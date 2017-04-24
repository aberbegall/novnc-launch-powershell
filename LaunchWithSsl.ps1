[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$True)]
    [string] $proxyport,
    [Parameter(Mandatory=$True)]
    [string] $webport,
    [Parameter(Mandatory=$True)]
    [string] $certpath,
    [Parameter(Mandatory=$True)]
    [string] $keypath,
    [Parameter(Mandatory=$True)]
    [string] $commonname,
    [Parameter(Mandatory=$false)]
    [string] $vnc = "localhost:5900"    
)

Write-Verbose "proxyport = $proxyport"
Write-Verbose "webport = $webport"
Write-Verbose "certpath = $certpath"
Write-Verbose "keypath = $keypath"
Write-Verbose "commonname = $commonname"
Write-Verbose "vnc = $vnc"

function Find-ListeningPort([int] $port)
{
     $ipproperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
     $listening = $ipproperties.GetActiveTcpListeners() | where Port -EQ $port
     return ($listening -ne $null)
}

function Set-NodeVariables()
{
    Write-Verbose "Configuring nodejs installation"
    [string] $modulespath = Join-Path $env:APPDATA -ChildPath "\npm\node_modules"
    [Environment]::SetEnvironmentVariable("NODE_PATH", $modulespath, "Machine")
    $currentpath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    [Environment]::SetEnvironmentVariable("Path", ("{0};{1}" -f $currentpath.ToString(), [Environment]::GetEnvironmentVariable("%NODE_PATH%","Machine")), "Machine")    
    return $currentpath.ToString()
}

function Install-NodeJs()
{
    Write-Verbose "Installing nodejs"
    choco install nodejs.install -y

    Update-SessionEnvironment

    Write-Verbose "Installing required nodejs modules"
    npm install -g optimist, policyfile, ws, http-server        
}

function Get-NoVncSource([string] $tempfolder, [string] $novncfolder)
{
    Write-Verbose "Downloading novnc git master repository; $($tempfolder)\novnc.zip"    
    wget https://github.com/novnc/noVNC/archive/master.zip -OutFile "$($tempfolder)\novnc.zip"
    
    Write-Verbose "Extracting novnc source in $($novncfolder)"
    Add-Type -AssemblyName "System.IO.Compression.FileSystem"    
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$($tempfolder)\novnc.zip", "$($webfolder)")
}

function Get-WebSockifySource([string] $tempfolder, [string] $websockifyfolder)
{
    Write-Verbose "Downloading websockify git master repository; $($tempfolder)\websockify.zip"
    wget https://github.com/novnc/websockify/archive/master.zip -OutFile "$($tempfolder)\websockify.zip"

    Write-Verbose "Extracting novnc source in $($websockifyfolder)"
    Add-Type -AssemblyName "System.IO.Compression.FileSystem"    
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$($tempfolder)\websockify.zip", "$($webfolder)")
}

function Start-NoVncWebServer([string] $novncfolder, [string] $webport, [string] $certpath, [string] $keypath, [string] $commonname)
{
    [string]$arguments = "http-server $($novncfolder) -a $($commonname) -p $($webport) -S -C $($certpath) -K $($keypath)"
    Write-Verbose "Starting novnc web server on port $($webport)"
    $novncprocess = Start-Process powershell -ArgumentList $arguments -PassThru
    If ($novncprocess -eq $null)
    {
        throw "Failed to start novnc web server"
    }
    return $novncprocess
}

function Start-WebSockifyProxy([string] $websockifyfolder, [string] $proxyport, [string] $vnc, [string] $certpath, [string] $keypath, [string] $commonname)
{
    [string]$websockifyjs = Join-Path $($websockifyfolder) -ChildPath "other\js\websockify.js" 
    [string]$arguments = "node $($websockifyjs) --cert $($certpath) --key $($keypath) $($commonname):$($proxyport) $($vnc)"
    Write-Verbose "Starting websockify proxy from port $($commonname):$($proxyport) to $($vnc)"
    $websockifyprocess = Start-Process powershell -ArgumentList $arguments -PassThru 
    If ($websockifyprocess -eq $null)
    {
        throw "Failed to start websockify proxy"
    }
    return $websockifyprocess
}

function Import-ChocolateyModules()
{
    Write-Verbose "Importing chocolatey helper functions for powershell"
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1"
}

function Save-Path([string] $currentpath)
{
    [string] $backuppath = Join-Path $($PWD) -ChildPath "path.back"
    ("{0} - {1}" -f [datetime]::now.ToString('yyyy-MM-dd'), $currentpath) | Out-File $backuppath -Append
}

Try 
{
    If (Find-ListeningPort -port $proxyport)
    {
        throw "Port $proxyport in use. Try -proxyport PORT"
    }
    If (Find-ListeningPort -port $webport)
    {
        throw "Port $webport in use. Try -webport PORT"
    }

    Import-ChocolateyModules
    Install-NodeJs
    [string] $currentpath = Set-NodeVariables
    Save-Path -currentpath $currentpath
    Update-SessionEnvironment 

    $tempfolder = New-Item -ItemType directory "$($PWD)\$(get-date -f yyyyMMddHHmmss)" 
    [string] $webfolder = Join-Path $tempfolder -ChildPath "\web"
    [string] $novncfolder = Join-Path $tempfolder -ChildPath "\web\noVNC-master"
    [string] $websockifyfolder = Join-Path $tempfolder -ChildPath "\web\websockify-master"

    Get-NoVncSource -tempfolder $tempfolder -novncfolder $novncfolder
    Get-WebSockifySource -tempfolder $tempfolder -websockifyfolder $websockifyfolder

    $novncprocess = Start-NoVncWebServer -novncfolder $novncfolder -webport $webport -certpath $certpath -keypath $keypath -commonname $commonname
    $websockifyprocess = Start-WebSockifyProxy -websockifyfolder $websockifyfolder -proxyport $proxyport -vnc $vnc -certpath $certpath -keypath $keypath -commonname $commonname

    [string] $novncclient = "https://$($commonname):$($webport)/vnc.html?host=$($commonname)&port=$($proxyport)"
    Start-Process $novncclient

    Wait-Process -InputObject $novncprocess, $websockifyprocess
}
Catch 
{    
    Write-Error $_
}
Finally 
{ 
    If ($currentpath -ne $null)
    {
        Write-Verbose "Reverting system path variable value"
        [Environment]::SetEnvironmentVariable("Path", $currentpath, "Machine")
    }
    If (Test-Path $tempfolder)
    {
        Remove-Item $tempfolder -Recurse
    }
    If ($novncprocess -ne $null)
    {
        Stop-Process $novncprocess -ErrorAction SilentlyContinue
    }
    If ($websockifyprocess -ne $null)
    {
        Stop-Process $websockifyprocess -ErrorAction SilentlyContinue
    }
}
