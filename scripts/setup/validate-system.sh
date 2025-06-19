#!/bin/bash

# System Validation Script
# Tests the installation environment without making changes

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly PACKAGES_DIR="${DOTFILES_DIR}/scripts/setup/packages"

print_header() {
    echo
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC} ${BOLD}System Validation Report${NC} ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

section() {
    echo
    echo -e "${BOLD}${BLUE}==> ${1}${NC}"
}

# System checks
check_system() {
    section "System Environment"
    
    # OS check
    if [[ -f /etc/arch-release ]]; then
        success "Running on Arch Linux"
    else
        error "Not running on Arch Linux"
        return 1
    fi
    
    # User check
    if [[ $EUID -eq 0 ]]; then
        error "Running as root (should be regular user)"
        return 1
    else
        success "Running as regular user"
    fi
    
    # Internet check
    if ping -c 1 archlinux.org &>/dev/null; then
        success "Internet connection available"
    else
        error "No internet connection"
        return 1
    fi
    
    # Sudo check
    if sudo -n true 2>/dev/null; then
        success "Passwordless sudo configured"
    elif sudo -v &>/dev/null; then
        warning "Sudo available but requires password"
    else
        error "No sudo access"
        return 1
    fi
    
    return 0
}

# Package manager checks
check_package_managers() {
    section "Package Managers"
    
    # Pacman
    if command -v pacman &>/dev/null; then
        success "pacman available"
        info "pacman version: $(pacman --version | head -1)"
    else
        error "pacman not found"
        return 1
    fi
    
    # yay
    if command -v yay &>/dev/null; then
        success "yay already installed"
        info "yay version: $(yay --version | head -1)"
    else
        warning "yay not installed (will be installed automatically)"
    fi
    
    # Git (needed for AUR)
    if command -v git &>/dev/null; then
        success "git available"
    else
        error "git not found (required for AUR packages)"
        return 1
    fi
    
    return 0
}

# Directory structure validation
check_directories() {
    section "Directory Structure"
    
    # Dotfiles directory
    if [[ -d "$DOTFILES_DIR" ]]; then
        success "Dotfiles directory exists: $DOTFILES_DIR"
    else
        error "Dotfiles directory not found: $DOTFILES_DIR"
        return 1
    fi
    
    # Packages directory
    if [[ -d "$PACKAGES_DIR" ]]; then
        success "Packages directory exists"
    else
        error "Packages directory not found: $PACKAGES_DIR"
        return 1
    fi
    
    # Package files
    local package_files=(
        "essential.txt"
        "development.txt"
        "theming.txt"
        "multimedia.txt"
        "gaming.txt"
        "optional.txt"
    )
    
    for file in "${package_files[@]}"; do
        if [[ -f "$PACKAGES_DIR/$file" ]]; then
            local count
            count=$(grep -v '^#' "$PACKAGES_DIR/$file" | grep -v '^$' | wc -l)
            success "$file ($count packages)"
        else
            error "$file not found"
        fi
    done
    
    return 0
}

# Configuration directories validation
check_configs() {
    section "Configuration Directories"
    
    local config_dirs=(
        "hypr"
        "waybar" 
        "kitty"
        "fish"
        "dunst"
        "fuzzel"
        "matugen"
    )
    
    for dir in "${config_dirs[@]}"; do
        local config_path="$DOTFILES_DIR/$dir"
        if [[ -d "$config_path" ]]; then
            success "$dir configuration exists"
        else
            warning "$dir configuration not found"
        fi
    done
    
    return 0
}

# System resources check
check_resources() {
    section "System Resources"
    
    # Disk space
    local available_space
    available_space=$(df "$HOME" | awk 'NR==2 {print $4}')
    local available_gb=$((available_space / 1024 / 1024))
    
    if [[ $available_gb -gt 10 ]]; then
        success "Sufficient disk space: ${available_gb}GB available"
    elif [[ $available_gb -gt 5 ]]; then
        warning "Limited disk space: ${available_gb}GB available"
    else
        error "Insufficient disk space: ${available_gb}GB available (need >5GB)"
    fi
    
    # Memory
    local total_mem
    total_mem=$(free -g | awk 'NR==2{print $2}')
    
    if [[ $total_mem -gt 4 ]]; then
        success "Sufficient memory: ${total_mem}GB"
    elif [[ $total_mem -gt 2 ]]; then
        warning "Limited memory: ${total_mem}GB"
    else
        error "Insufficient memory: ${total_mem}GB (recommended >2GB)"
    fi
    
    # CPU cores
    local cpu_cores
    cpu_cores=$(nproc)
    success "CPU cores: $cpu_cores"
    
    return 0
}

# Hardware detection
check_hardware() {
    section "Hardware Detection"
    
    # GPU detection
    if lspci | grep -i nvidia &>/dev/null; then
        success "NVIDIA GPU detected"
        info "$(lspci | grep -i nvidia | head -1)"
    fi
    
    if lspci | grep -i amd &>/dev/null; then
        success "AMD GPU detected"
        info "$(lspci | grep -i amd | grep -i vga)"
    fi
    
    if lspci | grep -i intel.*graphics &>/dev/null; then
        success "Intel graphics detected"
        info "$(lspci | grep -i intel.*graphics)"
    fi
    
    # Audio
    if lspci | grep -i audio &>/dev/null; then
        success "Audio hardware detected"
    else
        warning "No audio hardware detected"
    fi
    
    # Network
    if ip link show | grep -q "state UP"; then
        success "Network interface active"
    else
        warning "No active network interfaces"
    fi
    
    return 0
}

# Main validation function
main() {
    print_header
    
    local exit_code=0
    
    check_system || exit_code=1
    check_package_managers || exit_code=1
    check_directories || exit_code=1
    check_configs
    check_resources
    check_hardware
    
    echo
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}✓ System validation passed!${NC}"
        echo -e "${BLUE}Ready for dotfiles installation.${NC}"
    else
        echo -e "${RED}${BOLD}✗ System validation failed!${NC}"
        echo -e "${YELLOW}Please fix the errors above before proceeding.${NC}"
    fi
    
    echo
    echo -e "${BLUE}To run the installer: ${BOLD}./install.sh${NC}"
    
    exit $exit_code
}

# Run validation
main "$@" 