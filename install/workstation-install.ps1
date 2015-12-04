# powershell.exe -executionpolicy unrestricted -command .\workstation-install.ps1
# Set-ExecutionPolicy unrestricted -force
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

#windows features
# List all windowsfeatures with Get-WindowsOptionalFeature -Online
$features = @(
	"IIS-WebServerRole"
	"IIS-ISAPIFilter"
	"IIS-ISAPIExtensions" 
	"IIS-NetFxExtensibility" 
	"IIS-ASPNET"
)
foreach ($task in $features) {
	Enable-WindowsOptionalFeature -Online -FeatureName $task
}


# ### Install ### #
cinst putty -y
cinst 7zip -y
cinst spotify -y
cinst grepwin -y
cinst conemu -y
cinst fiddler4 -y

# Web
cinst firefox -y
cinst googlechrome -y

# Powershell modules
cinst powertab -y # you need to Import-Module PowerTab to configure this

# Version control and nuget packages
cinst SourceTree -y
cinst gitextensions -y
cinst kdiff3 -y
cinst poshgit -y
cinst Nuget.commandline

# Languages
cinst DotNet4.6 -y
cinst nodejs.install -y
cinst ruby -y
cinst npm -y

# IDE
cinst sublimetext3 -y
cinst notepadplusplus -y
# Mount visual studio image from share and run it with (for unmanned installation of vs2015)
# .\vs_professional.exe "PathToFile\AdminDeployment.xml" /quiet /norestart
# after visual studio installation install resharper 9.2
# cinst resharper -version 9.2.0.0 -y 

# register .net to iis
c:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe -i

# install something with webpi, not yet work at 0.9.9.8
# cinst theawesomeurlrewritemodule -source webpi

# NuGet commandline and our own repositories
cinst nuget.commandline -y
nuget.exe sources add -Name "Solita public" -Source "https://www.myget.org/F/solita-episerver/"
nuget.exe sources add -Name "EPiServer" -Source "http://nuget.episerver.com/feed/packages.svc"

#other stuff
cinst keepass -y