<#
.SYNOPSIS
    脚本 2/3: 仅用于配置指定的虚拟机，并进行性能最大化调优。
.DESCRIPTION
    此脚本需要以管理员权限运行。
    它会自动关闭 VMware 主程序，然后对列表中的每台虚拟机执行以下操作：
    1. 确保虚拟机已强制关机。
    2. 恢复到指定的快照，以获得一个干净的基线。
    3. 修改 .vmx 文件以应用最终的性能配置 (CPU, 内存, 硬件虚拟化等)。
    脚本结束后会自动重新打开 VMware 主程序。
    
    版本: 1.3 (修正逻辑顺序，增加程序启停控制)
#>

# =================================================================================
# --- 用户配置区域 ---
# =================================================================================

# 1. 虚拟机配置列表:
$vmConfigurations = @(
    @{
        Path              = "C:\Users\admin\Desktop\DO280 v4.0\workstation\workstation.vmx"
        MemoryMB          = 24576 # 24 GB
        NumCPUs           = 1     # 虚拟 CPU 插槽数 (通常为 1)
        NumCoresPerSocket = 12    # 每个插槽的核心数
        VncEnabled        = $true
        VncPort           = 5901
        LockMemory        = $true # 强烈推荐：立即为虚拟机锁定全部内存
    },
    @{
        Path              = "C:\Users\admin\Desktop\DO280 v4.0\master01\master01.vmx"
        MemoryMB          = 32768 # 32 GB
        NumCPUs           = 1
        NumCoresPerSocket = 12
        VncEnabled        = $true
        VncPort           = 5902
        LockMemory        = $true # 强烈推荐：立即为虚拟机锁定全部内存
    }
)

# 2. 快照名称:
$snapshotNameToRevert = "v4.12"

# =================================================================================
# --- 脚本主体 ---
# =================================================================================

#region 权限和环境检查

# ... (此区域代码与之前版本相同，保持不变) ...
if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "错误：此脚本需要管理员权限。请右键单击并选择 '以管理员身份运行'。"
    Read-Host "按任意键退出..."
    exit
}
Write-Host "正在查找 VMware Workstation 安装路径..." -ForegroundColor Cyan
$vmwarePath = $null
try { $vmwarePath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\VMware, Inc.\VMware Workstation").InstallPath } catch { $vmwarePath = "C:\Program Files (x86)\VMware\VMware Workstation" }
if (-Not (Test-Path -Path $vmwarePath)) { Write-Error "错误：在 '$vmwarePath' 未找到 VMware Workstation。"; Read-Host "按任意键退出..."; exit }
$vmrunPath = Join-Path -Path $vmwarePath -ChildPath "vmrun.exe"
$vmwareExePath = Join-Path -Path $vmwarePath -ChildPath "vmware.exe"
if (-Not (Test-Path -Path $vmrunPath -PathType Leaf)) { Write-Error "错误：在 VMware 安装目录中未找到 vmrun.exe。"; Read-Host "按任意键退出..."; exit }
Write-Host "成功找到 VMware 工具路径: $vmwarePath" -ForegroundColor Green

#endregion

#region 辅助函数

# ... (此区域代码与之前版本相同，保持不变) ...
function Invoke-Vmrun {
    param([string]$Arguments)
    Write-Host "  [VMRUN] 正在执行: $Arguments" -ForegroundColor DarkGray
    $process = Start-Process -FilePath $vmrunPath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -ne 0) {
        throw "vmrun.exe 命令执行失败，退出代码: $($process.ExitCode)。"
    }
    return $process
}
function Set-VmxKeyValue {
    param([string[]]$Content, [string]$Key, [string]$Value)
    $fullSetting = "$Key = `"$Value`""
    $keyPattern = "^$([regex]::Escape($Key))\s*="
    $foundLine = $Content | Select-String -Pattern $keyPattern -Quiet
    if ($foundLine) {
        $Content = $Content | ForEach-Object { if ($_ -match $keyPattern) { return $fullSetting } else { return $_ } }
        Write-Host "    已更新: $fullSetting" -ForegroundColor DarkGray
    } else {
        $Content += $fullSetting
        Write-Host "    已添加: $fullSetting" -ForegroundColor DarkGray
    }
    return $Content
}
function Update-VmxConfiguration {
    param([hashtable]$vmConfig)
    $vmxPath = $vmConfig.Path
    Write-Host "  [VMX] 正在为 '$vmxPath' 应用性能最大化配置..."
    if (-Not (Test-Path $vmxPath)) { Write-Warning "    .vmx 文件不存在: $vmxPath"; return }
    $vmxContent = Get-Content -Path $vmxPath -Encoding UTF8
    $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'memsize' -Value $vmConfig.MemoryMB
    if ($vmConfig.LockMemory) { $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'mainMem.backing' -Value "locked" } else { $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'mainMem.backing' -Value "swap" }
    $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'MemTrimRate' -Value "0"
    $totalCores = $vmConfig.NumCPUs * $vmConfig.NumCoresPerSocket
    $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'numvcpus' -Value $totalCores
    $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'cpuid.coresPerSocket' -Value $vmConfig.NumCoresPerSocket
    $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'vhv.enable' -Value "TRUE"
    $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'monitor.virtual.exec' -Value "hardware"
    $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'RemoteDisplay.vnc.enabled' -Value ($vmConfig.VncEnabled.ToString().ToUpper())
    if ($vmConfig.VncEnabled) { $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'RemoteDisplay.vnc.port' -Value $vmConfig.VncPort }
    $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'priority.grabbed' -Value "high"
    $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'logging' -Value "FALSE"
    $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'mks.enable3d' -Value "FALSE"
    $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'isolation.tools.unity.disable' -Value "TRUE"
    $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'sound.present' -Value "FALSE"
    $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'gui.fitGuestUsingNativeDisplayResolution' -Value "FALSE"
    $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'gui.stretchGuest' -Value "TRUE"
    $vmxContent = Set-VmxKeyValue -Content $vmxContent -Key 'gui.keepAspectRatio' -Value "TRUE"
    Set-Content -Path $vmxPath -Value $vmxContent -Encoding UTF8
    Write-Host "    .vmx 性能配置已应用并保存。" -ForegroundColor Green
}

#endregion

#region 核心执行逻辑
try {
    # [已增加] 步骤 0: 检查并关闭 VMware 主程序，防止文件占用或配置覆盖
    Write-Host "`n---------- [准备环境] ----------" -ForegroundColor Yellow
    $vmwareProcess = Get-Process -Name "vmware" -ErrorAction SilentlyContinue
    if ($vmwareProcess) {
        Write-Host "  检测到 VMware Workstation 正在运行，正在关闭..." -ForegroundColor Cyan
        Stop-Process -InputObject $vmwareProcess -Force
        Start-Sleep -Seconds 2
        Write-Host "  VMware Workstation 已关闭。" -ForegroundColor Green
    }

    Write-Host "`n---------- [开始管理虚拟机] ----------" -ForegroundColor Yellow
    foreach ($vmConfig in $vmConfigurations) {
        $vmPath = $vmConfig.Path
        $vmName = [System.IO.Path]::GetFileNameWithoutExtension($vmPath)
        Write-Host "`n正在处理虚拟机: $vmName" -ForegroundColor Cyan
        if (-Not (Test-Path -Path $vmPath)) {
            Write-Warning "  路径无效，跳过此虚拟机: $vmPath"
            continue
        }

        # 步骤 1: 确保虚拟机已强制关机
        Write-Host "1. 正在确保虚拟机已强制关机..."
        try {
            Invoke-Vmrun -Arguments "-T ws stop `"$vmPath`" hard"
        } catch {
            if ($_.Exception.Message -like "*The virtual machine is not powered on*") {
                Write-Host "  虚拟机已经是关机状态，无需操作。" -ForegroundColor DarkGray
            } else {
                throw $_.Exception
            }
        }
        
        # [逻辑修正] 步骤 2: 先恢复快照，建立配置基线
        Write-Host "2. 正在检查并恢复到快照 '$snapshotNameToRevert'..."
        try {
            $snapshotList = & $vmrunPath -T ws listSnapshots "$vmPath"
            if ($snapshotList -contains $snapshotNameToRevert) {
                Invoke-Vmrun -Arguments "-T ws revertToSnapshot `"$vmPath`" `"$snapshotNameToRevert`""
                Write-Host "  已成功恢复到快照 '$snapshotNameToRevert'。" -ForegroundColor Green
            } else {
                Write-Warning "  虚拟机 '$vmName' 没有找到名为 '$snapshotNameToRevert' 的快照，已跳过恢复操作。"
            }
        } catch {
            Write-Warning "  检查或恢复快照时出错: $($_.Exception.Message)"
        }
        
        # [逻辑修正] 步骤 3: 在快照恢复后，应用最终的自定义配置
        Write-Host "3. 正在应用详细的虚拟机配置..."
        Update-VmxConfiguration -vmConfig $vmConfig
        
        Write-Host "虚拟机 '$vmName' 处理完成。" -ForegroundColor Green
    }
    Write-Host "`n---------- [虚拟机管理完成] ----------" -ForegroundColor Yellow
} catch {
    Write-Error "脚本执行过程中发生严重错误: $($_.Exception.Message)"
} finally {
    # [已增加] 最终操作: 重新启动 VMware 主程序
    if (Test-Path -Path $vmwareExePath -PathType Leaf) {
        Write-Host "`n正在启动 VMware Workstation 主程序..." -ForegroundColor Cyan
        Start-Process -FilePath $vmwareExePath
    }
    Write-Host "`n虚拟机配置脚本执行完毕。"
    Read-Host "按任意键退出..."
}
#endregion
