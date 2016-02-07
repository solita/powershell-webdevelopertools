$ErrorActionPreference = "Stop"

$webPiPath = (Join-Path "$env:programfiles" "microsoft\Web Platform Installer\webpicmd.exe")
$webDeployPath = (Join-Path "$env:programfiles" "IIS\Microsoft Web Deploy V3")
$appPoolDotNetVersion = "v4.0"

function Initialize-IISToolsModule {
	<#
    .SYNOPSIS 
    Checks that W3SVC is running and loads webadministration and serveradministration modules

    .DESCRIPTION
    Checks that W3SVC is running and loads webadministration and serveradministration modules

    .EXAMPLE
    Initialize-IISToolsModule
    #>
    [CmdletBinding()]
	Param()
    Import-Module ServerManager

    # check if there is no iis 
    $IIS = Get-service | Where-Object {$_.name -eq "W3SVC"}
    if (!$IIS)
    {   
        write-error "IIS was not found. Please install it first"
    }
	
	Import-Module WebAdministration
}

function Remove-DefaultSiteAndGivenSite {
	<#
    .SYNOPSIS 
    Checks that W3SVC is running and loads webadministration and serveradministration modules

    .DESCRIPTION
    Checks that W3SVC is running and loads webadministration and serveradministration modules

    .EXAMPLE
    Initialize-IISToolsModule
    #>
    [CmdletBinding()]
	Param(
		[string]$siteName)
	Get-Website | ? {$_.Name -eq "Default Web Site" } | Remove-WebSite -ErrorAction SilentlyContinue
	Get-Website | ? {$_.Name -eq $siteName } | Remove-WebSite -ErrorAction SilentlyContinue
}

function Set-ApplicationPoolWithDefaults {
	<#
    .SYNOPSIS 
    Checks that W3SVC is running and loads webadministration and serveradministration modules

    .DESCRIPTION
    Checks that W3SVC is running and loads webadministration and serveradministration modules

    .EXAMPLE
    Initialize-IISToolsModule
    #>
    [CmdletBinding()]
	Param(
		[string]$appPoolName,
		[string]$appPoolRestartTime)
	# Create application pool
	if($appPoolName -ne $null -and (-not (Test-Path IIS:\AppPools\$appPoolName)))
	{
		Write-Verbose "Creating application pool"
		$poolCreationInfo = New-WebAppPool -Name $appPoolName
	}
	### tune application pool settings ###
	# .NET runtime 
	Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name "managedRuntimeVersion" -Value $appPoolDotNetVersion
	# recycling
	Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name Recycling.periodicRestart.time -value ([TimeSpan]::FromMinutes(1440)) # 1 day (default: 1740)
	Clear-ItemProperty "IIS:\AppPools\$appPoolName" -Name Recycling.periodicRestart.schedule # Clear existing values if any
	Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name Recycling.periodicRestart.schedule -Value @{value="$appPoolRestartTime"}
	Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name processModel.idleTimeout -value ([TimeSpan]::FromMinutes(0)) # Disabled (default: 20)
	# logs from recycling to event log
	$recycleLogEvents = "Time,Requests,Schedule,Memory,IsapiUnhealthy,OnDemand,ConfigChange,PrivateMemory"
	Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name Recycling.logEventOnRecycle -Value $recycleLogEvents
}

function Initialize-WebDeployWithConfiguration {
	<#
    .SYNOPSIS 
    Create websites and configure application pools

    .DESCRIPTION
    Create websites and configure application pools

    .EXAMPLE
    Set-WebSiteWithDefault $config.root.IIS.WebSite
    #>
    [CmdletBinding()]
	Param(
		$siteName,
		$appPoolName,
		$wdeployUser,
		$wdeployUserPw)
	### Configure WDeploy ###
	& (Join-Path "$webDeployPath" "scripts\SetupSiteForPublish.ps1") -siteName $siteName -siteAppPoolName $appPoolName -deploymentUserName $wdeployUser -deploymentUserPassword $wdeployUserPw -managedRuntimeVersion $appPoolDotNetVersion
}

function Set-WebSiteWithDefaults {
	<#
    .SYNOPSIS 
    Create website and configure application pool 

    .DESCRIPTION
    Create website and configure application pool 

    .EXAMPLE
    Set-WebSiteWithDefault $config.root.IIS.WebSite
    #>
    [CmdletBinding()]
	Param(
		$siteName,
		$appPoolName,
		$appPoolRestartTime,
		$physicalPath,
		[array]$bindings)
	Set-ApplicationPoolWithDefaults $appPoolName $appPoolRestartTime
		
	# Create website (force id because crashes without it if there is no new sites in older versions)
	Write-Verbose "Creating website"
	$siteCreationInfo = New-WebSite -Name $siteName  -Port 80 -HostHeader $siteName -PhysicalPath $physicalPath  
	Set-ItemProperty IIS:\Sites\$siteName -name applicationPool -value $appPoolName
	# set bindings (go through all the bindings and create new webbinding for each)
	foreach($binding in $bindings)
	{
		Write-Verbose "Adding binding $binding"
		$bindingProtocol = "http"
		$bindingIP = "*"
		$bindingPort = "80"
		$bindingHostHeader = $binding.Hostname
		$bindingCreationInfo = New-WebBinding -Protocol $binding.protocol -Name $siteName -IPAddress $bindingIP -Port $bindingPort -HostHeader $bindingHostHeader
	}
}

function Install-WebPIPluginsWithDefaultArguments {
	<#
    .SYNOPSIS 
    Checks that W3SVC is running and loads webadministration and serveradministration modules

    .DESCRIPTION
    Checks that W3SVC is running and loads webadministration and serveradministration modules

    .EXAMPLE
    Initialize-IISToolsModule
    #>
    [CmdletBinding()]
	Param(
		$webPiPlugin)
	### Install stuff with WebPI ###
	Write-Verbose "Installing WebPI plugin: $webPiPlugin"
	# All enables parent features
	& $webPiPath /Install /Products:"$webPiPlugin" /AcceptEula
}