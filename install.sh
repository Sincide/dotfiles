#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Print colored message
print_message() {
    echo -e "${BLUE}==>${NC} $1"
}

# Print error message
print_error() {
    echo -e "${RED}Error:${NC} $1"
}

# Print warning message
print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

# Print success message
print_success() {
    echo -e "${GREEN}Success:${NC} $1"
}

# Error handler
handle_error() {
    print_error "$1"
    exit 1
}

# Check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        handle_error "Required command '$1' not found. Please install it first."
    fi
}

# Verify symlink creation
verify_symlink() {
    local source="$1"
    local target="$2"
    if [ ! -L "$target" ]; then
        print_error "Failed to create symlink from $source to $target"
        return 1
    fi
    if [ ! "$(readlink "$target")" = "$source" ]; then
        print_error "Symlink $target points to wrong location"
        return 1
    fi
    return 0
}

# Check for Wayland session
check_wayland_session() {
    if [ "$XDG_SESSION_TYPE" != "wayland" ]; then
        print_warning "Not running in a Wayland session. Some features may not work until you log into Wayland."
    fi
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
    handle_error "Please do not run as root"
fi

# Check for required base commands
check_command "git"
check_command "make"
check_command "gcc"

# Detect environment
ENV_TYPE=$(detect_environment)
print_message "Detected environment: $ENV_TYPE"

# Check for Wayland session
check_wayland_session

# Install yay if not present
if ! command -v yay &> /dev/null; then
    print_message "Installing yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay || handle_error "Failed to clone yay repository"
    (cd /tmp/yay && makepkg -si --noconfirm) || handle_error "Failed to install yay"
    rm -rf /tmp/yay
fi

# Install required packages
print_message "Installing required packages..."
COMMON_PACKAGES="hyprland hyprpaper waybar kitty fish wofi dunst polkit-gnome xdg-desktop-portal-hyprland xdg-desktop-portal-gtk qt5-wayland qt6-wayland pipewire wireplumber pavucontrol pamixer playerctl grim slurp wl-clipboard swappy catppuccin-gtk-theme-mocha ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji papirus-icon-theme thunar thunar-volman thunar-archive-plugin xdg-utils xdg-user-dirs network-manager-applet blueman jq swaylock-effects vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau"

# Split installation to handle errors better
echo "$COMMON_PACKAGES" | tr ' ' '\n' | while read -r package; do
    if ! yay -Q "$package" &>/dev/null; then
        print_message "Installing $package..."
        yay -S --needed --noconfirm "$package" || handle_error "Failed to install $package"
    fi
done

if [ "$ENV_TYPE" = "physical" ]; then
    print_message "Installing physical machine specific packages..."
    yay -S --needed --noconfirm brightnessctl || handle_error "Failed to install brightnessctl"
fi

# Backup existing configs
print_message "Backing up existing configurations..."
config_dir="$HOME/.config"
backup_dir="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

if [ -d "$config_dir" ]; then
    mkdir -p "$backup_dir"
    for dir in hypr waybar kitty fish dunst wofi; do
        if [ -d "$config_dir/$dir" ]; then
            cp -r "$config_dir/$dir" "$backup_dir/" || print_warning "Failed to backup $dir"
        fi
    done
fi

# Rotate old backups (keep last 5)
find "$HOME" -maxdepth 1 -name ".config-backup-*" -type d -printf '%T@ %p\n' | \
    sort -n | head -n -5 | cut -d' ' -f2- | xargs -r rm -rf

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
                        target="$HOME/.local/share/applications/$(basename "$file")"
                        ln -sf "$dotfiles_dir/$file" "$target"
                        verify_symlink "$dotfiles_dir/$file" "$target" || print_warning "Failed to verify symlink for $(basename "$file")"
                    fi
                done
                ;;
            *)
                # Handle .config directories
                target_dir="$HOME/.config/$base_name"
                mkdir -p "$(dirname "$target_dir")"
                ln -sf "$dotfiles_dir/$dir" "$target_dir"
                verify_symlink "$dotfiles_dir/$dir" "$target_dir" || print_warning "Failed to verify symlink for $base_name"
                ;;
        esac
    fi
done

# Create necessary directories
mkdir -p "$HOME/Pictures/Screenshots" || handle_error "Failed to create Screenshots directory"

# Configure environment-specific settings
print_message "Configuring environment-specific settings..."
if [ "$ENV_TYPE" = "vm" ]; then
    # Link VM-specific monitor config
    ln -sf "$dotfiles_dir/config/hypr/monitors-vm.conf" "$HOME/.config/hypr/monitors.conf"
    verify_symlink "$dotfiles_dir/config/hypr/monitors-vm.conf" "$HOME/.config/hypr/monitors.conf" || \
        handle_error "Failed to configure VM monitor settings"
else
    # Link physical machine monitor config
    ln -sf "$dotfiles_dir/config/hypr/monitors-physical.conf" "$HOME/.config/hypr/monitors.conf"
    verify_symlink "$dotfiles_dir/config/hypr/monitors-physical.conf" "$HOME/.config/hypr/monitors.conf" || \
        handle_error "Failed to configure physical monitor settings"
fi

# Ensure proper permissions for scripts
print_message "Setting script permissions..."
find "$HOME/.config/hypr/scripts/" -type f -name "*.sh" -exec chmod +x {} \; || print_warning "Failed to set permissions for Hyprland scripts"
find "$HOME/.config/waybar/scripts/" -type f -name "*.sh" -exec chmod +x {} \; || print_warning "Failed to set permissions for Waybar scripts"

# Configure default applications
print_message "Configuring default applications..."
xdg-mime default kitty.desktop x-scheme-handler/terminal
xdg-mime default kitty.desktop application/x-terminal-emulator

# Update XDG user directories
print_message "Updating XDG user directories..."
xdg-user-dirs-update || print_warning "Failed to update XDG user directories"

# Set fish as default shell
if [ "$SHELL" != "$(which fish)" ]; then
    print_message "Setting fish as default shell..."
    chsh -s "$(which fish)" || print_warning "Failed to set fish as default shell"
fi

print_success "Installation completed! Please log out and log back in to start Hyprland."
print_message "Note: Some changes might require a system restart to take effect."

# Final verification
print_message "Performing final verification..."
missing_deps=0
for cmd in hyprland waybar kitty fish wofi dunst jq wl-clipboard swaylock; do
    if ! command -v "$cmd" &> /dev/null; then
        print_error "Required command '$cmd' not found after installation!"
        missing_deps=1
    fi
done

if [ $missing_deps -eq 1 ]; then
    print_warning "Some dependencies are missing. Please check the error messages above."
else
    print_success "All core dependencies are installed correctly."
fi 