# novnc-launch-powershell
This repository contains an unofficial launch powershell scripts for novnc + websockify.

Initially developed as port for Windows platform of the official novnc launch.sh script, it can be used for quick demostrations or automation purposes too.

## Credits
https://github.com/novnc/

## Prerequisites
To execute the script chocolatey needs to be installed. Check how to install it here https://chocolatey.org/install.

## Instructions
### To launch (http novnc server + ws websockify + vnc web client)

```powershell
	.\Launch.ps1
		-proxyport 2777
		-webport 8081
		-vnc localhost:5900
```
### To launch (https novnc server + wss websockify + vnc web client)

```powershell
	.\LaunchWithSsl.ps1 
		-proxyport 2777
		-webport 8081
		-vnc HostName:5900
		-certpath self.pem
		-keypath key.pem
		-commonname HostName
```		
### To launch (novnc server + websockify + plink + vnc web client)
This option is appropriate when VNC connections are encrypted through an ssh tunnel (http://www.karlrunge.com/x11vnc/ssvnc.html)

```powershell
	.\LaunchWithPlink.ps1
		-proxyport 2777
		-webport 8081
		-plinkport 3200
		-plinkkeypath "key.ppk"
		-plinkuser "user"
		-plinkkeypassphrase "passphrase"
		-vnc localhost:5900                
```	
## Arguments

	- proxyport 		a local port where the websockets to tcp proxy should listen for websocket requests.
	- webport 		a local port where the novnc server should listen for http requests.
	- plinkport 		a local port where the plink forwards the remote secure connection.
	- plinkkeypath	 	a local path where is the putty key is located.
	- plinkuser 		a user from the vnc host.
	- plinkkeypassphrase 	a key to access the putty key.
	- vnc 			a tuple ip:port where a vnc server listens for connections (default is localhost:5900).
	- certpath		a full path to the certificate file
	- keypath		a full path to the certificate key file
	- commonname		a host name specified as CN in the certificate

## Description
The script automates the following actions: 

	- installing the required components
		- nodejs
		- npm
		- nodejs modules (optimist, policyfile, ws and http-server)
		- putty (only applicable to LaunchWithPlink.ps1)
	- configure components
	- download the novnc and websockify source from master branch
	- start the services
		- novnc webserver
		- websockify proxy server
		- plink tunnel (only applicable to LaunchWithPlink.ps1)
	- open novnc browser instance
	
## Troubleshooting
*Ensure prerequisites are met

*Ensure powershell execution policy, allows you to run the script (e.g. RemoteSigned)

*The specified port numbers should correspond to an available port, not already bound to another service.

*Add -Verbose argument to get additional log information

