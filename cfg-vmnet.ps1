<#
.SYNOPSIS
    脚本 1/3: 自动配置 VMware Workstation 的虚拟网络。
.DESCRIPTION
    此脚本需要以管理员权限运行。
    - 如果 VMware Workstation 程序正在运行，会自动关闭它。
    - 使用 VMware 官方工具来重置网络服务。
    - 将 VMnet8 设置为 NAT 模式 (192.168.8.0/24, 开启 DHCP)。
    - 将 VMnet1 设置为仅主机模式 (172.25.250.0/24, 关闭 DHCP)。
    - 完成后，会自动重新启动 VMware Workstation 程序。
    
    版本: 1.2 (增加程序启停控制)
#>

# =================================================================================
# --- 脚本主体 ---
# =================================================================================

#region 权限和环境检查

if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "错误：此脚本需要管理员权限。请右键单击并选择 '以管理员身份运行'。"
    Read-Host "按任意键退出..."
    exit
}

Write-Host "正在查找 VMware Workstation 安装路径..." -ForegroundColor Cyan
$vmwarePath = $null
# 优先从注册表查找路径，更可靠
try { $vmwarePath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\VMware, Inc.\VMware Workstation").InstallPath } catch { $vmwarePath = "C:\Program Files (x86)\VMware\VMware Workstation" }

if (-Not (Test-Path -Path $vmwarePath)) { Write-Error "错误：在 '$vmwarePath' 未找到 VMware Workstation。"; Read-Host "按任意键退出..."; exit }

# 校验关键程序是否存在
$vnetlibPath = Join-Path -Path $vmwarePath -ChildPath "vnetlib64.exe"
$vmwareExePath = Join-Path -Path $vmwarePath -ChildPath "vmware.exe"
if (-Not (Test-Path -Path $vnetlibPath -PathType Leaf)) { Write-Error "错误：在 VMware 安装目录中未找到 vnetlib64.exe。"; Read-Host "按任意键退出..."; exit }
if (-Not (Test-Path -Path $vmwareExePath -PathType Leaf)) { Write-Warning "警告：在 VMware 安装目录中未找到 vmware.exe，脚本将无法在最后启动程序。" }

Write-Host "成功找到 VMware 工具路径: $vmwarePath" -ForegroundColor Green

#endregion

#region 辅助函数

# 封装 vnetlib 的调用，增加日志和错误检查
function Invoke-Vnetlib {
    param(
        [string]$Arguments
    )
    Write-Host "  [VNETLIB] 正在执行: $Arguments" -ForegroundColor DarkGray
    $process = Start-Process -FilePath $vnetlibPath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -ne 0) {
        # 抛出异常，会被主逻辑的 catch 块捕获
        throw "vnetlib64.exe 命令执行失败，退出代码: $($process.ExitCode)。"
    }
}

#endregion

#region 核心执行逻辑
try {
    # 阶段 0: 检查并关闭 VMware 主程序
    Write-Host "`n---------- [阶段 0: 准备环境] ----------" -ForegroundColor Yellow
    $vmwareProcess = Get-Process -Name "vmware" -ErrorAction SilentlyContinue
    if ($vmwareProcess) {
        Write-Host "  检测到 VMware Workstation 正在运行，正在关闭..." -ForegroundColor Cyan
        Stop-Process -InputObject $vmwareProcess -Force
        Start-Sleep -Seconds 2 # 等待进程完全退出
        Write-Host "  VMware Workstation 已关闭。" -ForegroundColor Green
    } else {
        Write-Host "  VMware Workstation 未在运行，无需关闭。"
    }

    # 阶段 1: 使用官方工具停止所有服务
    Write-Host "`n---------- [阶段 1: 停止 VMware 服务] ----------" -ForegroundColor Yellow
    Invoke-Vnetlib -Arguments "-- stop-services"
    
    # 阶段 2: 配置虚拟网络
    Write-Host "`n---------- [阶段 2: 配置虚拟网络] ----------" -ForegroundColor Yellow
    
    # --- 配置 VMnet8 (NAT) ---
    Write-Host "`n正在配置 VMnet8 (NAT)..." -ForegroundColor Cyan
    Invoke-Vnetlib -Arguments "-- set vnet vmnet8 opt nat on"
    Invoke-Vnetlib -Arguments "-- set vnet vmnet8 addr 192.168.8.0 255.255.255.0"
    Invoke-Vnetlib -Arguments "-- set vnet vmnet8 prop dhcp on"
    
    # --- 配置 VMnet1 (仅主机) ---
    Write-Host "`n正在配置 VMnet1 (仅主机)..." -ForegroundColor Cyan
    Invoke-Vnetlib -Arguments "-- set vnet vmnet1 opt hostonly on"
    Invoke-Vnetlib -Arguments "-- set vnet vmnet1 addr 172.25.250.0 255.255.255.0"
    Invoke-Vnetlib -Arguments "-- set vnet vmnet1 prop dhcp off"
    
    Write-Host "`n---------- [阶段 2: 完成] ----------" -ForegroundColor Yellow

} catch {
    Write-Error "脚本执行过程中发生严重错误: $($_.Exception.Message)"
} finally {
    # 最终操作: 无论成功或失败，都尝试重启服务并启动主程序
    Write-Host "`n---------- [最终操作: 启动服务与程序] ----------" -ForegroundColor Yellow
    
    Write-Host "正在启动 VMware 服务..." -ForegroundColor Cyan
    Invoke-Vnetlib -Arguments "-- start-services"
    
    if (Test-Path -Path $vmwareExePath -PathType Leaf) {
        Write-Host "正在启动 VMware Workstation 主程序..." -ForegroundColor Cyan
        Start-Process -FilePath $vmwareExePath
    }
    
    Write-Host "`n网络配置脚本执行完毕。"
    Read-Host "按任意键退出..."
}
#endregion
