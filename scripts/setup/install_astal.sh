#!/bin/bash

# Astal (Aylur's GTK Shell) Installation Script
# This script handles the installation and basic configuration of Astal

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

# Configuration
ASTAL_PKG="aylurs-gtk-shell"
LOG_FILE="/tmp/astal-install-$(date +%Y%m%d_%H%M%S).log"

# Logging functions
print_status()    { echo -e "${BLUE}[*]${NC} $1"; }
print_success()   { echo -e "${GREEN}[✓]${NC} $1"; }
print_error()     { echo -e "${RED}[✗]${NC} $1"; exit 1; }
print_warning()   { echo -e "${YELLOW}[!]${NC} $1"; }

log() {
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[$timestamp] $1${NC}"
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
    fi
}

# Check system requirements and compatibility
check_requirements() {
    log "Checking system requirements for Astal..."
    
    # 1. Check for required commands
    local required_commands=("yay" "git")
    local recommended_commands=("node" "sassc" "typescript" "esbuild")
    
    # Check required commands
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            print_error "Required command '$cmd' is not installed."
        fi
    done
    
    # Check recommended commands
    local missing_commands=()
    for cmd in "${recommended_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        print_warning "Recommended build tools missing: ${missing_commands[*]}"
        if ! confirm "Continue without recommended tools?" "y"; then
            print_error "Installation aborted. Please install missing tools first."
        fi
    fi
    
    # 2. Check for Wayland session
    if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_SESSION_TYPE" != "wayland" ]; then
        print_warning "Astal works best on Wayland. You're currently not in a Wayland session."
        if ! confirm "Continue with installation anyway?" "n"; then
            print_error "Installation aborted. Please switch to a Wayland session."
        fi
    fi
    
    # 3. Check for required libraries
    local required_libs=("gtk4" "libadwaita-1" "gjs")
    local missing_libs=()
    
    for lib in "${required_libs[@]}"; do
        if ! pkg-config --exists "$lib" 2>/dev/null; then
            missing_libs+=("$lib")
        fi
    done
    
    if [ ${#missing_libs[@]} -gt 0 ]; then
        print_warning "Missing required libraries: ${missing_libs[*]}"
        if confirm "Install missing libraries now?" "y"; then
            log "Installing required libraries..."
            if ! yay -S --needed --noconfirm "${missing_libs[@]}"; then
                print_error "Failed to install required libraries"
            fi
        else
            print_error "Installation aborted. Required libraries are missing."
        fi
    fi
    
    print_success "System requirements check completed"

# Install Astal package
install_astal() {
    log "Installing $ASTAL_PKG from AUR..."
    if yay -S --needed --noconfirm "$ASTAL_PKG"; then
        print_success "Successfully installed $ASTAL_PKG"
    else
        print_error "Failed to install $ASTAL_PKG"
    fi
}

# Create basic configuration
setup_config() {
    local config_dir="$HOME/.config/ags"
    
    log "Setting up Astal configuration..."
    
    # Create config directory if it doesn't exist
    mkdir -p "$config_dir"
    
    # Create basic config file if it doesn't exist
    if [[ ! -f "$config_dir/config.js" ]]; then
        log "Creating default configuration..."
        cat > "$config_dir/config.js" << 'EOL'
// Astal Configuration
// This is a basic configuration file for Astal

// Import required modules
const { exec } = require('resource:///com/github/Aylur/ags/utils.js');

// Configuration object
const Config = {
    // General settings
    style: 'default',
    theme: 'default',
    
    // Bar configuration
    bar: {
        position: 'top',  // top or bottom
        height: 42,
        // ... add more bar settings as needed
    },
    
    // Modules to load
    modules: [
        'bar',
        'dashboard',
        'notifications',
        // Add more modules as needed
    ],
    
    // Keybindings
    keybinds: {
        // Example keybindings
        'super+space': 'show-applications',
        'super+return': 'open-terminal',
    },
    
    // Initialize function
    init: () => {
        // Initialization code here
        log('Astal configuration loaded');
    }
};

// Export the configuration
module.exports = Config;
EOL
        print_success "Created default configuration at $config_dir/config.js"
    else
        print_warning "Configuration file already exists at $config_dir/config.js"
    fi
}

# Main function
main() {
    log "Starting Astal installation..."
    
    # Check prerequisites
    check_root
    
    # Check system requirements and install dependencies
    check_requirements
    
    # Install Astal
    install_astal
    
    # Setup configuration
    setup_config
    
    # Print completion message
    echo -e "\n${GREEN}Astal (Aylur's GTK Shell) installation completed successfully!${NC}"
    echo -e "\n${YELLOW}Next steps:${NC}"
    echo "1. Log out and log back in to ensure all components are properly loaded"
    echo "2. Configure Astal by editing ~/.config/ags/config.js"
    echo "3. Add 'ags &' to your Hyprland autostart to launch Astal on login"
    echo -e "\n${YELLOW}Log file: $LOG_FILE${NC}"
}

# Run main function
main "$@"
