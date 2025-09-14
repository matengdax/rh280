<#
.SYNOPSIS
    配置 VMware Workstation 的 VMnet1 和 VMnet8 虚拟网络。

.DESCRIPTION
    此脚本需要以管理员权限运行。
    它会修改 VMnet1 (仅主机模式) 和 VMnet8 (NAT 模式) 的网络设置，包括子网地址和 DHCP 服务状态。
    - VMnet8 将被设置为 192.168.8.0/24 网段，并开启 DHCP。
    - VMnet1 将被设置为 172.25.250.0/24 网段，并关闭 DHCP。

.NOTES
    作者: Gemini
    版本: 1.0
    要求: Windows PowerShell 5.1 或更高版本，已安装 VMware Workstation。
#>

#region 权限和环境检查

# 1. 检查是否以管理员身份运行
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-Not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "错误：此脚本需要管理员权限才能修改网络配置。请右键单击脚本并选择 '以管理员身份运行'。"
    # 等待用户按键后退出
    Read-Host "按任意键退出..."
    exit
}

# 2. 查找 VMware Workstation 安装路径
Write-Host "正在查找 VMware Workstation 安装路径..."
$vmwarePath = $null
# 优先从注册表查找 (更可靠)
try {
    $vmwarePath = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\VMware, Inc.\VMware Workstation").InstallPath
}
catch {
    # 注册表找不到时，使用默认路径
    $vmwarePath = "C:\Program Files (x86)\VMware\VMware Workstation"
}

if (-Not (Test-Path -Path $vmwarePath)) {
    Write-Error "错误：在 '$vmwarePath' 未找到 VMware Workstation。请确认您的安装路径。"
    Read-Host "按任意键退出..."
    exit
}

$vnetlibPath = Join-Path -Path $vmwarePath -ChildPath "vnetlib64.exe"

if (-Not (Test-Path -Path $vnetlibPath)) {
    Write-Error "错误：在 '$($vnetlibPath)' 未找到核心网络配置工具 vnetlib64.exe。"
    Read-Host "按任意键退出..."
    exit
}

Write-Host "成功找到 VMware Workstation: $vmwarePath" -ForegroundColor Green

#endregion

#region 核心执行逻辑

# 定义一个辅助函数来调用 vnetlib64.exe 并检查结果
function Invoke-Vnetlib {
    param(
        [string]$Arguments
    )
    
    Write-Host "正在执行: vnetlib64.exe $Arguments"
    $process = Start-Process -FilePath $vnetlibPath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -ne 0) {
        # 如果命令执行失败，则抛出异常
        throw "命令执行失败，退出代码: $($process.ExitCode)。请检查 VMware 服务状态或日志。"
    }
    else {
        Write-Host "命令成功执行。" -ForegroundColor Green
    }
}

# 使用 try/catch/finally 结构确保无论成功与否，最后都会尝试重启服务
try {
    # 停止服务
    Invoke-Vnetlib -Arguments "-- stop-services"
    
    # --- 配置 VMnet8 (NAT) ---
    Write-Host "`n--- 正在配置 VMnet8 (NAT) ---" -ForegroundColor Cyan
    # 设置子网和掩码
    Invoke-Vnetlib -Arguments "-- set vnet VMnet8 addr 192.168.8.0 255.255.255.0"
    # 开启 DHCP
    Invoke-Vnetlib -Arguments "-- set vnet VMnet8 prop dhcp on"
    Write-Host "VMnet8 配置完成。" -ForegroundColor Cyan

    # --- 配置 VMnet1 (仅主机) ---
    Write-Host "`n--- 正在配置 VMnet1 (仅主机) ---" -ForegroundColor Cyan
    # 设置子网和掩码
    Invoke-Vnetlib -Arguments "-- set vnet VMnet1 addr 172.25.250.0 255.255.255.0"
    # 关闭 DHCP
    Invoke-Vnetlib -Arguments "-- set vnet VMnet1 prop dhcp off"
    Write-Host "VMnet1 配置完成。" -ForegroundColor Cyan
}
catch {
    # 如果在 try 块中发生任何错误，则会执行此处的代码
    Write-Error "在配置过程中发生严重错误: $($_.Exception.Message)"
}
finally {
    # 无论 try 块是否成功，finally 块中的代码总会执行
    Write-Host "`n--- 正在启动 VMware 服务 ---" -ForegroundColor Yellow
    # 启动服务
    Invoke-Vnetlib -Arguments "-- start-services"
    Write-Host "`n脚本执行完毕。请在 '虚拟网络编辑器' 中检查配置是否生效。" -ForegroundColor Yellow
}

#endregion
```eof

### 如何使用此脚本

1.  **保存脚本**：将上面的代码复制并粘贴到一个文本文件中，然后将其另存为 `Configure-VMware-Networks.ps1`。
2.  **以管理员身份运行**：
    * 右键单击您保存的 `.ps1` 文件。
    * 在弹出的菜单中选择 “**使用 PowerShell 运行**” 或 “**以管理员身份运行**” (Run with PowerShell / Run as administrator)。
3.  **执行策略问题**：如果您是第一次在系统上运行 PowerShell 脚本，可能会遇到执行策略的限制。如果出现错误，请先以**管理员身份**打开一个 PowerShell 窗口，然后执行以下命令来允许运行本地脚本：
    ```powershell
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
    ```
    然后在此窗口中，通过 `cd` 命令导航到脚本所在的目录，并运行它：
    ```powershell
    .\Configure-VMware-Networks.ps1
    ```
4.  **观察输出**：脚本会显示其执行的每一步。完成后，您可以打开 VMware Workstation 的 "编辑" -> "虚拟网络编辑器" 来验证更改是否已成功应用。
