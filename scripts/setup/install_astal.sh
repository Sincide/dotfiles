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

# Check for required commands
check_commands() {
    local commands=("yay" "git")
    for cmd in "${commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            print_error "Required command '$cmd' is not installed."
        fi
    done
}

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
    check_commands
    
    # Install Astal
    install_astal
    
    # Setup configuration
    setup_config
    
    print_success "Astal installation completed successfully!"
    print_warning "Please restart your session to apply all changes."
    print_warning "Log file: $LOG_FILE"
}

# Run main function
main "$@"
