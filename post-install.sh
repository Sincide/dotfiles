#!/bin/bash

# Arch Linux Post-Install Script
# This script helps set up a fresh Arch Linux installation with Hyprland

set -e  # Exit on error

# Configuration
DOTFILES_DIR="$HOME/dotfiles"
LOG_FILE="/tmp/arch-post-install-$(date +%Y%m%d_%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# Ask for confirmation before proceeding
confirm() {
    local prompt="${1:-Continue?} [y/N] "
    local default_choice=${2:-n}
    
    if [ "$default_choice" = "y" ]; then
        prompt="${1:-Continue?} [Y/n] "
    fi
    
    read -rp "$prompt" response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        [nN][oO]|[nN])
            return 1
            ;;
        *)
            if [ "$default_choice" = "y" ]; then
                return 0
            else
                return 1
            fi
            ;;
    esac
}

# Print section header
section() {
    echo -e "\n${BLUE}==> ${1}${NC}"
}

# Print step
step() {
    echo -e "${GREEN}->${NC} ${1}"
}

# Initialize logging
init_logging() {
    log "Starting Arch Linux post-installation script"
    log "Log file: $LOG_FILE"
}

# Logging function
log() {
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    local message="[$timestamp] $1"
    
    # Print to console with color
    echo -e "${YELLOW}${message}${NC}"
    
    # Append to log file
    echo "$message" >> "$LOG_FILE"
}

# Error handling function
error() {
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    local message="[ERROR] $1"
    
    # Print to stderr with color
    echo -e "${RED}${message}${NC}" >&2
    echo "[$timestamp] $message" >> "$LOG_FILE"
    
    # Wait for user input before continuing
    read -p "Press Enter to continue or Ctrl+C to abort..."
    return 1
}

# Check if running as root and exit if true
check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Prompt for sudo password if not already available
check_sudo() {
    log "Checking for sudo access..."
    
    # Check if we already have passwordless sudo
    if sudo -n true 2>/dev/null; then
        log "Passwordless sudo already configured"
        return 0
    fi
    
    # Prompt for sudo password
    echo -e "${YELLOW}This operation requires sudo privileges.${NC}"
    if ! sudo -v; then
        error "Failed to obtain sudo privileges"
        return 1
    fi
    
    log "Sudo access granted"
}

# Run a command with sudo, prompting for password if needed
run_sudo() {
    if [ $# -eq 0 ]; then
        error "No command provided to run_sudo"
        return 1
    fi
    
    log "Running command with sudo: $*"
    
    # Try running the command with sudo
    if ! sudo -v; then
        error "Failed to obtain sudo privileges"
        return 1
    fi
    
    # Execute the command with sudo
    if ! sudo "$@"; then
        error "Command failed: $*"
        return 1
    fi
    
    return 0
}

# Install required build dependencies for AUR packages
install_build_deps() {
    log "Installing build dependencies..."
    
    local pkgs=(
        base-devel
        git
    )
    
    if ! run_sudo pacman -S --needed --noconfirm "${pkgs[@]}"; then
        error "Failed to install build dependencies"
        return 1
    fi
    
    log "Build dependencies installed successfully"
    return 0
}

# Install yay-bin from AUR
install_yay() {
    log "Starting yay-bin installation..."
    
    # Check if yay is already installed
    if command -v yay &> /dev/null; then
        log "yay is already installed"
        return 0
    fi
    
    # Install build dependencies
    if ! install_build_deps; then
        error "Failed to install build dependencies for yay"
        return 1
    fi
    
    local temp_dir
    temp_dir=$(mktemp -d)
    
    if [ -z "$temp_dir" ]; then
        error "Failed to create temporary directory"
        return 1
    fi
    
    log "Cloning yay-bin repository..."
    if ! git clone https://aur.archlinux.org/yay-bin.git "$temp_dir"; then
        error "Failed to clone yay-bin repository"
        rm -rf "$temp_dir"
        return 1
    fi
    
    log "Building and installing yay-bin..."
    cd "$temp_dir" || {
        error "Failed to enter temporary directory"
        rm -rf "$temp_dir"
        return 1
    }
    
    if ! makepkg -si --noconfirm; then
        error "Failed to build/install yay-bin"
        cd - >/dev/null || true
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Clean up
    cd - >/dev/null || true
    rm -rf "$temp_dir"
    
    # Verify installation
    if ! command -v yay &> /dev/null; then
        error "yay installation verification failed"
        return 1
    fi
    
    log "yay-bin installed successfully"
    return 0
}

# Enable systemd services
enable_services() {
    section "Service Configuration"
    
    if ! confirm "Enable SSH server (sshd)?" "y"; then
        log "Skipping SSH service configuration"
        return 0
    fi
    
    log "Enabling SSH service..."
    
    if ! run_sudo systemctl enable --now sshd 2>> "$LOG_FILE"; then
        error "Failed to enable SSH service"
        return 1
    fi
    
    log "System services enabled successfully"
    return 0
}

# Create dotfiles directory structure
setup_dotfiles_dir() {
    section "Dotfiles Setup"
    
    if ! confirm "Set up dotfiles directory structure?" "y"; then
        log "Skipping dotfiles setup"
        return 0
    fi
    
    log "Setting up dotfiles directory structure..."
    
    # Create main dotfiles directory
    if [ ! -d "$DOTFILES_DIR" ]; then
        log "Creating dotfiles directory at $DOTFILES_DIR"
        mkdir -p "$DOTFILES_DIR" || {
            error "Failed to create dotfiles directory"
            return 1
        }
    else
        log "Dotfiles directory already exists at $DOTFILES_DIR"
    fi
    
    # Create config subdirectories
    local config_dirs=(
        "hypr"
        "waybar"
        "kitty"
        "fish"
        "dunst"
        "nvim"
    )
    
    for dir in "${config_dirs[@]}"; do
        local full_path="$DOTFILES_DIR/$dir"
        if [ ! -d "$full_path" ]; then
            log "Creating directory: $full_path"
            mkdir -p "$full_path" || {
                error "Failed to create directory: $full_path"
                return 1
            }
        fi
    done
    
    log "Dotfiles directory structure created successfully"
    return 0
}

# Create minimal configuration files
create_config_files() {
    log "Creating minimal configuration files..."
    
    # Create Hyprland config
    local hypr_config="$DOTFILES_DIR/hypr/hyprland.conf"
    if [ ! -f "$hypr_config" ]; then
        log "Creating Hyprland config"
        cat > "$hypr_config" << 'EOL'
# This is a minimal Hyprland config
# See https://wiki.hyprland.org/Configuring/Configuration/ for more

# Monitor configuration
monitor=,preferred,auto,1

# Autostart
exec-once = waybar
exec-once = dunst

# Input configuration
input {
    kb_layout = us
    follow_mouse = 1
    sensitivity = 0
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    layout = dwindle
}

decoration {
    rounding = 10
    
    blur {
        enabled = true
        size = 3
        passes = 1
    }
}

# Window rules
windowrule = float,^(kitty)$

# Keybindings
$mainMod = SUPER

bind = $mainMod, Return, exec, kitty
bind = $mainMod, Q, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, V, togglefloating,
bind = $mainMod, F, fullscreen,
bind = $mainMod, D, exec, fuzzel
EOL
    fi
    
    # Create Kitty config
    local kitty_config="$DOTFILES_DIR/kitty/kitty.conf"
    if [ ! -f "$kitty_config" ]; then
        log "Creating Kitty config"
        cat > "$kitty_config" << 'EOL'
# Kitty Terminal Config
font_family JetBrainsMono Nerd Font
font_size 11.0

# Theme
background #1e1e2e
foreground #cdd6f4

# Cursor
cursor #f5e0dc
cursor_text_color #11111b

# Selection
selection_foreground #1e1e2e
selection_background #f5e0dc

# Tab bar
tab_bar_style powerline
EOL
    fi
    
    # Create Waybar config
    local waybar_config="$DOTFILES_DIR/waybar/config"
    if [ ! -f "$waybar_config" ]; then
        log "Creating Waybar config"
        cat > "$waybar_config" << 'EOL'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "spacing": 4,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["hyprland/window"],
    "modules-right": ["pulseaudio", "network", "battery", "clock"],
    "clock": {
        "format": "{:%H:%M}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },
    "network": {
        "format-wifi": "{essid} ({signalStrength}%) ",
        "format-ethernet": "{ifname} ",
        "format-disconnected": "Disconnected ⚠",
        "tooltip-format": "{ifname}: {ipaddr}"
    },
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""],
        "format-charging": "{capacity}% "
    },
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-bluetooth": "{volume}% {icon}",
        "format-muted": "🔇",
        "format-icons": {
            "headphone": "",
            "default": ["", "", ""]
        },
        "on-click": "pactl set-sink-mute @DEFAULT_SINK@ toggle"
    }
}
EOL
    fi
    
    log "Configuration files created successfully"
    return 0
}

# Create AMD GPU overclocking script
setup_amd_overclock() {
    section "AMD GPU Configuration"
    
    if ! confirm "Set up AMD GPU overclocking?" "n"; then
        log "Skipping AMD GPU overclocking setup"
        return 0
    fi
    
    log "Setting up AMD GPU overclocking..."
    
    local script_path="$DOTFILES_DIR/scripts/amd-overclock.sh"
    local modprobe_dir="/etc/modprobe.d"
    local modprobe_conf="$modprobe_dir/amdgpu-overdrive.conf"
    
    # Create scripts directory if it doesn't exist
    mkdir -p "$(dirname "$script_path")" || {
        error "Failed to create scripts directory"
        return 1
    }
    
    # Create the overclocking script
    log "Creating AMD overclocking script at $script_path"
    cat > "$script_path" << 'EOL'
#!/bin/bash

# AMD GPU Overclocking Script
# This script enables AMD GPU overclocking and sets performance levels
# WARNING: Use at your own risk. Overclocking can potentially damage your hardware.

set -e

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Check for AMD GPU
if ! lspci | grep -i 'amd\|ati' | grep -i 'vga\|display\|3d' > /dev/null; then
    echo "No AMD GPU detected. Exiting." >&2
    exit 1
fi

# Enable AMD GPU overdrive
enable_overdrive() {
    echo "Enabling AMD GPU overdrive..."
    
    # Set the ppfeaturemask to enable overdrive
    local mask="0xffffffff"
    
    # Create modprobe directory if it doesn't exist
    mkdir -p "/etc/modprobe.d"
    
    # Add kernel parameter
    echo "options amdgpu ppfeaturemask=$mask" | tee "/etc/modprobe.d/amdgpu-overdrive.conf" > /dev/null
    
    # Update initramfs
    if command -v update-initramfs &> /dev/null; then
        update-initramfs -u -k all
    elif command -v mkinitcpio &> /dev/null; then
        mkinitcpio -P
    fi
    
    echo "AMD GPU overdrive enabled. Please reboot for changes to take effect."
}

# Set performance level
set_performance_level() {
    local card="/sys/class/drm/card0/device"
    
    if [ ! -d "$card" ]; then
        echo "GPU device not found. Is the AMD driver loaded?" >&2
        return 1
    fi
    
    echo "Setting performance level to high..."
    
    # Set power level to high
    echo "high" > "$card/power_dpm_force_performance_level" 2>/dev/null || {
        echo "Failed to set performance level. Make sure overdrive is enabled." >&2
        return 1
    }
    
    echo "Performance level set to high"
}

# Main function
main() {
    echo "=== AMD GPU Overclocking Tool ==="
    echo "1. Enable AMD GPU Overdrive (requires reboot)"
    echo "2. Set Performance Level to High"
    echo "3. Exit"
    
    read -p "Select an option (1-3): " choice
    
    case $choice in
        1)
            enable_overdrive
            ;;
        2)
            set_performance_level
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option" >&2
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
EOL
    
    # Make the script executable
    chmod +x "$script_path"
    
    # Create a symlink in a directory that's in PATH
    if [ -d "$HOME/.local/bin" ]; then
        ln -sf "$script_path" "$HOME/.local/bin/amd-overclock"
    else
        mkdir -p "$HOME/.local/bin"
        ln -sf "$script_path" "$HOME/.local/bin/amd-overclock"
        echo "Added $HOME/.local/bin to PATH in .bashrc and .zshrc"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    fi
    
    log "AMD GPU overclocking script installed at $script_path"
    log "You can run it with: amd-overclock"
    
    return 0
}

# Create symlinks for dotfiles
create_symlinks() {
    log "Creating symlinks for configuration files..."
    
    # Create ~/.config if it doesn't exist
    local config_dir="$HOME/.config"
    if [ ! -d "$config_dir" ]; then
        log "Creating $config_dir"
        mkdir -p "$config_dir" || {
            error "Failed to create $config_dir"
            return 1
        }
    fi
    
    # List of directories to symlink
    local dot_dirs=(
        "hypr"
        "waybar"
        "kitty"
        "fish"
        "dunst"
        "nvim"
    )
    
    # Create symlinks
    for dir in "${dot_dirs[@]}"; do
        local source_dir="$DOTFILES_DIR/$dir"
        local target_dir="$config_dir/$dir"
        
        # Skip if source doesn't exist
        if [ ! -d "$source_dir" ]; then
            log "Skipping $dir (not found in dotfiles)"
            continue
        fi
        
        # Remove existing symlink or directory
        if [ -L "$target_dir" ] || [ -e "$target_dir" ]; then
            log "Removing existing $target_dir"
            rm -rf "$target_dir" || {
                error "Failed to remove existing $target_dir"
                return 1
            }
        fi
        
        # Create symlink
        log "Creating symlink: $target_dir -> $source_dir"
        ln -s "$source_dir" "$target_dir" || {
            error "Failed to create symlink for $dir"
            return 1
        }
    done
    
    log "Symlinks created successfully"
    return 0
}

# Set default shell to fish
set_default_shell() {
    section "Shell Configuration"
    
    if ! confirm "Set fish as the default shell?" "y"; then
        log "Skipping shell configuration"
        return 0
    fi
    local fish_shell
    fish_shell=$(which fish)
    
    if [ -z "$fish_shell" ]; then
        error "Fish shell not found. Please install it first."
        return 1
    fi
    
    # Check if fish is already the default shell
    if [ "$SHELL" = "$fish_shell" ]; then
        log "Fish is already the default shell"
        return 0
    fi
    
    # Add fish to /etc/shells if not present
    if ! grep -q "^$fish_shell$" /etc/shells; then
        log "Adding fish to /etc/shells"
        echo "$fish_shell" | run_sudo tee -a /etc/shells > /dev/null || {
            error "Failed to add fish to /etc/shells"
            return 1
        }
    fi
    
    # Change the default shell
    log "Setting default shell to fish..."
    if ! run_sudo chsh -s "$fish_shell" "$USER"; then
        error "Failed to set fish as default shell"
        return 1
    fi
    
    log "Default shell set to fish successfully"
    echo -e "${YELLOW}Note: The new shell will be activated on next login${NC}"
    return 0
}

# Install system packages using yay
install_packages() {
    section "Package Installation"
    
    if ! confirm "Install system packages?" "y"; then
        log "Skipping package installation"
        return 0
    fi
    
    log "Starting package installation..."
    
    # Check if yay is available
    if ! command -v yay &> /dev/null; then
        error "yay is not installed. Cannot proceed with package installation."
        return 1
    fi
    
    # Update package databases
    log "Synchronizing package databases..."
    if ! yay -Syy; then
        error "Failed to synchronize package databases"
        return 1
    fi
    
    # Define package lists
    local packages=(
        # Window Manager & Desktop
        hyprland
        waybar
        fuzzel
        dunst
        
        # Terminal & Shell
        kitty
        fish
        
        # File Manager
        thunar
        thunar-archive-plugin
        thunar-volman
        gvfs
        
        # System Utilities
        btop
        fastfetch
        polkit-kde-agent
        
        # Fonts
        ttf-jetbrains-mono-nerd
        noto-fonts-emoji
        
        # Web Browser
        brave-bin
        
        # Text Editor
        nano-syntax-highlighting
        
        # Media
        pipewire
        pipewire-pulse
        wireplumber
        
        # Network
        network-manager-applet
        
        # Theme
        qt5ct
        qt6ct
        kvantum
    )
    
    log "Installing packages: ${packages[*]}"
    
    # Install all packages
    if ! yay -S --needed --noconfirm "${packages[@]}"; then
        error "Failed to install some packages"
        return 1
    fi
    
    log "All packages installed successfully"
    return 0
}

# Print summary of actions
print_summary() {
    section "Installation Summary"
    echo -e "The following actions will be performed:"
    echo -e "- Install system packages (yay, hyprland, kitty, etc.)"
    echo -e "- Enable system services (sshd, pipewire, bluetooth)"
    echo -e "- Set fish as the default shell"
    echo -e "- Set up dotfiles in $DOTFILES_DIR"
    echo -e "- Configure AMD GPU overclocking (optional)"
    echo -e "\nLog file: $LOG_FILE"
    echo -e "\nYou will be prompted before each major step."
}

# Main function
main() {
    echo -e "${GREEN}Arch Linux Post-Install Script${NC}"
    echo -e "This script will help set up a new Arch Linux installation\n"
    
    # Initialize logging
    init_logging
    log "Script started"
    
    # Check if running as root (shouldn't be)
    check_root
    log "Running as regular user: $(whoami)"
    
    # Print summary
    print_summary
    
    if ! confirm "Do you want to continue?" "n"; then
        log "Installation cancelled by user"
        echo -e "\n${YELLOW}Installation cancelled. No changes were made.${NC}"
        exit 0
    fi
    
    # Check for sudo access
    section "Privilege Check"
    if ! check_sudo; then
        error "Failed to obtain sudo privileges. Exiting."
        exit 1
    fi
    
    # Install yay if not already installed
    section "AUR Helper Setup"
    if ! install_yay; then
        error "Failed to install yay. Exiting."
        exit 1
    fi
    
    # Run installation steps
    install_packages
    enable_services
    set_default_shell
    setup_dotfiles_dir
    create_config_files
    create_symlinks
    setup_amd_overclock
    
    # Final message
    section "Installation Complete"
    log "Script completed successfully"
    echo -e "\n${GREEN}Installation completed successfully!${NC}"
    echo -e "\nNext steps:"
    echo -e "- Review the log file at: $LOG_FILE"
    echo -e "- Reboot your system to apply all changes"
    echo -e "- After reboot, run 'amd-overclock' to configure AMD GPU settings"
    echo -e "\nThank you for using the Arch Linux Post-Install Script!"
}

# Run main function
main "$@"
