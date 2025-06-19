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

# Confirm action with user
confirm() {
    local prompt default response
    prompt="$1"
    default="${2:-y}"  # Default to 'y' if not provided
    
    # Set the prompt
    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n] "
    else
        prompt="$prompt [y/N] "
    fi
    
    # Read the response
    read -r -p "$prompt" response
    
    # Set default if empty
    [ -z "$response" ] && response="$default"
    
    # Convert to lowercase and check
    case "${response,,}" in
        y|yes) return 0 ;;
        *) return 1 ;;
    esac
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
    fi
}

# Check system requirements
check_requirements() {
    log "Checking system requirements for Astal..."
    
    # Check for required commands
    local required_commands=("yay" "git")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        print_error "Missing required commands: ${missing_commands[*]}"
        return 1
    fi
    
    # Check for Wayland session
    if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_SESSION_TYPE" != "wayland" ]; then
        print_warning "Astal works best on Wayland. You're currently not in a Wayland session."
        if ! confirm "Continue anyway?" "n"; then
            return 1
        fi
    fi
    
    # Check for recommended build tools
    local recommended_commands=("node" "sassc" "typescript" "esbuild" "bun")
    local missing_recommended=()
    
    for cmd in "${recommended_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_recommended+=("$cmd")
        fi
    done
    
    if [ ${#missing_recommended[@]} -gt 0 ]; then
        print_warning "Missing recommended tools: ${missing_recommended[*]}"
        if ! confirm "Install recommended tools?" "y"; then
            return 1
        fi
        
        log "Installing recommended tools..."
        if ! run_sudo pacman -S --needed --noconfirm "${missing_recommended[@]}"; then
            print_error "Failed to install recommended tools"
            return 1
        fi
    fi
    
    # Check for required AGS dependencies
    local ags_deps=(
        "gtk4" 
        "libadwaita" 
        "gjs" 
        "gobject-introspection"
        "typescript"
        "sassc"
        "nodejs"
        "bun"
    )
    
    local missing_deps=()
    
    for dep in "${ags_deps[@]}"; do
        if ! pacman -Qi "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_warning "Missing AGS dependencies: ${missing_deps[*]}"
        if ! confirm "Install missing AGS dependencies?" "y"; then
            return 1
        fi
        
        log "Installing AGS dependencies..."
        if ! run_sudo pacman -S --needed --noconfirm "${missing_deps[@]}"; then
            print_error "Failed to install AGS dependencies"
            return 1
        fi
    fi
    
    # Check for AGS AUR package
    if ! pacman -Qi aylurs-gtk-shell &> /dev/null; then
        print_warning "Aylur's GTK Shell (AGS) is not installed"
        if ! confirm "Install Aylur's GTK Shell (AGS)?" "y"; then
            return 1
        fi
        
        log "Installing Aylur's GTK Shell (AGS)..."
        if ! yay -S --needed --noconfirm aylurs-gtk-shell; then
            print_error "Failed to install Aylur's GTK Shell (AGS)"
            return 1
        fi
    fi
    
    return 0
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

# Main function
main() {
    log "Starting Astal installation..."
    
    # Check if running as root
    check_root
    
    # Check requirements
    if ! check_requirements; then
        print_error "System requirements check failed. See $LOG_FILE for details."
    fi
    
    # Install Astal
    if ! install_astal; then
        print_error "Failed to install Astal. See $LOG_FILE for details."
    fi
    
    print_success "Astal installation completed successfully!"
    echo -e "\n${BLUE}Next steps:${NC}"
    echo "1. Ensure your Astal configuration is set up in your dotfiles"
    echo "2. The configuration will be symlinked from your dotfiles to ~/.config/ags"
    echo "3. Log out and log back in to ensure all components are properly loaded"
    echo '4. Run "ags --run-js \"console.log(\'"'"'Hello from AGS!'"'"')\"" to test the configuration'
    echo -e "\n${YELLOW}Log file: $LOG_FILE${NC}"
}

# Run main function
main "$@"
