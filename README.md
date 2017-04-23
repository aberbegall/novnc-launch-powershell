# novnc-launch-powershell
This repository contains an unofficial launch powershell scripts for novnc + websockify.
Initially developed as port for Windows platform of the official novnc launch.sh script.
It can be used for quick demostrations or automation purposes too.

## Credits
https://github.com/novnc/

## Prerequisites
To execute the script chocolatey needs to be installed. Check how to install it here https://chocolatey.org/install.

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
	- open novcn browser instance

## Instructions
### To start (novnc + websockify) server and open a vnc browser instance
#### .\Launch.ps1 -proxyport 2777 -webport 8081 -vnc localhost:5900  -Verbose

Arguments:

	- proxyport; a local port where the websockets to tcp proxy should listen for websocket requests.
	- webport; a local port where the novnc server should listen for http requests.
	- vnc; (default is localhost:5900) the ip:port where a vnc server listens for connections. 
	- Verbose; (optional)

### To start (novnc + websockify + plink) server and open a vnc browser instance
#### \LaunchWithPlink.ps1 -proxyport 2777 -webport 8081 -plinkport 3200 -plinkkeypath "key.ppk" -plinkuser "user" -plinkkeypassphrase "passphrase" -vnc localhost:5900 -Verbose

Arguments:

	- proxyport; a local port where the websockets to tcp proxy should listen for websocket requests.
	- webport; a local port where the novnc server should listen for http requests.
	- plinkport; a local port where the plink forwards the remote secure connection.
	- plinkkeypath; a local path where is the putty key is located.
	- plinkuser; a user from the vnc host.
	- plinkkeypassphrase; a key to access the putty key.
	- vnc; (default is localhost:5900) the ip:port where a vnc server listens for connections. 
	- Verbose; (optional)
