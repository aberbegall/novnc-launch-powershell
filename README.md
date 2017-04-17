# novnc-launch-powershell
This repository contains an unofficial launch powershell scripts for novnc + websockify.
Initially developed as port for Windows of the official novnc launch.sh script.
It can be used for quick demostrations or automation purposes too.

## Credits
https://github.com/novnc/

## Instructions
### To start (novnc + websockify) server and open a vnc browser instance
.\Launch.ps1 -proxyport 2777 -webport 8081 -vnc localhost:5900  -Verbose

  -proxyport; the port where the websockets to tcp proxy should listen for wss request

  -webport; the port where the novnc server will listen for http requests

  -vnc; (optional) the ip:port where the vnc server is listen for connections

  -Verbose; (optional)


### To start (novnc + websockify) server over SSH channel and open a vnc browser instance
.\Launch.ps1 -proxyport 2777 -webport 8081 -vnc localhost:5900  -Verbose

  -proxyport; the port where the websockets to tcp proxy should listen for wss request

  -webport; the port where the novnc server will listen for http requests

  -vnc; (optional) the ip:port where the vnc server is listen for connections

  -Verbose; (optional)
