#!/usr/bin/env bash
# Black Ops 3 Dedicated Server Installer for NixOS
# Usage: nix-shell --run ./nixos/install.sh
#    or: nix develop --command ./nixos/install.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Default installation directory
INSTALL_DIR="${BO3_INSTALL_DIR:-$HOME/bo3-server}"
STEAM_USER="${STEAM_USER:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     Black Ops 3 Dedicated Server Installer for NixOS         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if we're running in a Nix environment
if ! command -v steamcmd &> /dev/null; then
    log_error "steamcmd not found. Please run this script inside a Nix shell:"
    echo ""
    echo "  nix develop --command ./nixos/install.sh"
    echo "  # or"
    echo "  nix-shell --run ./nixos/install.sh"
    echo ""
    exit 1
fi

if ! command -v wine &> /dev/null; then
    log_error "wine not found. Please ensure you're in the correct Nix environment."
    exit 1
fi

# Prompt for installation directory
echo -n "Installation directory [$INSTALL_DIR]: "
read -r USER_DIR
INSTALL_DIR="${USER_DIR:-$INSTALL_DIR}"

log_info "Installing to: $INSTALL_DIR"

# Prompt for Steam username
if [ -z "$STEAM_USER" ]; then
    echo -n "Enter your Steam username: "
    read -r STEAM_USER
fi

if [ -z "$STEAM_USER" ]; then
    log_error "Steam username is required"
    exit 1
fi

# Create installation directory
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Set up Wine prefix
export WINEPREFIX="$INSTALL_DIR/.wine"
log_info "Wine prefix: $WINEPREFIX"

echo ""
log_info "Downloading Black Ops 3 Unranked Server via SteamCMD..."
log_warn "You will be prompted for your Steam password and possibly Steam Guard code."
echo ""

# Run SteamCMD with steam-run for FHS compatibility
if command -v steam-run &> /dev/null; then
    steam-run steamcmd \
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir "$INSTALL_DIR" \
        +login "$STEAM_USER" \
        +app_update 545990 validate \
        +quit
else
    steamcmd \
        +@sSteamCmdForcePlatformType windows \
        +force_install_dir "$INSTALL_DIR" \
        +login "$STEAM_USER" \
        +app_update 545990 validate \
        +quit
fi

echo ""
log_info "Downloading T7X Client..."
curl -L -o t7x.exe "https://master.bo3.eu/t7x_v2/t7x.exe" 2>/dev/null || {
    log_warn "Failed to download T7X client"
}

echo ""
log_info "Downloading EZZBOIII Client..."
curl -L -o boiii.exe "https://github.com/Ezz-lol/boiii-free/releases/latest/download/boiii.exe" 2>/dev/null || {
    log_warn "Failed to download EZZBOIII client (trying fallback)..."
    curl -L -o boiii.exe "https://github.com/Starter69/boiii/releases/download/v1.0/boiii.exe" 2>/dev/null || {
        log_warn "Failed to download EZZBOIII client from fallback"
    }
}

echo ""
log_info "Initializing Wine prefix..."
wineboot --init 2>/dev/null || true

echo ""
log_info "Setting up BOIII AppData directory..."
BOIII_APPDATA="$WINEPREFIX/drive_c/users/$USER/AppData/Local/boiii"
mkdir -p "$BOIII_APPDATA"

# Extract BOIII server files if available
if [ -f "$SCRIPT_DIR/boiii-server-files.zip" ]; then
    log_info "Extracting BOIII server files..."
    unzip -o "$SCRIPT_DIR/boiii-server-files.zip" -d "$BOIII_APPDATA" 2>/dev/null || true
fi

echo ""
log_info "Copying server configuration files..."
mkdir -p "$INSTALL_DIR/zone"
mkdir -p "$INSTALL_DIR/boiii"
mkdir -p "$INSTALL_DIR/t7x"

if [ -d "$SCRIPT_DIR/UnrankedServer" ]; then
    cp -r "$SCRIPT_DIR/UnrankedServer/"* "$INSTALL_DIR/" 2>/dev/null || true
    log_success "Configuration files copied"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                   Installation Complete!                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
log_success "Server installed to: $INSTALL_DIR"
log_success "Wine prefix: $WINEPREFIX"
echo ""
echo "Next steps:"
echo "  1. Edit server configuration:"
echo "     $INSTALL_DIR/zone/server.cfg     (Multiplayer)"
echo "     $INSTALL_DIR/zone/server_zm.cfg  (Zombies)"
echo "     $INSTALL_DIR/zone/server_cp.cfg  (Campaign/Coop)"
echo ""
echo "  2. Start the server:"
echo "     nix run .#server -- --dir $INSTALL_DIR --mp"
echo "     # or"
echo "     ./nixos/launch.sh --dir $INSTALL_DIR --client boiii --mp"
echo ""

# Create a helper script in the install directory
cat > "$INSTALL_DIR/start-server.sh" << 'STARTSCRIPT'
#!/usr/bin/env bash
# Quick start script - run from a Nix shell
cd "$(dirname "$0")"
export WINEPREFIX="$(pwd)/.wine"

CLIENT="${1:-boiii}"
CONFIG="${2:-server.cfg}"
PORT="${3:-27017}"

case "$CLIENT" in
    boiii) EXE="boiii.exe" ;;
    t7x) EXE="t7x.exe" ;;
    official) EXE="BlackOps3_UnrankedDedicatedServer.exe" ;;
    *) echo "Unknown client: $CLIENT"; exit 1 ;;
esac

echo "Starting $CLIENT server with $CONFIG on port $PORT..."
exec steam-run wine "$EXE" -headless +set net_port "$PORT" +set logfile 2 +exec "$CONFIG"
STARTSCRIPT

chmod +x "$INSTALL_DIR/start-server.sh"
log_success "Created quick-start script: $INSTALL_DIR/start-server.sh"
echo ""
