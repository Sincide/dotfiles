#!/bin/bash

set -euo pipefail

LOGFILE="$HOME/install.log"

log() {
    echo -e "[*] $1" | tee -a "$LOGFILE"
}

ascii_art() {
cat << "EOF"

      ____        _   _       _ _       
     |  _ \  ___ | |_| |_   _| | |_ ___ 
     | | | |/ _ \| __| | | | | | __/ _ \
     | |_| | (_) | |_| | |_| | | ||  __/
     |____/ \___/ \__|_|\__,_|_|\__\___|
        🗂 DOTFILES LINKING MODULE

EOF
}

ascii_art

DOTFILES="$HOME/dotfiles"
CONFIG="$HOME/.config"

log "Creating config directories..."
mkdir -p "$CONFIG/hypr"
mkdir -p "$CONFIG/waybar"
mkdir -p "$CONFIG/fish"
mkdir -p "$CONFIG/fuzzel"
mkdir -p "$CONFIG/dunst"
mkdir -p "$CONFIG/kitty"

log "Linking dotfiles..."

# -------- HOW TO ADD MORE CONFIGS --------
# 1. Place the config folder/file in ~/dotfiles (e.g. ~/dotfiles/foot/)
# 2. Then copy-paste one of the link_file lines below and update the name:
#       link_file "foot"
# -----------------------------------------

link_file() {
    local src="$DOTFILES/$1"
    local dest="$CONFIG/$1"

    if [[ -e "$dest" || -L "$dest" ]]; then
        log "Backup existing $dest to $dest.bak"
        mv "$dest" "$dest.bak"
    fi

    ln -sv "$src" "$dest" | tee -a "$LOGFILE"
}

# List of configs to symlink (you can add more below)
link_file "hypr"
link_file "waybar"
link_file "fish"
link_file "fuzzel"
link_file "dunst"
link_file "kitty"

log "✅ Dotfiles symlinking complete."
