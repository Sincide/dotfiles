#!/bin/bash

set -euo pipefail

LOGFILE="$HOME/install.log"

log() {
    echo -e "[*] $1" | tee -a "$LOGFILE"
}

ascii_art() {
cat << "EOF"

   ______ _     _     
  |  ____| |   (_)    
  | |__  | |__  _ ___ 
  |  __| | '_ \| / __|
  | |____| | | | \__ \
  |______|_| |_|_|___/
    🐟 SHELL SETUP MODULE

EOF
}

ascii_art

log "Checking if Fish is installed..."
if ! command -v fish >/dev/null; then
    log "Fish is not installed. Please run 01-packages.sh first."
    exit 1
fi

log "Setting Fish as default shell..."
chsh -s /usr/bin/fish

log "Creating config directories..."
mkdir -p ~/.config/fish

log "Writing minimal fish config..."
cat > ~/.config/fish/config.fish <<EOF
# Minimal fish config
set -gx EDITOR nano
set -gx BROWSER brave
set -gx TERMINAL kitty

# Source completions and custom functions
if status is-interactive
    fastfetch
end
EOF

log "✅ Fish shell setup complete."
