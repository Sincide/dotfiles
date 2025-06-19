#!/bin/bash

# Comprehensive Dotfiles Installation System
# Author: Martin's Dotfiles
# Description: Interactive installer for complete Arch Linux + Hyprland dotfiles setup

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly PACKAGES_DIR="${DOTFILES_DIR}/scripts/setup/packages"
readonly LOG_FILE="${LOG_DIR}/installer_$(date +%Y%m%d_%H%M%S).log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Installation state
declare -A INSTALL_STATE=(
    [packages_essential]=false
    [packages_development]=false
    [packages_theming]=false
    [packages_multimedia]=false
    [packages_gaming]=false
    [packages_optional]=false
    [dotfiles_deployment]=false
    [user_setup]=false
    [system_optimization]=false
)

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    echo "Starting dotfiles installation - $(date)" >> "$LOG_FILE"
    log "Installer started from: $SCRIPT_DIR"
    log "Dotfiles directory: $DOTFILES_DIR"
    log "Packages directory: $PACKAGES_DIR"
}

# Logging functions
log() {
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
    echo -e "${CYAN}[LOG]${NC} $1"
}

success() {
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [SUCCESS] $1" >> "$LOG_FILE"
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [WARNING] $1" >> "$LOG_FILE"
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [ERROR] $1" >> "$LOG_FILE"
    echo -e "${RED}✗${NC} $1" >&2
}

# Print styled headers
print_header() {
    echo
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC} ${BOLD}$1${NC} ${BOLD}${BLUE}║${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_section() {
    echo
    echo -e "${BOLD}${PURPLE}==> ${1}${NC}"
}

# Interactive confirmation
confirm() {
    local prompt="${1:-Continue?}"
    local default="${2:-n}"
    
    while true; do
        if [[ "$default" == "y" ]]; then
            read -rp "${prompt} [Y/n]: " response
        else
            read -rp "${prompt} [y/N]: " response
        fi
        
        case "${response,,}" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            "") [[ "$default" == "y" ]] && return 0 || return 1 ;;
            *) echo -e "${RED}Please answer yes or no.${NC}" ;;
        esac
    done
}

# System checks
check_arch_linux() {
    if [[ ! -f /etc/arch-release ]]; then
        error "This installer is designed for Arch Linux only"
        exit 1
    fi
    success "Running on Arch Linux"
}

check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Do not run this script as root"
        exit 1
    fi
    success "Running as regular user"
}

check_internet() {
    if ! ping -c 1 archlinux.org &>/dev/null; then
        error "Internet connection required"
        exit 1
    fi
    success "Internet connection available"
}

check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        echo -e "${YELLOW}This installer requires sudo privileges${NC}"
        sudo -v || {
            error "Failed to obtain sudo privileges"
            exit 1
        }
    fi
    success "Sudo access available"
}

# AUR helper installation
install_yay() {
    if command -v yay &>/dev/null; then
        success "yay is already installed"
        return 0
    fi
    
    print_section "Installing yay AUR helper"
    
    # Install dependencies
    sudo pacman -S --needed --noconfirm base-devel git
    
    # Clone and build yay-bin
    local temp_dir
    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    
    cd "$DOTFILES_DIR"
    rm -rf "$temp_dir"
    
    if command -v yay &>/dev/null; then
        success "yay installed successfully"
    else
        error "yay installation failed"
        return 1
    fi
}

# Package installation functions
install_package_category() {
    local category="$1"
    local package_file="${PACKAGES_DIR}/${category}.txt"
    
    if [[ ! -f "$package_file" ]]; then
        error "Package file not found: $package_file"
        return 1
    fi
    
    print_section "Installing $category packages"
    
    local packages
    mapfile -t packages < <(grep -v '^#' "$package_file" | grep -v '^$')
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        warning "No packages found in $category"
        return 0
    fi
    
    echo -e "${BLUE}Packages to install:${NC}"
    printf '  - %s\n' "${packages[@]}"
    echo
    
    if ! confirm "Install these packages?"; then
        warning "Skipping $category packages"
        return 0
    fi
    
    # Separate official and AUR packages
    local official_packages=()
    local aur_packages=()
    
    for package in "${packages[@]}"; do
        if pacman -Si "$package" &>/dev/null; then
            official_packages+=("$package")
        else
            aur_packages+=("$package")
        fi
    done
    
    # Install official packages
    if [[ ${#official_packages[@]} -gt 0 ]]; then
        log "Installing official packages: ${official_packages[*]}"
        sudo pacman -S --needed --noconfirm "${official_packages[@]}" || {
            error "Failed to install official packages"
            return 1
        }
    fi
    
    # Install AUR packages
    if [[ ${#aur_packages[@]} -gt 0 ]]; then
        log "Installing AUR packages: ${aur_packages[*]}"
        yay -S --needed --noconfirm "${aur_packages[@]}" || {
            error "Failed to install AUR packages"
            return 1
        }
    fi
    
    INSTALL_STATE["packages_${category}"]=true
    success "$category packages installed"
}

# Dotfiles deployment
deploy_dotfiles() {
    print_section "Deploying dotfiles"
    
    local config_dir="$HOME/.config"
    mkdir -p "$config_dir"
    
    # Symlink directories
    local dirs_to_link=(
        "hypr"
        "waybar"
        "kitty"
        "fish"
        "dunst"
        "nvim"
        "fuzzel"
        "swappy"
        "matugen"
    )
    
    for dir in "${dirs_to_link[@]}"; do
        local source="${DOTFILES_DIR}/${dir}"
        local target="${config_dir}/${dir}"
        
        if [[ ! -d "$source" ]]; then
            warning "Source directory not found: $source"
            continue
        fi
        
        if [[ -L "$target" ]]; then
            log "Symlink already exists: $target"
            continue
        fi
        
        if [[ -d "$target" ]]; then
            if confirm "Backup existing config: $target?"; then
                mv "$target" "${target}.backup.$(date +%s)"
                log "Backed up existing config: $target"
            else
                warning "Skipping: $target (directory exists)"
                continue
            fi
        fi
        
        ln -sf "$source" "$target"
        success "Linked: $source -> $target"
    done
    
    INSTALL_STATE["dotfiles_deployment"]=true
    success "Dotfiles deployed"
}

# User setup
setup_user_environment() {
    print_section "Setting up user environment"
    
    # Set fish as default shell
    if confirm "Set fish as default shell?"; then
        sudo chsh -s /usr/bin/fish "$USER"
        success "Default shell set to fish"
    fi
    
    # Git configuration
    if confirm "Configure git?"; then
        read -rp "Git username: " git_username
        read -rp "Git email: " git_email
        
        git config --global user.name "$git_username"
        git config --global user.email "$git_email"
        git config --global init.defaultBranch main
        
        success "Git configured"
    fi
    
    # SSH key generation
    if confirm "Generate SSH key?"; then
        if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
            ssh-keygen -t ed25519 -C "$git_email" -f "$HOME/.ssh/id_ed25519" -N ""
            success "SSH key generated"
        else
            warning "SSH key already exists"
        fi
    fi
    
    INSTALL_STATE["user_setup"]=true
    success "User environment configured"
}

# System optimization
optimize_system() {
    print_section "Applying system optimizations"
    
    # Enable systemd services
    local services=(
        "bluetooth.service"
        "NetworkManager.service"
    )
    
    for service in "${services[@]}"; do
        if confirm "Enable $service?"; then
            sudo systemctl enable --now "$service"
            success "Enabled: $service"
        fi
    done
    
    # GPU optimization
    if confirm "Apply GPU optimizations?"; then
        # Check for NVIDIA
        if lspci | grep -i nvidia &>/dev/null; then
            log "NVIDIA GPU detected"
            if confirm "Install NVIDIA drivers?"; then
                sudo pacman -S --needed --noconfirm nvidia nvidia-utils nvidia-settings
                success "NVIDIA drivers installed"
            fi
        fi
        
        # Check for AMD
        if lspci | grep -i amd &>/dev/null; then
            log "AMD GPU detected"
            if confirm "Install AMD drivers?"; then
                sudo pacman -S --needed --noconfirm mesa vulkan-radeon libva-mesa-driver
                success "AMD drivers installed"
            fi
        fi
    fi
    
    # Apply performance tweaks
    if confirm "Apply performance tweaks?"; then
        # Update makepkg.conf for faster builds
        sudo sed -i 's/#MAKEFLAGS="-j2"/MAKEFLAGS="-j$(nproc)"/' /etc/makepkg.conf
        sudo sed -i 's/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -z - --threads=0)/' /etc/makepkg.conf
        
        success "Performance tweaks applied"
    fi
    
    INSTALL_STATE["system_optimization"]=true
    success "System optimized"
}

# Installation summary
show_summary() {
    print_header "Installation Summary"
    
    echo -e "${BOLD}Installation Results:${NC}"
    for component in "${!INSTALL_STATE[@]}"; do
        local status_icon="${RED}✗${NC}"
        [[ "${INSTALL_STATE[$component]}" == "true" ]] && status_icon="${GREEN}✓${NC}"
        
        echo -e "  $status_icon $(echo "$component" | tr '_' ' ')"
    done
    
    echo
    echo -e "${YELLOW}Log file: $LOG_FILE${NC}"
    echo -e "${BLUE}Dotfiles directory: $DOTFILES_DIR${NC}"
    
    if confirm "Reboot system to apply all changes?"; then
        sudo reboot
    fi
}

# Main installation flow
main() {
    # Initialize
    init_logging
    
    print_header "Dotfiles Installation System"
    echo -e "${BOLD}Welcome to Martin's Comprehensive Dotfiles Installer${NC}"
    echo
    echo "This installer will help you set up a complete Arch Linux + Hyprland environment"
    echo "with theming, development tools, and optimizations."
    echo
    
    if ! confirm "Continue with installation?"; then
        echo "Installation cancelled"
        exit 0
    fi
    
    # System checks
    print_section "System Checks"
    check_arch_linux
    check_not_root
    check_internet
    check_sudo
    
    # Install yay
    install_yay
    
    # Package installation menu
    print_section "Package Installation"
    echo "Select package categories to install:"
    
    confirm "Essential packages (core system tools)?" && install_package_category "essential"
    confirm "Development packages (programming tools)?" && install_package_category "development"
    confirm "Theming packages (matugen, themes, fonts)?" && install_package_category "theming"
    confirm "Multimedia packages (media tools)?" && install_package_category "multimedia"
    confirm "Gaming packages (Steam, gaming tools)?" && install_package_category "gaming"
    confirm "Optional packages (nice-to-have tools)?" && install_package_category "optional"
    
    # Configuration
    confirm "Deploy dotfiles configurations?" && deploy_dotfiles
    confirm "Set up user environment?" && setup_user_environment
    confirm "Apply system optimizations?" && optimize_system
    
    # Summary
    show_summary
}

# Run main function
main "$@" 