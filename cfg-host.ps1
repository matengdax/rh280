<#
.SYNOPSIS
    脚本 1/3: 仅用于配置本地 Windows 系统的设置。
.DESCRIPTION
    此脚本需要以管理员权限运行。
    它会执行一系列系统级设置，以达到一个干净、高性能的环境。
    所有操作均可在此脚本中找到，并有清晰的注释。
    
    版本: 1.1 (已修正)
#>

# =================================================================================
# --- 脚本主体 ---
# =================================================================================

#region 权限检查

if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "错误：此脚本需要管理员权限。请右键单击并选择 '以管理员身份运行'。"
    Read-Host "按任意键退出..."
    exit
}

#endregion

#region 核心执行逻辑
try {
    Write-Host "`n---------- [开始配置本地系统] ----------" -ForegroundColor Yellow

    Write-Host "`n1. 正在禁用账户锁定策略..." -ForegroundColor Cyan
    net accounts /lockoutthreshold:0
    
    Write-Host "`n2. 正在创建 '卓越性能' 电源计划..." -ForegroundColor Cyan
    # 此 GUID 是卓越性能模式的固定标识符
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
    
    Write-Host "`n3. 正在禁用 Windows 防火墙 (警告: 极大降低安全性)..." -ForegroundColor Cyan
    Set-NetFirewallProfile -Profile Domain, Private, Public -Enabled False
    
    Write-Host "`n4. 正在彻底禁用 UAC (需要重启生效, 警告: 极大降低安全性)..." -ForegroundColor Cyan
    # 设置为“从不通知”，这是禁用 UAC 的核心设置
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0 -Force
    # 为确保彻底，同时修改以下键值
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 0 -Force
    
    Write-Host "`n5. 正在安装 OpenSSH 服务器..." -ForegroundColor Cyan
    try {
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction Stop
        Write-Host "  OpenSSH 服务器安装成功。" -ForegroundColor Green
    } catch {
        Write-Warning "  安装 OpenSSH 服务器失败或已安装: $($_.Exception.Message)"
    }
    
    Write-Host "`n6. 正在配置并启动 SSHD 服务 (设置为 PowerShell Shell)..." -ForegroundColor Cyan
    try {
        # 确保服务存在并设置为自动启动
        Set-Service -Name sshd -StartupType 'Automatic' -ErrorAction Stop
        
        # [已修正] 正确的配置方法是修改 sshd_config 文件，而不是注册表
        $sshConfigPath = "$env:ProgramData\ssh\sshd_config"
        if (Test-Path $sshConfigPath) {
            $powershellPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
            (Get-Content $sshConfigPath) | ForEach-Object {
                # 注释掉旧的 cmd.exe 默认 shell (如果存在)
                $_ -replace '(?m)^(#?Subsystem\s+powershell\s+c.*cmd.exe)', '#$1'
            } | Set-Content -Path $sshConfigPath -Force

            # 添加或更新 PowerShell 为默认 Shell 的配置
            $configContent = Get-Content $sshConfigPath
            if ($configContent -notmatch "powershell.exe") {
                Add-Content -Path $sshConfigPath -Value "`n# Set PowerShell as default remote shell`nDefaultShell $powershellPath"
            }
            
            Restart-Service sshd
            Write-Host "  SSHD 服务已配置并启动，默认 Shell 已设置为 PowerShell。" -ForegroundColor Green
        } else {
            Write-Warning "  未找到 SSHD 配置文件: $sshConfigPath"
        }
    } catch {
        Write-Warning "  配置或启动 SSHD 服务时出错: $($_.Exception.Message)"
    }

    Write-Host "`n7. 正在通过注册表彻底禁用 Windows Defender (需要重启生效)..." -ForegroundColor Cyan
    try {
        # [已修正] 创建完整的注册表路径，确保设置不会因为路径不存在而失败
        $defenderPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
        $realTimePath = "$defenderPath\Real-Time Protection"
        
        New-Item -Path $defenderPath -Force -ErrorAction Stop | Out-Null
        New-Item -Path $realTimePath -Force -ErrorAction Stop | Out-Null

        # 禁用 Defender
        Set-ItemProperty -Path $defenderPath -Name "DisableAntiSpyware" -Value 1 -Force
        # 禁用实时保护
        Set-ItemProperty -Path $realTimePath -Name "DisableRealtimeMonitoring" -Value 1 -Force
        Write-Host "  Windows Defender 禁用策略已应用。" -ForegroundColor Green
    } catch {
        Write-Warning "  禁用 Defender 时出错: $($_.Exception.Message)"
    }

    Write-Host "`n8. 正在配置 Windows Update 为手动更新模式 (需要重启生效)..." -ForegroundColor Cyan
    $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    New-Item -Path $auPath -Force | Out-Null
    # 2 = 通知下载并通知安装，这是最接近“手动”的策略选项
    Set-ItemProperty -Path $auPath -Name "AUOptions" -Value 2 -Force
    Set-ItemProperty -Path $auPath -Name "NoAutoUpdate" -Value 1 -Force

    Write-Host "`n9. 正在彻底禁用 Windows 交换文件(Swap) (需要重启生效)..." -ForegroundColor Cyan
    Write-Warning "  警告: 禁用交换文件可能会在物理内存耗尽时导致系统不稳定或崩溃。"
    try {
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        if ($computerSystem.AutomaticManagedPageFile) {
            $computerSystem.AutomaticManagedPageFile = $false
            Set-CimInstance -InputObject $computerSystem
        }
        Get-CimInstance -ClassName Win32_PageFileSetting | Remove-CimInstance -Confirm:$false
        Write-Host "  系统交换文件已禁用。" -ForegroundColor Green
    } catch {
        Write-Warning "  禁用交换文件时出错: $($_.Exception.Message)"
    }
    
    Write-Host "`n10. 正在清理任务栏 (隐藏搜索和任务视图)..." -ForegroundColor Cyan
    # [注意] 以下设置为 HKCU，仅对当前运行脚本的管理员账户生效
    # 隐藏搜索框 (0 = 隐藏, 1 = 显示图标, 2 = 显示搜索框)
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Force
    # 隐藏任务视图按钮 (0 = 隐藏, 1 = 显示)
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Force

    Write-Host "`n11. 正在从任务栏取消固定 Microsoft Edge..." -ForegroundColor Cyan
    # [严重警告] 此方法严重依赖操作系统语言，仅在简体中文版 Windows 上有效！
    # 在其他语言系统上，此段代码会静默失败。
    try {
        $shell = New-Object -ComObject "Shell.Application"
        $taskbarPath = "shell:::{ED228FDF-9EA8-4870-834E-662DC4C9D562}"
        $taskbar = $shell.Namespace($taskbarPath)
        $edge = $taskbar.Items() | Where-Object { $_.Name -eq "Microsoft Edge" }
        
        if ($edge) {
            $unpinVerb = $edge.Verbs() | Where-Object { $_.Name.Contains("从任务栏取消固定") }
            if ($unpinVerb) {
                $unpinVerb.DoIt()
                Write-Host "  Microsoft Edge 已成功取消固定。" -ForegroundColor Green
            } else {
                Write-Warning "  未找到 '取消固定' 操作 (可能是系统语言不匹配)。"
            }
        } else {
            Write-Host "  任务栏上未找到 Microsoft Edge。"
        }
    } catch {
        Write-Warning "  取消固定 Edge 时出错: $($_.Exception.Message)"
    }

    Write-Host "`n12. 正在重命名计算机为 'ex280' (需要重启生效)..." -ForegroundColor Cyan
    try {
        Rename-Computer -NewName "ex280" -Force -ErrorAction Stop
        Write-Host "  计算机重命名请求已提交。" -ForegroundColor Green
    } catch {
        # 捕获可能因为名称已相同等原因导致的错误
        Write-Warning "  重命名计算机失败: $($_.Exception.Message)"
    }
    
    Write-Host "`n---------- [本地系统配置完成] ----------" -ForegroundColor Yellow
    Write-Host "`n重要提示: 大部分设置需要您手动重启计算机后才能完全生效！" -ForegroundColor Red

} catch {
    Write-Error "脚本执行过程中发生严重错误: $($_.Exception.Message)"
} finally {
    Write-Host "`n本地系统配置脚本执行完毕。"
    Read-Host "按任意键退出..."
}
#endregion
