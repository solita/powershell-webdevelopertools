# load WebAdministration
Import-Module WebAdministration


function Get-CurrentPath {
    <#
    .SYNOPSIS 
    Gets current path

    .DESCRIPTION
    Helper function to get current path

    .EXAMPLE
    Get-CurrentPath
    #>
    (Get-Item -Path ".\" -Verbose).FullName
}

function New-WebDevPfxCertificate {
    <#
    .SYNOPSIS 
    Creates a pfx certificate

    .DESCRIPTION
    Creates a pfx certificate with given name and password and exports it to current path

    .EXAMPLE
    New-WebDevPfxCertificate  "my-test-cert" "Abbacd123"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CN,
        [Parameter(Mandatory=$true)]
        [string]$password)
    # tries to achieve same thing as following lines
    #makecert.exe -r -a sha256 -len 2048 -n $cname -sv $CN.pvk $CN.cer
    #pvk2pfx.exe -pvk $CN.pvk -spc $CN.cer -pfx $CN.pfx -po $password
    $currentPath = Get-CurrentPath
    $outputPath = ($currentPath + "\" + $CN + ".pfx")
    $scriptblockMakeCert = { makecert.exe -r -a sha256 -len 2048 -n "cn=$($args[0])" -sv "$($args[0]).pvk" "$($args[0]).cer" }
    $scriptblockConvertToPfx = { pvk2pfx.exe -pvk "$($args[0]).pvk" -spc "$($args[0]).cer" -pfx "$($args[0]).pfx" -po "$($args[1])" -f }
    $null = Invoke-Command -ScriptBlock $scriptblockMakeCert -ArgumentList $CN
    $null = Invoke-Command -ScriptBlock $scriptblockConvertToPfx -ArgumentList $CN, $password
    Import-WebDevPfxCertificate $outputPath "LocalMachine" "My" $password
    # TODO: Once win10 is in use change to use below when new flags can be used https://technet.microsoft.com/en-us/library/hh848633%28v=wps.640%29.aspx
    #$cert = New-SelfSignedCertificate -DnsName $CN -CertStoreLocation cert:\LocalMachine\My 
    #$pwd = ConvertTo-SecureString -String $password -Force -AsPlainText
    #$null = Export-PfxCertificate -cert $cert -FilePath $outputPath -Password $pwd
}

function Import-WebDevPfxCertificate {
    <#
    .SYNOPSIS 
    Imports a pfx certificate 

    .DESCRIPTION
    Imports a given pfx certificate to given store

    .EXAMPLE
    Import-WebDevPfxCertificate "c:\lol.pfx"
    
    .EXAMPLE
    Import-WebDevPfxCertificate "c:\lol.pfx" "LocalMachine" "My" "password"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]$certPath,
        [String]$certRootStore = "LocalMachine",
        [String]$certStore ="My",
        $pfxPass = $null)
    $pfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2

    if ($pfxPass -eq $null) {$pfxPass = read-host "Enter the pfx password" -assecurestring}
    $KeyStorageFlags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable -bxor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::MachineKeySet -bxor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet;
        
    $pfx.import($certPath,$pfxPass,$KeyStorageFlags)

    $store = new-object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore)
    $store.open("MaxAllowed")
    $store.add($pfx)
    $store.close()
}

function Import-WebDev509Certificate {
    <#
    .SYNOPSIS 
    Imports a 509 certificate to local store

    .DESCRIPTION
    Imports a given 509 certificate to given store

    .EXAMPLE
    Import-WebDev509Certificate "c:\lol.crt"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]$certPath,
        [String]$certRootStore = "LocalMachine",
        [String]$certStore ="My")
     
    $pfx = new-object System.Security.Cryptography.X509Certificates.X509Certificate2
    $pfx.import($certPath)
     
    $store = new-object System.Security.Cryptography.X509Certificates.X509Store($certStore,$certRootStore)
    $store.open("MaxAllowed")
    $store.add($pfx)
    $store.close()
}

function Set-CertificatePrivateKeyRightsToIIS_IUsrs {
    <#
    .SYNOPSIS 
    Gives IIS_IUSRS rights to certificate

    .DESCRIPTION
    Gives IIS_IUSRS rights to certificate

    .EXAMPLE
    Set-CertificatePrivateKeyRightsToIIS_IUsrs "my-test-cert" 
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$cnName)
    $rsaFile = $null     
    Try
    {
        $WorkingCert = Get-ChildItem CERT:\LocalMachine\My |where {$_.Subject -match $cnName} | sort $_.NotAfter -Descending | select -first 1 -erroraction STOP
        $TPrint = $WorkingCert.Thumbprint
        Write-Verbose "Thumbprint: $TPrint" 
        $rsaFile = $WorkingCert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
        Write-Verbose "RSA file container: $rsaFile" 
    }
    Catch
    {
        Write-Error "Error: unable to locate certificate for $($cnName)"
    }
    
    $keyPath = ("$env:ProgramData" + "\Microsoft\Crypto\RSA\MachineKeys\")
    $fullPath=$keyPath+$rsaFile
    $acl=$acl = (Get-Item $fullPath).GetAccessControl('Access')
    $acl=Get-Acl -Path $fullPath
    $permission="IIS_IUSRS","Read","Allow"
    $accessRule=new-object System.Security.AccessControl.FileSystemAccessRule $permission
    $acl.AddAccessRule($accessRule)
    
    Try
    {
        Set-Acl $fullPath $acl
        #icacls $fullPath /grant "IIS_IUSRS:(F)"
        #icacls $fullpath /grant "IIS_IUSRS"`:RX
        #icacls.exe test.txt /grant "IIS AppPool\IIS_IUSRS":(OI)(CI)M
    }
    Catch
    {
        Write-Error "Error: unable to set ACL on certificate"
    }
}

function Install-FrontDeveloperFrameworks {
    <#
    .SYNOPSIS 
    Installs node, ruby and npm

    .DESCRIPTION
    Installs node, ruby and npm

    .EXAMPLE
    Install-FrontDeveloperFrameworks 
    #>
    [CmdletBinding()]
    param()
    cinst nodejs.install -y
    mkdir "$home\AppData\Roaming\npm"
    cinst ruby -y
    cinst npm -y
}

function Register-AspNETForIIS {
    <#
    .SYNOPSIS 
    Registers ASP.NET for IIS

    .DESCRIPTION
    Registers ASP.NET for IIS

    .EXAMPLE
    Register-AspNETForIIS 
    #>
    [CmdletBinding()]
    param()
    # register .net to iis
    c:\Windows\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe -i
}


function Invoke-GulpWatch {
    <#
    .SYNOPSIS 
    Starts gulp watch

    .DESCRIPTION
    Starts gulp watch

    .EXAMPLE
    Invoke-GulpWatch C:\watch\this\gulp 
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$gulpDirectory)
    start-process powershell.exe -argument '-nologo -noprofile -executionpolicy bypass -command cd $gulpDirectory; call npm install; call gulp watch;'
}

function Remove-AspNETCache {
    <#
    .SYNOPSIS 
    Removes aspnetcache

    .DESCRIPTION
    Removes aspnetcache

    .EXAMPLE
    Remove-AspNETCache 
    #>
    [CmdletBinding()]
    param()
    iisreset -stop
    # http://blogs.technet.com/b/heyscriptingguy/archive/2012/02/22/the-best-way-to-use-powershell-to-delete-folders.aspx
    $foldersToDelete = @()
    $foldersToDelete += ($ENV:Windir + "\Microsoft.NET\Framework\v2.0.50727\Temporary ASP.NET Files\root") 
    $foldersToDelete += ($ENV:Windir + "\Microsoft.NET\Framework64\v2.0.50727\Temporary ASP.NET Files\root") 
    $foldersToDelete += ($ENV:Windir + "\Microsoft.NET\Framework\v4.0.30319\Temporary ASP.NET Files\root")
    $foldersToDelete += ($ENV:Windir + "\Microsoft.NET\Framework64\v4.0.30319\Temporary ASP.NET Files\root")
    
    foreach($folder in $foldersToDelete)
    {
        gci $folder -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }
    
    iisreset -start
}

function Set-WebDevWebSite {
    <#
    .SYNOPSIS 
    Creates website, bindings and applicationPool

    .DESCRIPTION
    Creates website, bindings and applicationPool

    .EXAMPLE
    Set-WebSite -SiteName $siteName -PhysicalPath $path -AppPoolName $pool -BindAlsoSiteName $bindSiteName -Bindings $Bindings 
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SiteName,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PhysicalPath,
        [string]$AppPoolName = $null,
        [string]$AppPoolDotNetVersion = "v4.0",
        [bool]$RemoveApplicationPool = $false,
        [bool]$BindAlsoSiteName = $false,
        [array]$Bindings = @())

    # Fetch the website and pass it to remove if found 
    Get-Website | ? {$_.Name -eq $SiteName } | Remove-WebSite -ErrorAction SilentlyContinue
    # If applicationPool is given delete and recreate it
    if($AppPoolName -ne $null -and $RemoveApplicationPool)
    {
        Remove-WebAppPool -Name $AppPoolName -ErrorAction SilentlyContinue
        $poolCreationInfo = New-WebAppPool -Name $AppPoolName
    }
	# Check if there is no websites 
	if(Get-Website | Measure | Select Count | ? {$_.Count -eq 0})
	{
		# force id (crashes without it if there is no new sites)
		$siteCreationInfo = New-WebSite -Name $SiteName -Id 1 -Port 80 -HostHeader $SiteName -PhysicalPath $PhysicalPath 
	}	
	else 
	{
		# Crete the website
		$siteCreationInfo = New-WebSite -Name $SiteName -Port 80 -HostHeader $SiteName -PhysicalPath $PhysicalPath 
    }
	# if the apppool was given set it
    if($AppPoolName -ne $null)
    {
        Set-ItemProperty IIS:\Sites\$SiteName -name applicationPool -value $AppPoolName
        GCI IIS:\AppPools | ? {$_.Name -eq $AppPoolName} | Set-ItemProperty -Name "managedRuntimeVersion" -Value $AppPoolDotNetVersion
    }
    
    # Set bindings
    Set-WebDevSiteBindings $SiteName $Bindings

    # if the user did not want to bind the site also to sitename then remove it
    if(-Not $BindAlsoSiteName)
    {
        # Fetch the binding that was created in website creation and delete it 
        Get-WebBinding -Port 80 -Name $SiteName | Where bindingInformation -eq ("*:80:" + $SiteName) | Remove-WebBinding
    }
}

function Set-WebDevSiteBindings {
    <#
    .SYNOPSIS 
    Sets site bindings

    .DESCRIPTION
    Sets site bindings

    .EXAMPLE
    Set-SiteBindings -SiteName $siteName -Bindings $Bindings 
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SiteName,
        [array]$Bindings = @())
    # go through all the bindings and create new webbinding for each
    foreach($binding in $bindings)
    {
        Write-Verbose "Adding binding $binding"
        $bindingProtocol = "http"
        $bindingIP = "*"
        $bindingPort = "80"
        $bindingHostHeader = $binding
        $bindingCreationInfo = New-WebBinding -Protocol $binding.protocol -Name $SiteName -IPAddress $bindingIP -Port $bindingPort -HostHeader $bindingHostHeader
    }
}

function Test-EverythingIsInstalled {
    <#
    .SYNOPSIS 
    Tests that iis is properly installed

    .DESCRIPTION
    Test that w3svc process is found and there is .NET in machine and runs regiis

    .EXAMPLE
    Test-EverythingIsInstalled 
    #>
    [CmdletBinding()]
    param()
    # check if there is no iis 
    $IIS = Get-service | Where-Object {$_.name -eq "W3SVC"}
    if (!$IIS)
    {   
        write-error "IIS was not found. Please install it first"
    }

    # check if there is no .net version installed 
    $net40Path = [System.IO.Path]::Combine($env:SystemRoot, "Microsoft.NET\Framework\v4.0.30319")
    $aspnetRegIISFullName = [System.IO.Path]::Combine($net40Path, "aspnet_regiis.exe")
    if ((test-path $aspnetRegIISFullName) -eq $false)
    {
        $message =  "aspnet_regiis.exe was not found in {0}. Make sure Microsoft .NET Framework 4.0 installed first." -f $net40Path
        write-error $message
    }

    # register asp.net for iis 
    start-process -filepath $aspnetRegIISFullName  -argumentlist "-iru"

    # install iis url rewrite module for iis 
}

function Test-IsElevated {
    <#
    .SYNOPSIS 
    Tests elevation

    .DESCRIPTION
    Tests that user is surely running as administrator

    .EXAMPLE
    Test-IsElevated
    #>
    [CmdletBinding()]
    param()
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