#approved powershell nouns https://technet.microsoft.com/en-us/library/ms714428%28v=vs.85%29.aspx

function Import-VisualStudioTools {
    <#
        .SYNOPSIS 
        Loads visual studio tools for specific visual studio version
        .DESCRIPTION
        Loads by default vs 12.0 tools to the powershell session
        .PARAMETER version
        Version number of the visual studio e.g. "12.0"
        .EXAMPLE
        Solita-LoadVisualStudioTools
        .EXAMPLE
        Solita-LoadVisualStudioTools "12.0"
    #>
    [CmdletBinding()]
    param([string]$version = "12.0")
	VsVars32 $version
}

function Install-ChocoAndUpgradePowershell
{
<#
	.SYNOPSIS 
	Install chocolatey and upgrades powershell
	.EXAMPLE
	Solita-InstallChocoAndUpgradePowershell
#>
    [CmdletBinding()]
    param()
	# https://github.com/chocolatey/chocolatey/wiki/Installation
	(iex ((new-object net.webclient).DownloadString(`
		'https://chocolatey.org/install.ps1')))>$null 2>&1
	choco install powershell
}

function script:VsVars32($version)
{
    $VsToolsDir = "C:\Program Files (x86)\Microsoft Visual Studio "+$version+"\Common7\Tools"
    $BatchFile = [System.IO.Path]::Combine($VsToolsDir, "vsvars32.bat")
    Get-Batchfile $BatchFile
    [System.Console]::Title = "Visual Studio " + $version + " Windows Powershell"
}

function script:Get-Batchfile ($file) {
    $cmd = "`"$file`" & set"
    cmd /c $cmd | Foreach-Object {
        $p, $v = $_.split('=')
        Set-Item -path env:$p -value $v
    }
}

function Get-PSVersion {
     <#
        .SYNOPSIS 
        Gets PowerShell version
        .DESCRIPTION
        Gets PowerShell version, if it is unable to find it out it default to 1.0
        .EXAMPLE
        Get-PSVersion
    #>
    [CmdletBinding()]
    param()
    if (test-path variable:psversiontable) {$psversiontable.psversion} else {[version]"1.0.0.0"}
}