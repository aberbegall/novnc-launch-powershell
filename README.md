# novnc-launch-powershell
This repository contains an unofficial launch powershell scripts for novnc + websockify.
Initially developed as port for Windows of the official novnc launch.sh script.
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
		- nodejs modules
		- putty (in case of ssh sscript only)
	- configure components
	- download the novnc and websockify source from master branch
	- start the services
	- open novcn browser instance

## Instructions
### To start (novnc + websockify) server and open a vnc browser instance
#### .\Launch.ps1 -proxyport 2777 -webport 8081 -vnc localhost:5900  -Verbose

Arguments:

	- -proxyport; the port where the websockets to tcp proxy should listen for websocket requests. The script will fail if the port is not available.
	- -webport; the port where the novnc server should listen for http requests. The script will fail if the port is not available.
	- -vnc; (optional) the ip:port where a vnc server listens for connections. 
	- -Verbose; (optional)
