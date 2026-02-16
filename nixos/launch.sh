#!/usr/bin/env bash
# Black Ops 3 Dedicated Server Launcher for NixOS
# Usage: nix-shell --run "./nixos/launch.sh [OPTIONS]"
#    or: nix develop --command ./nixos/launch.sh [OPTIONS]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Default values
INSTALL_DIR="${BO3_INSTALL_DIR:-$HOME/bo3-server}"
CLIENT="boiii"
CONFIG="server.cfg"
PORT="27017"
MOD_ID=""
VERBOSE=false

print_help() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║      Black Ops 3 Dedicated Server Launcher for NixOS         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --dir PATH       Server installation directory (default: ~/bo3-server)"
    echo "  --client NAME    Client to use: boiii, t7x, official (default: boiii)"
    echo "  --config FILE    Server config file (default: server.cfg)"
    echo "  --port PORT      Game port (default: 27017)"
    echo "  --mod ID         Steam Workshop mod ID (optional)"
    echo "  --verbose        Enable verbose output"
    echo "  --help           Show this help message"
    echo ""
    echo "Game Mode Presets:"
    echo "  --mp             Multiplayer (uses server.cfg)"
    echo "  --zm             Zombies (uses server_zm.cfg)"
    echo "  --cp             Campaign/Coop (uses server_cp.cfg)"
    echo ""
    echo "Examples:"
    echo "  $0 --mp                              # Start multiplayer server"
    echo "  $0 --zm --port 27018                 # Start zombies on port 27018"
    echo "  $0 --client t7x --mp                 # Use T7X client"
    echo "  $0 --dir /opt/bo3 --mp               # Custom install directory"
    echo ""
    echo "Environment Variables:"
    echo "  BO3_INSTALL_DIR  Default installation directory"
    echo "  WINEPREFIX       Wine prefix path (auto-detected)"
    echo ""
}

# Parse arguments
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
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            print_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            print_help
            exit 1
            ;;
    esac
done

# Check for required commands
check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 not found. Please run inside a Nix shell:"
        echo ""
        echo "  nix develop --command $0 $*"
        echo "  # or"
        echo "  nix-shell --run \"$0 $*\""
        echo ""
        exit 1
    fi
}

# Validate installation directory
if [ ! -d "$INSTALL_DIR" ]; then
    log_error "Installation directory not found: $INSTALL_DIR"
    echo ""
    echo "Please run the installer first:"
    echo "  nix run .#install"
    echo "  # or"
    echo "  nix develop --command ./nixos/install.sh"
    echo ""
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
        log_error "Unknown client: $CLIENT"
        log_info "Valid clients: boiii, t7x, official"
        exit 1
        ;;
esac

# Check if executable exists
if [ ! -f "$EXE" ]; then
    log_error "Client executable not found: $EXE"
    echo ""
    echo "Available executables:"
    ls -la *.exe 2>/dev/null || echo "  (none found)"
    echo ""
    echo "Please run the installer or download the client manually."
    exit 1
fi

# Check if config exists
if [ ! -f "zone/$CONFIG" ] && [ ! -f "$CONFIG" ]; then
    log_warn "Config file not found: $CONFIG"
    echo ""
    echo "Available configs in zone/:"
    ls -la zone/*.cfg 2>/dev/null || echo "  (none found)"
    echo ""
fi

# Set up Wine prefix
export WINEPREFIX="${WINEPREFIX:-$INSTALL_DIR/.wine}"

# Build command arguments
ARGS="-headless"
ARGS="$ARGS +set net_port $PORT"
ARGS="$ARGS +set logfile 2"

if [ -n "$MOD_ID" ]; then
    ARGS="$ARGS +set fs_game \"mods/$MOD_ID\""
fi

ARGS="$ARGS +exec $CONFIG"

# Print startup info
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           Starting Black Ops 3 Dedicated Server              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
log_info "Client:    $CLIENT ($EXE)"
log_info "Config:    $CONFIG"
log_info "Port:      $PORT"
log_info "Directory: $INSTALL_DIR"
log_info "Wine:      $WINEPREFIX"
[ -n "$MOD_ID" ] && log_info "Mod:       $MOD_ID"
echo ""

if $VERBOSE; then
    log_info "Command: wine $EXE $ARGS"
    echo ""
fi

log_success "Server starting... Press Ctrl+C to stop."
echo ""

# Run the server
if command -v steam-run &> /dev/null; then
    exec steam-run wine "$EXE" $ARGS
else
    exec wine "$EXE" $ARGS
fi
