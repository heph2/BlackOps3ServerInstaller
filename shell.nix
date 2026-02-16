# shell.nix - Traditional Nix shell for users who don't use flakes
# Usage: nix-shell
#        nix-shell --run "./nixos/install.sh"

{ pkgs ? import <nixpkgs> { config.allowUnfree = true; } }:

pkgs.mkShell {
  name = "bo3-server-shell";

  buildInputs = with pkgs; [
    # Core dependencies
    steamcmd
    steam-run

    # Wine for running Windows executables
    wineWowPackages.stable
    winetricks

    # Download utilities
    curl
    wget

    # Archive handling
    unzip
    gnutar
    gzip

    # Standard utilities
    coreutils
    gnugrep
  ];

  shellHook = ''
    export WINEPREFIX="''${BO3_INSTALL_DIR:-$HOME/bo3-server}/.wine"

    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║        Black Ops 3 Server - NixOS Development Shell          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Available commands:"
    echo "  ./nixos/install.sh    Install the server"
    echo "  ./nixos/launch.sh     Launch the server"
    echo ""
    echo "Quick start:"
    echo "  ./nixos/install.sh              # Download and set up server"
    echo "  ./nixos/launch.sh --mp          # Start multiplayer server"
    echo "  ./nixos/launch.sh --zm          # Start zombies server"
    echo "  ./nixos/launch.sh --help        # Show all options"
    echo ""
    echo "Environment:"
    echo "  WINEPREFIX=$WINEPREFIX"
    echo ""
  '';
}
