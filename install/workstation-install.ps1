# powershell.exe -executionpolicy unrestricted -command .\test.ps1
# Set-ExecutionPolicy unrestricted -force
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))

#windows features, these should work like this but didn't at 0.9.9.8
#cinst IIS-WebServerRole -source windowsfeatures
#cinst IIS-ISAPIFilter -source windowsfeatures
#cinst IIS-ISAPIExtensions -source windowsfeatures
#cinst IIS-NetFxExtensibility -source windowsfeatures
#cinst IIS-ASPNET -source windowsfeatures

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
cinst poshgit -y
cinst Nuget.commandline

# Languages
cinst DotNet4.5.2 -y
cinst nodejs.install -y
mkdir "$home\AppData\Roaming\npm"
cinst ruby -y
cinst npm -y

# IDE
cinst sublimetext3 -y
cinst VisualStudio2013Professional -InstallArguments "/Features:'WebTools'" -y

# register .net to iis
c:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe -i

# install something with webpi, not yet work at 0.9.9.8
# cinst theawesomeurlrewritemodule -source webpi

# NuGet commandline and our own repositories
cinst nuget.commandline -y
nuget.exe sources add -Name "Solita public" -Source "https://www.myget.org/F/solita-episerver/"
nuget.exe sources add -Name "EPiServer" -Source "http://nuget.episerver.com/feed/packages.svc"