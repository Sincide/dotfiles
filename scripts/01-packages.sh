#!/bin/bash

set -euo pipefail

LOGFILE="$HOME/install.log"

log() {
    echo -e "[*] $1" | tee -a "$LOGFILE"
}

ascii_art() {
cat << "EOF"

  ____        _           _                
 |  _ \ _   _| |__   ___ | |__   ___  _ __ 
 | |_) | | | | '_ \ / _ \| '_ \ / _ \| '__|
 |  __/| |_| | |_) | (_) | |_) | (_) | |   
 |_|    \__,_|_.__/ \___/|_.__/ \___/|_|   
     📦 PACKAGE INSTALLATION MODULE

EOF
}

ascii_art
log "Updating system..."
sudo pacman -Syu --noconfirm

log "Installing essential packages..."
sudo pacman -S --noconfirm \
    base-devel \
    git \
    curl \
    kitty \
    thunar thunar-volman thunar-archive-plugin file-roller \
    btop fastfetch \
    nano \
    openssh \
    fish \
    wayland \
    wl-clipboard \
    unzip \
    polkit-gnome \
    swww

log "Cloning yay-bin AUR helper..."
cd /tmp
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si --noconfirm

log "Installing AUR packages with yay..."
yay -S --noconfirm \
    brave-bin \
    hyprland \
    waybar \
    fuzzel \
    dunst \
    ttf-jetbrains-mono-nerd

log "✅ Package installation complete."
