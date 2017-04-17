[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$True)]
    [string] $proxyport,
    [Parameter(Mandatory=$True)]
    [string] $webport,
    [Parameter(Mandatory=$false)]
    [string] $vnc = "localhost:5900"
)

Write-Verbose "proxyport = $proxyport"
Write-Verbose "webport = $webport"
Write-Verbose "vnc = $vnc"

function Find-ListeningPort([int] $port)
{
     $ipproperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
     $listening = $ipproperties.GetActiveTcpListeners() | where Port -EQ $port
     return ($listening -ne $null)
}

function Install-NodeJs()
{
    Write-Verbose "Installing nodejs"
    choco install nodejs.install -y

    Write-Verbose "Installing required nodejs modules"
    npm install -g optimist, policyfile, ws, http-server

    Write-Verbose "Configuring nodejs installation"
    [Environment]::SetEnvironmentVariable("NODE_PATH", "%AppData%\npm\node_modules", "User")
    [Environment]::SetEnvironmentVariable("Path", ("{0};{1}" -f [Environment]::GetEnvironmentVariable("Path","User"), [Environment]::GetEnvironmentVariable("NODE_PATH","User")), "User")    
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

function Start-NoVncWebServer([string] $novncfolder, [string] $webport)
{
    [string]$arguments = "http-server $($novncfolder) -p $($webport)"
    Write-Verbose "Starting novnc web server on port $($webport)"
    $novncprocess = Start-Process powershell -ArgumentList $arguments -PassThru
    If ($novncprocess -eq $null)
    {
        throw "Failed to start novnc web server"
    }
    return $novncprocess
}

function Start-WebSockifyProxy([string] $websockifyfolder, [string] $proxyport, [string] $vnc)
{
    [string]$websockifyjs = Join-Path $($websockifyfolder) -ChildPath "other\js\websockify.js" 
    [string]$arguments = "node $($websockifyjs) localhost:$($proxyport) $($vnc)"
    Write-Verbose "Starting websockify proxy from port localhost:$($proxyport) to $($vnc)"
    $websockifyprocess = Start-Process powershell -ArgumentList $arguments -PassThru 
    If ($websockifyprocess -eq $null)
    {
        throw "Failed to start websockify proxy"
    }
    return $websockifyprocess
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

    Install-NodeJs

    $tempfolder = New-Item -ItemType directory "$($PWD)\$(get-date -f yyyyMMddHHmmss)" 
    [string] $webfolder = Join-Path $tempfolder -ChildPath "\web"
    [string] $novncfolder = Join-Path $tempfolder -ChildPath "\web\noVNC-master"
    [string] $websockifyfolder = Join-Path $tempfolder -ChildPath "\web\websockify-master"

    Get-NoVncSource -tempfolder $tempfolder -novncfolder $novncfolder
    Get-WebSockifySource -tempfolder $tempfolder -websockifyfolder $websockifyfolder

    $novncprocess = Start-NoVncWebServer -novncfolder $novncfolder -webport $webport
    $websockifyprocess = Start-WebSockifyProxy -websockifyfolder $websockifyfolder -proxyport $proxyport -vnc $vnc

    [string] $novncclient = "http://localhost:$($webport)/vnc.html?host=localhost&port=$($proxyport)"
    Sleep -Seconds 1
    Start-Process $novncclient

    Wait-Process -InputObject $novncprocess, $websockifyprocess
}
Catch 
{
    Write-Error $_
}
Finally 
{
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
