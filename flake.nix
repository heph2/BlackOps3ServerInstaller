{
  description = "Black Ops 3 Dedicated Server for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      # NixOS module for the BO3 server
      nixosModule = import ./nixos/module.nix;
    in
    {
      # NixOS module export
      nixosModules.default = nixosModule;
      nixosModules.bo3-server = nixosModule;
    } // flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Common dependencies
        serverDeps = with pkgs; [
          steamcmd
          wineWowPackages.stable
          winetricks
          curl
          wget
          unzip
          coreutils
          gnugrep
          gnutar
          gzip
        ];

        # Installation script
        bo3-install = pkgs.writeShellScriptBin "bo3-install" ''
          set -euo pipefail

          export PATH="${pkgs.lib.makeBinPath serverDeps}:$PATH"

          # Default installation directory
          INSTALL_DIR="''${BO3_INSTALL_DIR:-$HOME/bo3-server}"
          STEAM_USER="''${STEAM_USER:-}"

          echo "=== Black Ops 3 Dedicated Server Installer (NixOS) ==="
          echo ""
          echo "Installation directory: $INSTALL_DIR"
          echo ""

          # Prompt for Steam username if not set
          if [ -z "$STEAM_USER" ]; then
            echo -n "Enter your Steam username: "
            read -r STEAM_USER
          fi

          if [ -z "$STEAM_USER" ]; then
            echo "Error: Steam username is required"
            exit 1
          fi

          # Create installation directory
          mkdir -p "$INSTALL_DIR"
          cd "$INSTALL_DIR"

          echo ""
          echo "=== Downloading Black Ops 3 Unranked Server via SteamCMD ==="
          echo "You will be prompted for your Steam password and possibly Steam Guard code."
          echo ""

          # Run SteamCMD with steam-run for FHS compatibility
          ${pkgs.steam-run}/bin/steam-run ${pkgs.steamcmd}/bin/steamcmd \
            +@sSteamCmdForcePlatformType windows \
            +force_install_dir "$INSTALL_DIR" \
            +login "$STEAM_USER" \
            +app_update 545990 validate \
            +quit

          echo ""
          echo "=== Downloading T7X Client ==="
          curl -L -o t7x.exe "https://master.bo3.eu/t7x_v2/t7x.exe" || {
            echo "Warning: Failed to download T7X client"
          }

          echo ""
          echo "=== Downloading EZZBOIII Client ==="
          curl -L -o boiii.exe "https://github.com/Starter69/boiii/releases/download/v1.0/boiii.exe" || {
            # Fallback URL
            curl -L -o boiii.exe "https://github.com/Ezz-lol/boiii-free/releases/latest/download/boiii.exe" || {
              echo "Warning: Failed to download EZZBOIII client"
            }
          }

          echo ""
          echo "=== Setting up Wine prefix ==="
          export WINEPREFIX="$INSTALL_DIR/.wine"
          ${pkgs.wineWowPackages.stable}/bin/wineboot --init

          echo ""
          echo "=== Extracting BOIII server files ==="
          if [ -f "${self}/boiii-server-files.zip" ]; then
            BOIII_APPDATA="$WINEPREFIX/drive_c/users/$USER/AppData/Local/boiii"
            mkdir -p "$BOIII_APPDATA"
            unzip -o "${self}/boiii-server-files.zip" -d "$BOIII_APPDATA"
          fi

          echo ""
          echo "=== Copying server configuration files ==="
          if [ -d "${self}/UnrankedServer" ]; then
            cp -r "${self}/UnrankedServer/"* "$INSTALL_DIR/" 2>/dev/null || true
          fi

          echo ""
          echo "=== Installation Complete ==="
          echo ""
          echo "Server installed to: $INSTALL_DIR"
          echo "Wine prefix: $WINEPREFIX"
          echo ""
          echo "Next steps:"
          echo "  1. Edit server configuration: $INSTALL_DIR/zone/server.cfg"
          echo "  2. Start the server: bo3-server --dir $INSTALL_DIR"
          echo ""
        '';

        # Server launch script
        bo3-server = pkgs.writeShellScriptBin "bo3-server" ''
          set -euo pipefail

          export PATH="${pkgs.lib.makeBinPath serverDeps}:$PATH"

          # Parse arguments
          INSTALL_DIR="''${BO3_INSTALL_DIR:-$HOME/bo3-server}"
          CLIENT="boiii"
          CONFIG="server.cfg"
          PORT="27017"
          MOD_ID=""

          print_help() {
            echo "Usage: bo3-server [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dir PATH       Server installation directory (default: ~/bo3-server)"
            echo "  --client NAME    Client to use: boiii or t7x (default: boiii)"
            echo "  --config FILE    Server config file (default: server.cfg)"
            echo "  --port PORT      Game port (default: 27017)"
            echo "  --mod ID         Steam Workshop mod ID (optional)"
            echo "  --help           Show this help message"
            echo ""
            echo "Config presets:"
            echo "  --mp             Multiplayer (server.cfg)"
            echo "  --zm             Zombies (server_zm.cfg)"
            echo "  --cp             Campaign/Coop (server_cp.cfg)"
          }

          while [[ $# -gt 0 ]]; do
            case $1 in
              --dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
              --client)
                CLIENT="$2"
                shift 2
                ;;
              --config)
                CONFIG="$2"
                shift 2
                ;;
              --port)
                PORT="$2"
                shift 2
                ;;
              --mod)
                MOD_ID="$2"
                shift 2
                ;;
              --mp)
                CONFIG="server.cfg"
                shift
                ;;
              --zm)
                CONFIG="server_zm.cfg"
                shift
                ;;
              --cp)
                CONFIG="server_cp.cfg"
                shift
                ;;
              --help)
                print_help
                exit 0
                ;;
              *)
                echo "Unknown option: $1"
                print_help
                exit 1
                ;;
            esac
          done

          # Validate installation directory
          if [ ! -d "$INSTALL_DIR" ]; then
            echo "Error: Installation directory not found: $INSTALL_DIR"
            echo "Run 'bo3-install' first to set up the server."
            exit 1
          fi

          cd "$INSTALL_DIR"

          # Determine executable
          case "$CLIENT" in
            boiii)
              EXE="boiii.exe"
              ;;
            t7x)
              EXE="t7x.exe"
              ;;
            official)
              EXE="BlackOps3_UnrankedDedicatedServer.exe"
              ;;
            *)
              echo "Error: Unknown client: $CLIENT"
              exit 1
              ;;
          esac

          if [ ! -f "$EXE" ]; then
            echo "Error: Client executable not found: $EXE"
            exit 1
          fi

          # Set up Wine prefix
          export WINEPREFIX="$INSTALL_DIR/.wine"

          # Build command arguments
          ARGS="-headless"
          ARGS="$ARGS +set net_port $PORT"
          ARGS="$ARGS +set logfile 2"

          if [ -n "$MOD_ID" ]; then
            ARGS="$ARGS +set fs_game \"mods/$MOD_ID\""
          fi

          ARGS="$ARGS +exec $CONFIG"

          echo "=== Starting Black Ops 3 Server ==="
          echo "Client: $CLIENT ($EXE)"
          echo "Config: $CONFIG"
          echo "Port: $PORT"
          echo "Directory: $INSTALL_DIR"
          [ -n "$MOD_ID" ] && echo "Mod: $MOD_ID"
          echo ""

          # Run with steam-run for FHS compatibility
          exec ${pkgs.steam-run}/bin/steam-run \
            ${pkgs.wineWowPackages.stable}/bin/wine \
            "$EXE" $ARGS
        '';

      in
      {
        # Development shell for manual work
        devShells.default = pkgs.mkShell {
          buildInputs = serverDeps ++ [ pkgs.steam-run ];

          shellHook = ''
            export WINEPREFIX="''${BO3_INSTALL_DIR:-$HOME/bo3-server}/.wine"
            echo "Black Ops 3 Server Development Shell"
            echo ""
            echo "Available commands:"
            echo "  steamcmd    - Steam command-line client"
            echo "  wine        - Wine for running Windows executables"
            echo ""
            echo "Environment:"
            echo "  WINEPREFIX=$WINEPREFIX"
            echo ""
          '';
        };

        # Packages
        packages = {
          default = bo3-server;
          bo3-server = bo3-server;
          bo3-install = bo3-install;
        };

        # Apps for `nix run`
        apps = {
          default = {
            type = "app";
            program = "${bo3-server}/bin/bo3-server";
          };
          install = {
            type = "app";
            program = "${bo3-install}/bin/bo3-install";
          };
          server = {
            type = "app";
            program = "${bo3-server}/bin/bo3-server";
          };
        };
      });
}
