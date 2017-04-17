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

function Set-VncWebRoot([string] $webpath)
{
    If ($webpath)
    {
        [string]$vncwebfile = "$($webpath)\vnc.html"
        If (-Not (Test-Path $vncwebfile))
        {
            throw [System.IO.FileNotFoundException] "Could not find $($vncwebfile)"
        }
    }
    ElseIf (Test-Path "$($PWD)\vnc.html")
    {
        $webpath = $PWD
    }
    ElseIf (Test-Path "$($PSScriptRoot)\..\vnc.html")
    {
        $webpath = "$($PSScriptRoot)\..\"
    }
    ElseIf (Test-Path "$($PSScriptRoot)\vnc.html")
    {
        $webpath = $($PSScriptRoot)
    }
    ElseIf (Test-Path "$($PSScriptRoot)\..\share\novnc\vnc.html")
    {
        $webpath = "$($PSScriptRoot)\..\share\novnc\"
    }
    Else
    {
        throw [System.IO.FileNotFoundException] "Could not find vnc.html"
    }
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

    Write-Output "Installing nodejs"
    choco install nodejs.install -y

    Write-Output "Installing required nodejs modules"
    npm install -g optimist, policyfile, ws, http-server

    Write-Output "Configuring nodejs installation"
    [Environment]::SetEnvironmentVariable("NODE_PATH", "%AppData%\npm\node_modules", "User")
    [Environment]::SetEnvironmentVariable("Path", ("{0};{1}" -f [Environment]::GetEnvironmentVariable("Path","User"), [Environment]::GetEnvironmentVariable("NODE_PATH","User")), "User")

    $tempfolder = New-Item -ItemType directory "$($PWD)\$(get-date -f yyyyMMddHHmmss)" 
    [string] $webfolder = Join-Path $tempfolder -ChildPath "\web"
    [string] $novncfolder = Join-Path $tempfolder -ChildPath "\web\noVNC-master"
    [string] $websockifyfolder = Join-Path $tempfolder -ChildPath "\web\websockify-master"

    Write-Output "Downloading novnc git master repository; $($tempfolder)\novnc.zip"    
    wget https://github.com/novnc/noVNC/archive/master.zip -OutFile "$($tempfolder)\novnc.zip"
    
    Write-Output "Extracting novnc source in $($novncfolder)"
    Add-Type -AssemblyName "System.IO.Compression.FileSystem"    
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$($tempfolder)\novnc.zip", "$($webfolder)")

    Write-Output "Downloading websockify git master repository; $($tempfolder)\websockify.zip"
    wget https://github.com/novnc/websockify/archive/master.zip -OutFile "$($tempfolder)\websockify.zip"

    Write-Output "Extracting novnc source in $($websockifyfolder)"
    [System.IO.Compression.ZipFile]::ExtractToDirectory("$($tempfolder)\websockify.zip", "$($webfolder)")

    [string]$arguments = "http-server $($novncfolder) -p $($webport)"
    Write-Output "Starting novnc web server on port $($webport)"
    $novncprocess = Start-Process powershell -ArgumentList $arguments -PassThru
    If ($novncprocess -eq $null)
    {
        throw "Failed to start novnc web server"
    }

    [string]$websockifyjs = Join-Path $($websockifyfolder) -ChildPath "other\js\websockify.js" 
    [string]$arguments = "node $($websockifyjs) localhost:$($proxyport) $($vnc)"
    Write-Output "Starting websockify proxy from port :$($proxyport) to $($vnc)"
    $websockifyprocess = Start-Process powershell -ArgumentList $arguments -PassThru
    If ($websockifyprocess -eq $null)
    {
        throw "Failed to start websockify proxy"
    }

    Write-Output ("Navigate to this URL: http://localhost:$($webport)/vnc.html?host=localhost&port=$($proxyport)")

    Wait-Process $novncprocess.Id
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
}