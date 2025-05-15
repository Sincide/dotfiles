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

# Detect if running in a VM
detect_environment() {
    if systemd-detect-virt --vm > /dev/null 2>&1; then
        echo "vm"
    elif systemd-detect-virt --container > /dev/null 2>&1; then
        echo "container"
    else
        echo "physical"
    fi
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run as root"
    exit 1
fi

# Detect environment
ENV_TYPE=$(detect_environment)
print_message "Detected environment: $ENV_TYPE"

# Install yay if not present
if ! command -v yay &> /dev/null; then
    print_message "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
fi

# Install required packages
print_message "Installing required packages..."
COMMON_PACKAGES="hyprland hyprpaper waybar kitty fish wofi dunst polkit-kde-agent xdg-desktop-portal-hyprland qt5-wayland qt6-wayland pipewire wireplumber pavucontrol pamixer playerctl grim slurp wl-clipboard swappy catppuccin-gtk-theme-mocha ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji papirus-icon-theme thunar thunar-volman thunar-archive-plugin xdg-utils xdg-user-dirs network-manager-applet blueman"

if [ "$ENV_TYPE" = "vm" ]; then
    # VM-specific packages (minimal set, no brightness control, etc.)
    yay -S --needed --noconfirm $COMMON_PACKAGES
else
    # Physical machine packages (full set with all utilities)
    yay -S --needed --noconfirm $COMMON_PACKAGES brightnessctl
fi

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

# Symlink config files
for dir in config/*; do
    if [ -d "$dir" ]; then
        base_name=$(basename "$dir")
        case "$base_name" in
            "applications")
                # Handle .local/share/applications directory
                mkdir -p "$HOME/.local/share/applications"
                for file in "$dir"/*; do
                    if [ -f "$file" ]; then
                        ln -sf "$dotfiles_dir/$file" "$HOME/.local/share/applications/$(basename "$file")"
                    fi
                done
                ;;
            *)
                # Handle .config directories
                target_dir="$HOME/.config/$base_name"
                mkdir -p "$(dirname "$target_dir")"
                ln -sf "$dotfiles_dir/$dir" "$target_dir"
                ;;
        esac
    fi
done

# Create necessary directories
mkdir -p "$HOME/Pictures/Screenshots"

# Configure environment-specific settings
print_message "Configuring environment-specific settings..."
if [ "$ENV_TYPE" = "vm" ]; then
    # Link VM-specific monitor config
    ln -sf "$dotfiles_dir/config/hypr/monitors-vm.conf" "$HOME/.config/hypr/monitors.conf"
    
    # Update hyprpaper config for VM
    cat > "$HOME/.config/hypr/hyprpaper.conf" << EOF
preload = $HOME/dotfiles/assets/wallpapers/evilpuccin.png
wallpaper = Virtual-1,$HOME/dotfiles/assets/wallpapers/evilpuccin.png
splash = false
EOF
else
    # Link physical machine monitor config
    ln -sf "$dotfiles_dir/config/hypr/monitors-physical.conf" "$HOME/.config/hypr/monitors.conf"
    
    # Update hyprpaper config for physical setup
    cat > "$HOME/.config/hypr/hyprpaper.conf" << EOF
preload = $HOME/dotfiles/assets/wallpapers/evilpuccin.png
wallpaper = DP-3,$HOME/dotfiles/assets/wallpapers/evilpuccin.png
wallpaper = DP-1,$HOME/dotfiles/assets/wallpapers/evilpuccin.png
wallpaper = HDMI-A-1,$HOME/dotfiles/assets/wallpapers/evilpuccin.png
splash = false
EOF
fi

# Ensure proper permissions for scripts
print_message "Setting script permissions..."
chmod +x "$HOME/.config/hypr/scripts/"*.sh
chmod +x "$HOME/.config/waybar/scripts/"*.sh

# Set up terminal emulator configuration
print_message "Setting up terminal emulator configuration..."
mkdir -p "$HOME/.local/share/applications"
ln -sf "$dotfiles_dir/config/xfce4/terminal/kitty.desktop" "$HOME/.local/share/applications/kitty.desktop"

# Configure Thunar custom actions
print_message "Configuring Thunar custom actions..."
mkdir -p "$HOME/.config/Thunar"
ln -sf "$dotfiles_dir/config/xfce4/terminal/uca.xml" "$HOME/.config/Thunar/uca.xml"

# Configure default terminal emulator
print_message "Configuring default terminal emulator..."
xdg-mime default kitty.desktop x-scheme-handler/terminal
xdg-mime default kitty.desktop application/x-terminal-emulator

# Update XDG user directories
print_message "Updating XDG user directories..."
xdg-user-dirs-update

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

print_success "Installation completed! Please log out and log back in to start Hyprland."
print_message "Note: Some changes might require a system restart to take effect." 