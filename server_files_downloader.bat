@ECHO OFF
set "SteamcmdUrl=https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip"
set "T7XUrl=https://master.bo3.eu/t7x/t7x.exe"
set "EZZBOIIIUrl=https://github.com/Ezz-lol/boiii-free/releases/latest/download/boiii.exe"

::SEtting current folder as InstallPath for UnrankedServer
set "InstallPath=%CD%"

::SteamCMD doesn't want steamcmd and steamapps on the same level folder, for some reason, nesting steamcmd inside steamstuff
mkdir steamstuff
cd steamstuff

::Retrieves SteamCMD
curl -s "%SteamcmdUrl%" -o steamcmd.zip
mkdir steamcmd
move steamcmd.zip steamcmd
cd steamcmd
tar -xf steamcmd.zip

::Downloading server files
echo %InstallPath%
echo Login is required to download Black Ops 3 Unranked Server files
set /p SteamUser=Steam Username: 
steamcmd +force_install_dir %InstallPath% +login %SteamUser% +app_update 545990 validate +quit

::deleting unecessary folders
cd ..
rd /s /q steamcmd
cd ..
rd /s /q steamstuff
rd /s /q steamapps

::deleting unecessary files
cd UnrankedServer
::del copydedicated.bat
::del Launch_Server.bat

::downloading latest t7/boiii/bo3 client
curl -L "%T7XUrl%" -o t7x.exe
curl -L "%EZZBOIIIUrl%" -o boiii.exe
