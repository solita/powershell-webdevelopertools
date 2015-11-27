# this is an example profile file that can be put into some of below

#Current User, Current Host - console
# $Home\[My ]Documents\WindowsPowerShell\Profile.ps1

#Current User, All Hosts 
# $Home\[My ]Documents\Profile.ps1

#All Users, Current Host - console   
# $PsHome\Microsoft.PowerShell_profile.ps1

#All Users, All Hosts      
# $PsHome\Profile.ps1

#Current user, Current Host - ISE
# $Home\[My ]Documents\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1

#All users, Current Host - ISE  
# $PsHome\Microsoft.PowerShellISE_profile.ps1

$psdir="C:\Solita\Powershell\Autoload"
gci "${psdir}\*.psm1" | %{ Import-Module $_.FullName }
Write-Host  "Custom modules loaded" -ForeGroundColor "Yellow"
gci "${psdir}\*.ps1" | %{.$_}
Write-Host "Environment settings loaded" -ForeGroundColor "Yellow"

