#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Print colored message
print_message() {
    echo -e "${BLUE}==>${NC} $1"
}

# Print error message
print_error() {
    echo -e "${RED}Error:${NC} $1"
}

# Print success message
print_success() {
    echo -e "${GREEN}Success:${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run as root"
    exit 1
fi

# Install yay if not present
if ! command -v yay &> /dev/null; then
    print_message "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
fi

# Install required packages
print_message "Installing required packages..."
yay -S --needed --noconfirm \
    hyprland \
    waybar \
    kitty \
    fish \
    wofi \
    dunst \
    polkit-kde-agent \
    xdg-desktop-portal-hyprland \
    qt5-wayland \
    qt6-wayland \
    pipewire \
    wireplumber \
    pavucontrol \
    pamixer \
    playerctl \
    brightnessctl \
    grim \
    slurp \
    wl-clipboard \
    catppuccin-gtk-theme-mocha \
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji

# Backup existing configs
print_message "Backing up existing configurations..."
config_dir="$HOME/.config"
backup_dir="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

if [ -d "$config_dir" ]; then
    mkdir -p "$backup_dir"
    for dir in hypr waybar kitty fish dunst wofi; do
        if [ -d "$config_dir/$dir" ]; then
            mv "$config_dir/$dir" "$backup_dir/"
        fi
    done
fi

# Create symlinks
print_message "Creating symlinks..."
dotfiles_dir="$(pwd)"

for dir in config/*; do
    if [ -d "$dir" ]; then
        target_dir="$HOME/.${dir}"
        mkdir -p "$(dirname "$target_dir")"
        ln -sf "$dotfiles_dir/$dir" "$target_dir"
    fi
done

# Set fish as default shell
if [ "$SHELL" != "$(which fish)" ]; then
    print_message "Setting fish as default shell..."
    chsh -s "$(which fish)"
fi

# Configure GTK theme
print_message "Configuring GTK theme..."
if [ ! -f "$HOME/.config/gtk-3.0/settings.ini" ]; then
    mkdir -p "$HOME/.config/gtk-3.0"
    cat > "$HOME/.config/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=Catppuccin-Mocha-Standard-Blue-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
EOF
fi

# Create necessary directories
mkdir -p "$HOME/Pictures/Screenshots"

print_success "Installation completed! Please log out and log back in to start Hyprland."
print_message "Note: Some changes might require a system restart to take effect." 