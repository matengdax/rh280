<#
rds.easthome.com:25413
ruitong\brhce18
P@ssw0rd


10.30.13.73
admin
P@ssw0rd
#>

net accounts /lockoutthreshold:0
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
Set-NetFirewallProfile -Profile Domain, Private, Public -Enabled False
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Set-Service -Name sshd -StartupType 'Automatic'
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force -ErrorAction SilentlyContinue
Start-Service sshd
Set-MpPreference -DisableRealtimeMonitoring $true -DisableBehaviorMonitoring $true -DisableIOAVProtection $true -DisablePrivacyMode $true -MAPSReporting Disabled -SubmitSamplesConsent Never -Force
Rename-Computer -NewName "ex280"
