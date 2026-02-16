# BlackOps3ServerInstaller

<img width="3840" height="1240" alt="6534a8436e907efb0ced99edd8d02435" src="https://github.com/user-attachments/assets/f40d08e8-6285-423f-baf2-ddb873ed4301" />


Simplifying Black Ops 3 server installation for both Steam Black Ops 3 and Custom Clients (like T7X or BOIII). \
**No copyrighted files are distributed using these scripts.** \
\
This repository merges configurations and scripts from these projects:\
[T7X](https://forum.alterware.dev/t/how-to-install-the-t7x-client/1418/2)\
[EZZBOIII](https://forum.ezz.lol/topic/5/bo3-guide)\
[T7 Configuration files](https://github.com/Dss0/t7-server-config)\
[BOIIIEasyServer](https://github.com/rcv11x/BOIIIEasyServer)

**You can create servers on both Linux-based platforms and Windows.**

**There doesn't seem to be a way to run zombies server using the official BO3 Server Launcher. Currently zombies servers are only available using custom clients**

## Table of Contents
- [How to install on Windows](#how-to-install-on-windows)
- [How to install on Linux (Ubuntu, Debian, Arch)](#how-to-install-on-linux-ubuntu-debian-arch)
- [How to install on NixOS](#how-to-install-on-nixos)
- [EZZBOIII Server Additional Steps](#ezzboiii-server-additional-steps)
- [Cool, but Zombies?](#cool-but-zombies)
- [Mods?](#mods)
- [Custom Maps?](#custom-maps)
- [Notes](#notes)

## How to install on Windows
1. Clone this repository wherever you want to install the server
2. Double click on `server_files_downloader.bat`
3. Wait for server files to download through [steamcmd](https://developer.valvesoftware.com/wiki/SteamCMD)
4. Wait for the custom clients executable to download  (currently [T7X](https://forum.alterware.dev/t/how-to-install-the-t7x-client/1418/2) or [EZZBOIII](https://forum.ezz.lol/topic/5/bo3-guide))
5. **(For Custom Clients)** You can now edit `CustomClient_Server.bat` and `zone/server.cfg` (or `zone/server_cp.cfg` or `zone/server_zm.cfg`) with your desired settings
6. **(For Custom Clients)** Launch your server using `CustomClient_Server.bat boiii` if you want to use EZBOIII or `CustomClient_Server.bat t7x` if you want to use T7X
7. **(For official servers on vanilla BO3)** Launch your server using `Launch_Server.bat`
5. Done!

## How to install on Linux (Ubuntu, Debian, Arch)
Official BO3 servers only aimed for Windows support, but [Wine](https://www.winehq.org/) can help us run it on Linux too.
1. Clone this repository wherever you want to install the server
2. Make `server_files_downloader.sh` executable using `chmod +x` and execute it with `./server_files_downloader.sh ubuntu` (note, I currently support `ubuntu`, `debian` and `arch`). Example, if you're on arch just type `./server_files_downloader.sh arch`
3. Follow the setup "wizard" and confirm a bunch of wine required steps. Wait for server files to download through [steamcmd](https://developer.valvesoftware.com/wiki/SteamCMD)
4. Wait for the custom clients executable to download  (currently [T7X](https://forum.alterware.dev/t/how-to-install-the-t7x-client/1418/2) or [EZZBOIII](https://forum.ezz.lol/topic/5/bo3-guide))
5. **(For Custom Clients)** Make `CustomClient_Server.sh` executable using `chmod +x`. Edit your `CustomClient_Server.sh` and `zone/server.cfg` (or `zone/server_cp.cfg` or `zone/server_zm.cfg`) with your desired settings
6. **(For Custom Clients)** Launch your server using `CustomClient_Server.sh boiii` if you want to use EZBOIII or `CustomClient_Server.sh t7x` if you want to use T7X
7. **(For official servers on vanilla BO3)** Launch your server using `Launch_Server.sh`
5. Done!

## How to install on NixOS

NixOS support is provided via a Nix flake with both standalone scripts and a NixOS module for systemd service integration.

### Option 1: Using Nix Flakes (Recommended)

```bash
# Clone this repository
git clone https://github.com/framilano/BlackOps3ServerInstaller.git
cd BlackOps3ServerInstaller

# Install the server (you'll be prompted for Steam credentials)
nix run .#install

# Start the server
nix run .#server -- --mp          # Multiplayer
nix run .#server -- --zm          # Zombies
nix run .#server -- --cp          # Campaign/Coop

# Or with custom options
nix run .#server -- --dir ~/bo3-server --client boiii --port 27017 --mp
```

### Option 2: Using nix-shell (Traditional)

```bash
# Enter the development shell
nix-shell

# Run the installation script
./nixos/install.sh

# Launch the server
./nixos/launch.sh --mp
./nixos/launch.sh --help    # Show all options
```

### Option 3: NixOS Module (Systemd Service)

Add the flake to your NixOS configuration:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    bo3-server.url = "github:framilano/BlackOps3ServerInstaller";
  };

  outputs = { nixpkgs, bo3-server, ... }: {
    nixosConfigurations.myserver = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        bo3-server.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

Configure the server in your `configuration.nix`:

```nix
{ config, pkgs, ... }:
{
  services.bo3-server = {
    enable = true;
    steamUser = "your_steam_username";  # Required for installation
    client = "boiii";                    # boiii, t7x, or official
    port = 27017;
    serverName = "^5My ^7NixOS Server";
    description = "Powered by NixOS";
    maxClients = 18;
    openFirewall = true;

    # Map rotation
    mapRotation = [
      { gametype = "tdm"; map = "mp_biodome"; }
      { gametype = "dom"; map = "mp_sector"; }
      { gametype = "tdm"; map = "mp_spire"; }
    ];

    # Or use a custom config file
    # configFile = "server_zm.cfg";
  };
}
```

Then install and start the server:

```bash
# First, run the installation (requires TTY for Steam login)
sudo systemctl start bo3-server-install

# Start the server
sudo systemctl start bo3-server

# Enable auto-start on boot
sudo systemctl enable bo3-server

# Check logs
journalctl -u bo3-server -f
```

### NixOS Module Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable the BO3 server |
| `dataDir` | path | /var/lib/bo3-server | Server installation directory |
| `client` | enum | "boiii" | Client: boiii, t7x, official |
| `steamUser` | string | "" | Steam username for installation |
| `port` | int | 27017 | Game server port |
| `serverName` | string | "^5NixOS ^7Black Ops 3 Server" | Server name |
| `maxClients` | int | 18 | Maximum players |
| `password` | string | "" | Server password |
| `rconPassword` | string | "" | RCON password |
| `modId` | string | "" | Steam Workshop mod ID |
| `botDifficulty` | int (0-3) | 1 | Bot difficulty |
| `botMinPlayers` | int | 0 | Fill with bots up to this count |
| `mapRotation` | list | [...] | Map rotation list |
| `configFile` | string | null | Use custom config instead |
| `openFirewall` | bool | false | Open firewall ports |

## EZZBOIII Server Additional Steps
EZZBOIII requires some additional files in your `%APPDATA%/Local` folder to create a new server. Extract [`boiii-server-files.zip`](https://github.com/framilano/BlackOps3ServerInstaller/blob/main/boiii-server-files.zip) and move the extracted `boiii` folder:
- Windows: in your `%APPDATA%/Local` folder
- Linux: open your wine prefix and copy the `boiii` folder in `AppData/Local` folder present in it

## Cool, but Zombies?
The default server files only downloads MP-ready stuff. To serve a Zombies server you need to copy these fast files
from your BO3 game files and put them into `zone`:

```
zone/en_zm_patch.ff
zone/en_zm_common.ff
zone/en_zm_levelcommon.ff
zone/zm_patch.ff
zone/zm_common.fd
zone/zm_common.ff
zone/zm_levelcommon.ff
```
Let's say you want to create a Shadows of Evil server, you need to copy these fast files too.
```
zone/en_zm_zod.ff
zone/en_zm_zod_patch.ff
zone/zm_zod.ff
zone/zm_zod.fd
zone/zm_zod_patch.ff
```

## Mods?
There's a difference between Custom Maps and Mods, this section will explain how to load a mod downloaded from the Steam Workshop.
Let's say you subscribed to the [The Kermit Mod](https://steamcommunity.com/sharedfiles/filedetails/?id=1638465081), this will create a folder in your Steam folder in `steamapps/workshop/content/311210/1638465081`, create a new `mods` folder inside the root of your server folder (in UnrankedServer) and copy the folder named `1638465081` (this number changes depending on the mod) inside it. The resulting folders structure should look like this:

![immagine](https://github.com/user-attachments/assets/23843aca-0bd8-4dbc-8cfe-8dba4eba12c0)

Now modify the `set ModFolderName=` in `CustomClient_Server.bat` into `set ModFolderName=1638465081`, that's it, you're done!

## Custom Maps?
This section will explain how to load custom maps downloaded from the Steam Workshop.
Let's say you downloaded the [Mob of the Dead](https://steamcommunity.com/sharedfiles/filedetails/?id=3373649394) custom map and want to host a server with it, create the `usermaps` folder inside the root of your server folder (in UnrankedServer) and create a folder within it called `zm_prison` (the map codename, easily guess the name from the map gamefiles), put all map files inside this folder.

![Screenshot_2025-05-10_22-47-36](https://github.com/user-attachments/assets/002f790f-9843-4288-8fb4-67c929bb4f61)

Edit `server_zm.cfg` and add in map rotation `zm_prison`

`set sv_maprotation "gametype zclassic map zm_prison"`

That's it


## Notes
1. Unless you're playing LAN with friends, you need to port forward you router and open the ports used by your server in Windows Firewall.
2. If you don't need any custom client, just delete `t7x.exe` or `boiii.exe`.
3. Remember to change the port in `CustomClient_Server.bat` if you're launching the server in the same machine where you're playing Black Ops 3.
4. To save space, you can delete any unused fast files in `UnrankedServer/zone`
5. **(For Custom Clients)** To customise your server maps rotation and gamemodes just edit the files in `UnrankedServer/zone`, `server_zm.cfg` changes zombies configuration, `server.cfg` changes multiplayer configurations, `server_cp.cfg` changes coop campaign configuration.
These files can be executed even with the vanilla `Launch_Server.bat` or `Launch_Server.sh` but you need to edit these first to execute the desired .cfg file.
