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
Rename-Computer -NewName "ex280"
