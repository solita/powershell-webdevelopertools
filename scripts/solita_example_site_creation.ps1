$ErrorActionPreference = "Stop"
import-module .\..\solita-webdevelopertools.psm1

#################
# SANITY CHECKS #
#################
Test-IsElevated
Test-EverythingIsInstalled

$siteName = "ExampleSite"
$pool = "TheTestPool"
$path = "C:\Temp\TestWebSite"
$bindSiteName = $false
$Bindings = "test1.solita.fi","test2.solita.fi","test3.solita.fi" 

Set-WebDevWebSite -SiteName $siteName -PhysicalPath $path -AppPoolName $pool -BindAlsoSiteName $bindSiteName -Bindings $Bindings -RemoveApplicationPool $true