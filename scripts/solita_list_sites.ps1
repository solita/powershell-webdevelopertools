[CmdletBinding(SupportsShouldProcess=$True)]
param (
    [Parameter(Mandatory=$false)]
    [string]$BindingRegExp
)

# Import iis modules
Import-Module Webadministration
# define regexp for iis looping
$protocolRegExp = 'http|https'
$destinationFile = "$PSScriptRoot\sites.html"

# get the sites that match our regexps
$sitesCollection = Get-ChildItem -Path IIS:\Sites | 
	Select -ExpandProperty Bindings | 
	Select -ExpandProperty Collection | 
	Where protocol -match $protocolRegExp | 
	Where bindingInformation -match $BindingRegExp | 
	Select protocol, bindingInformation
	
[System.Collections.ArrayList]$urlCollection = @()	
# loop the sites
foreach ($site in $sitesCollection) {
	$url = $site.Protocol + "://"+ $site.bindingInformation.split(':')[-1]
	# output collection add output to null (otherwise echos to cmd)
	$null = $urlCollection.add($url)
	Write-Host $url
}


# create html table 
$urlTbl = $urlCollection |
	
	Select @{n='Url';e={"<a href='$($_)'>$($_)</a><br/>"}} |
	ConvertTo-Html

# add reference to system.web
Add-Type -AssemblyName System.Web
# use system web to decode the html table to real html
[System.Web.HttpUtility]::HtmlDecode($urlTbl) | Out-File $destinationFile

# open output in browser
Invoke-Item $destinationFile


