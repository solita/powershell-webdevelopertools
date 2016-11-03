[CmdletBinding()]
param()
### This script uses modules from powershell-webdevelopertools repository ###

# On default errors wont stop execution, we want to break execution on error
$ErrorActionPreference = "Stop"

### Load tools and config ###
Import-Module ..\solita-servertools.psm1
$configPath = gci *install-conf*.xml | Select-Object -first 1
Write-Verbose "Using config $configPath"
[xml]$config = Get-InstallationConfigurationFile $configPath
$tempdir = $config.Root.InstallationTempFolder
# Create temporaryfolder for installation
Set-FolderIfNeeded $config.Root.InstallationTempFolder

### Install OS features and msi installers ###
Install-WindowsFeaturesWithDefaultArguments $config.Root.WindowsFeatures.Feature.Name 
$config.Root.Installers.Installer | % { Install-InstallerFromUrlWithDefaultArguments $_.GetAttribute("Url") (Join-Path $tempdir $_.GetAttribute("File")) }

### Initialize iis tools ### 
Import-Module ..\solita-iistools.psm1
Initialize-IISToolsModule

# Install WebPI stuff 
$config.Root.WebPiFeatures.Feature.Name | % { Install-WebPIPluginsWithDefaultArguments $_ }

# Configure websites, application pools and web deploy
$wdeployUser = $config.Root.IIS.WebDeploy.GetAttribute("Name")
$wdeployPw = $config.Root.IIS.WebDeploy.GetAttribute("Password")
foreach($webSite in $config.Root.IIS.Website )
{
	# Clean old shit
	Remove-DefaultSiteAndGivenSite $webSite.GetAttribute("SiteName")
	# Construct binding array
	[array]$siteBindings = @()
	$webSite.Binding | % { $siteBindings += $_.GetAttribute("Hostname")	}
	# Create phsyical so
	Set-FolderIfNeeded $webSite.GetAttribute("PhysicalPath")
	Set-WebSiteWithDefaults $webSite.GetAttribute("SiteName") $webSite.GetAttribute("AppPoolName") $webSite.GetAttribute("AppPoolRestartTime") $webSite.GetAttribute("PhysicalPath") $siteBindings
	Initialize-WebDeployWithConfiguration $webSite.GetAttribute("SiteName") $webSite.GetAttribute("AppPoolName") $wdeployUser $wdeployPw 
}

### Install Executables ###
# (for example .NET needs reboot, so this is last)
$config.Root.Executables.Executable | % { Install-ExecutableFromUrlWithDefaultArguments $_.GetAttribute("Url") (Join-Path $tempdir $_.GetAttribute("File")) }

### REBOOT (for .NET installation) ###
shutdown -r 