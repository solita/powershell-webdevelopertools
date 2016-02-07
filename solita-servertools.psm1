$ErrorActionPreference = "Stop"


function Invoke-ProcessAsElevated  {
	<#
    .SYNOPSIS 
    Sudo for windows

    .DESCRIPTION
    Calls executable as elevated and returns status

    .EXAMPLE
    Invoke-ProcessAsElevated msiexec.exe $arguments
    #>
    [CmdletBinding()]
	param (
		[string]$exe = $(Throw “Pleave provide the name and path of an executable”),
		$arguments)
	# wait for process to execute
	# PassThru gives processhandle
	# Verb runAs makes elevated process
	Start-Process $exe  -Wait -PassThru -Verb runAs -ArgumentList $arguments
}

function Install-InstallerFileWithDefaultArguments {
	<#
    .SYNOPSIS 
    Installs msi packet silently

    .DESCRIPTION
    Installs msi packet silently

    .EXAMPLE
    Install-InstallerFileWithDefaultArguments $msiFile
    #>
    [CmdletBinding()]
    Param(
        [string]$File)
    $arguments = @(
        "/i" #install product
        "`"$File`""
        "/qn" # display no interface 
        "/norestart"
        "/passive")
    Write-Verbose "Installing $File....."
	# Let's do elevation to get rid of UAC warnings!
    $process = Invoke-ProcessAsElevated msiexec.exe $arguments
    if ($process.ExitCode -eq 0){
        Write-Verbose "$File has been successfully installed"
    }
    else {
        Write-Verbose "installer exit code  $($process.ExitCode) for file  $($File)"
    }
}

function Install-InstallerFromUrlWithDefaultArguments {
	<#
    .SYNOPSIS 
    Downloads and installs msi packet silently

    .DESCRIPTION
    Downloads and installs msi packet silently

    .EXAMPLE
    Install-InstallerFromUrlWithDefaultArguments $msiUrl $msiFile
    #>
    [CmdletBinding()]
	Param(
		[string]$Url,
        [string]$File)
	Invoke-WebRequest -Uri $Url -OutFile $File
	Install-InstallerFileWithDefaultArguments $File
}

function Install-ExecutableFileWithDefaultArguments {
	<#
    .SYNOPSIS 
    Installs exe silently

    .DESCRIPTION
    Installs exe silently

    .EXAMPLE
    Install-ExecutableFileWithDefaultArguments $exeFile
    #>
    [CmdletBinding()]
    Param(
        [string]$File)
    $arguments = @(
        "/qn" # display no interface 
        "/norestart"
        "/passive"
		"/S")
    Write-Verbose "Installing $File....."
	# Let's do elevation to get rid of UAC warnings!
    $process = Invoke-ProcessAsElevated $File $arguments
    if ($process.ExitCode -eq 0){
        Write-Verbose "$File has been successfully installed"
    }
    else {
        Write-Verbose "installer exit code  $($process.ExitCode) for file  $($File)"
    }
}

function Install-ExecutableFromUrlWithDefaultArguments {
	<#
    .SYNOPSIS 
    Downloads and installs exe silently

    .DESCRIPTION
    Downloads and installs exe silently

    .EXAMPLE
    Install-ExecutableFileWithDefaultArguments $exeUrl $exeFile
    #>
    [CmdletBinding()]
	Param(
		[string]$Url,
        [string]$File)
	Invoke-WebRequest -Uri $Url -OutFile $File
	Install-ExecutableFileWithDefaultArguments $File
}

function Install-WindowsFeaturesWithDefaultArguments {
	<#
    .SYNOPSIS 
    Enables windowsfeatures with default arguments 

    .DESCRIPTION
    Enables windowsfeatures with default arguments 

    .EXAMPLE
    Install-WindowsFeaturesWithDefaultArguments $windowsFeatures
    #>
    [CmdletBinding()]
	Param(
		[Array]$windowsFeatures)
	foreach ($task in $windowsFeatures) {
		Write-Verbose "Installing windows feature: $task"
		# All enables parent features
		# Online 
		$Null = Enable-WindowsOptionalFeature -Online -All -FeatureName $task
	}
}


function Set-FolderIfNeeded {
	<#
    .SYNOPSIS 
    Creates a folder if needed

    .DESCRIPTION
    Creates a folder if needed

    .EXAMPLE
    Set-FolderIfNeeded $folderPath
    #>
    [CmdletBinding()]
	Param(
		[string]$folderPath)
	# Create temp folder if it does not exists
	if(!(Test-Path -Path $folderPath )){
		Write-Verbose "Creating installation folder $folderPath"
		$Null = New-Item -ItemType directory -Path $folderPath
	}
}

function Get-InstallationConfigurationFile {
	<#
    .SYNOPSIS 
    Read given file and return its contents as xml 

    .DESCRIPTION
    Read given file and return it  contents as xml 

    .EXAMPLE
    Get-InstallationConfigurationFile $filePath
    #>
    [CmdletBinding()]
	Param(
		[string]$configFile)
	Test-IsRunElevated
	Test-IsRun64Bit
	
	Write-Verbose "Using configuration file: [$configFile]."
	try {
		[xml] (get-content $configFile -ErrorAction Stop)
	} catch {
		Write-Error ("Missing configuration file: " + $_.Exception.Message)
	}
}

function Test-IsRunElevated {
	<#
    .SYNOPSIS 
    Tests if process is run elevated

    .DESCRIPTION
    Tests if process is run elevated

    .EXAMPLE
    Test-IsRunElevated
    #>
    [CmdletBinding()]
	Param()
    & {
        $wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
        $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
        $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
        $IsAdmin=$prp.IsInRole($adm)
        if(!$IsAdmin)
        {
            Write-Error "You must run this with elevated mode (runas administrator)!"
        }
    }
}

function Test-IsRun64Bit {
	<#
    .SYNOPSIS 
    Tests if process is run 64bit 
	
    .DESCRIPTION
    Tests if process is run 64bit 

    .EXAMPLE
    Test-IsRun64Bit
    #>
    [CmdletBinding()]
	Param()
	if (-Not [Environment]::Is64BitProcess) {
		write-Error "This script needs to be run at 64 bit PowerShell version!"
	}
}