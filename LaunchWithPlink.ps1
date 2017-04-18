[CmdletBinding()]
Param
(
    [Parameter(Mandatory=$True)]
    [string] $proxyport,
    [Parameter(Mandatory=$True)]
    [string] $webport,
    [Parameter(Mandatory=$True)]
    [string] $plinkport,
    [Parameter(Mandatory=$True)]
    [string] $plinkkeypath,
    [Parameter(Mandatory=$True)]
    [string] $plinkuser,
    [Parameter(Mandatory=$True)]
    [string] $plinkkeypassphrase,
    [Parameter(Mandatory=$false)]
    [string] $vnc = "localhost:5900"
)

Write-Verbose "proxyport = $proxyport"
Write-Verbose "webport = $webport"
Write-Verbose "plinkport = $plinkport"
Write-Verbose "plinkkeypath = $plinkkeypath"
Write-Verbose "plinkuser = $plinkuser"
Write-Verbose "plinkkeypassphrase = $plinkkeypassphrase"
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

function Install-Putty()
{
    Write-Verbose "Installing putty"
    choco install putty.install -y    
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
    [string] $arguments = "http-server $($novncfolder) -p $($webport)"
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
    [string] $websockifyjs = Join-Path $($websockifyfolder) -ChildPath "other\js\websockify.js" 
    [string] $arguments = "node $($websockifyjs) localhost:$($proxyport) $($vnc)"
    Write-Verbose "Starting websockify proxy from localhost:$($proxyport) to $($vnc)"
    $websockifyprocess = Start-Process powershell -ArgumentList $arguments -PassThru 
    If ($websockifyprocess -eq $null)
    {
        throw "Failed to start websockify proxy"
    }
    return $websockifyprocess
}

function Start-Plink([string] $vnc, [string] $plinkport, [string] $plinkkeypath, [string] $plinkuser, [string] $plinkkeypassphrase)
{
    [string] $vncip = $vnc.Split(":")[0]
    [string] $vncport = $vnc.Split(":")[1]
    [string] $arguments = "echo y | plink -L $($plinkport):localhost:$($vncport) -i $($plinkkeypath) $($plinkuser)@$($vncip) -pw $($plinkkeypassphrase)"
    Write-Verbose "Starting ssh tunnel"
    $plinkprocess = Start-Process powershell -ArgumentList $arguments -PassThru
    If ($plinkprocess -eq $null)
    {
        throw "Failed to start plink tunnel"
    }
    return $plinkprocess
}

function Import-ChocolateyModules()
{
    Write-Verbose "Importing chocolatey helper functions for powershell"
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyInstaller.psm1"
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
    If (Find-ListeningPort -port $sshport)
    {
        throw "Port $sshport in use. Try -sshport PORT"
    }

    Import-ChocolateyModules
    Install-Putty    
    Install-NodeJs            
    [string] $currentpath = Set-NodeVariables
    Update-SessionEnvironment     

    $tempfolder = New-Item -ItemType directory "$($PWD)\$(get-date -f yyyyMMddHHmmss)" 
    [string] $webfolder = Join-Path $tempfolder -ChildPath "\web"
    [string] $novncfolder = Join-Path $tempfolder -ChildPath "\web\noVNC-master"
    [string] $websockifyfolder = Join-Path $tempfolder -ChildPath "\web\websockify-master"

    Get-NoVncSource -tempfolder $tempfolder -novncfolder $novncfolder
    Get-WebSockifySource -tempfolder $tempfolder -websockifyfolder $websockifyfolder

    $novncprocess = Start-NoVncWebServer -novncfolder $novncfolder -webport $webport
    $websockifyprocess = Start-WebSockifyProxy -websockifyfolder $websockifyfolder -proxyport $proxyport -vnc "localhost:$($plinkport)"
    $plinkprocess = Start-Plink -vnc $vnc -plinkport $plinkport -plinkkeypath $plinkkeypath -plinkuser $plinkuser -plinkkeypassphrase $plinkkeypassphrase

    [string] $novncclient = "http://localhost:$($webport)/vnc.html?host=localhost&port=$($proxyport)"
    Start-Process $novncclient

    Wait-Process -InputObject $novncprocess, $websockifyprocess, $plinkprocess
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
        Write-Verbose "Removing temporary files"
        Remove-Item $tempfolder -Recurse
    }
    If ($novncprocess -ne $null)
    {
        Write-Verbose "Stopping novnc process"
        Stop-Process $novncprocess -ErrorAction SilentlyContinue
    }
    If ($websockifyprocess -ne $null)
    {
        Write-Verbose "Stopping websockify process"
        Stop-Process $websockifyprocess -ErrorAction SilentlyContinue
    }
    If ($plinkprocess -ne $null)
    {
        Write-Verbose "Stopping plink process"
        Stop-Process $plinkprocess -ErrorAction SilentlyContinue
    }
}