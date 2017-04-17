# novnc-launch-powershell
This repository contains an unofficial launch powershell scripts for novnc + websockify.
It can be used for quick demostrations or automation purposes too.

## Credits
https://github.com/novnc/

## Instructions
### To start (novnc + websockify) server and open a vnc browser instance
.\Launch.ps1 -proxyport 2777 -webport 8081

### To start (novnc + websockify) server over SSH channel and open a vnc browser instance
.\LaunchWithSsh.ps1 -proxyport 2777 -webport 8081
