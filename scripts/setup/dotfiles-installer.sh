#!/bin/bash

# Beautiful Gum-powered Dotfiles Installation System
# Author: Martin's Dotfiles
# Description: Interactive installer using gum for beautiful TUI experience

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly PACKAGES_DIR="${DOTFILES_DIR}/scripts/setup/packages"
readonly LOG_FILE="${LOG_DIR}/installer_$(date +%Y%m%d_%H%M%S).log"

# Auto-install gum if not available
if ! command -v gum &>/dev/null; then
    echo "🎨 Installing gum for a beautiful installer experience..."
    if sudo pacman -S --needed --noconfirm gum; then
        echo "✓ gum installed successfully!"
        echo "Starting beautiful installer..."
        echo
        exec "$0" "$@"
    else
        echo "✗ Failed to install gum. Please install manually: sudo pacman -S gum"
        exit 1
    fi
fi

# Gum styling
readonly GUM_STYLE_HEADER="--foreground=212 --border-foreground=212 --border=double --align=center --width=60 --margin=1 --padding=2"
readonly GUM_STYLE_SECTION="--foreground=39 --bold"
readonly GUM_STYLE_SUCCESS="--foreground=46"
readonly GUM_STYLE_ERROR="--foreground=196"
readonly GUM_STYLE_WARNING="--foreground=226"
readonly GUM_STYLE_INFO="--foreground=75"

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
    echo "[LOG] Installer started from: $SCRIPT_DIR" >> "$LOG_FILE"
}

# Gum logging functions
log_to_file() {
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

gum_success() {
    gum style $GUM_STYLE_SUCCESS "✓ $1"
    log_to_file "[SUCCESS] $1"
}

gum_error() {
    gum style $GUM_STYLE_ERROR "✗ $1"
    log_to_file "[ERROR] $1"
}

gum_warning() {
    gum style $GUM_STYLE_WARNING "⚠ $1"
    log_to_file "[WARNING] $1"
}

gum_info() {
    gum style $GUM_STYLE_INFO "ℹ $1"
    log_to_file "[INFO] $1"
}

gum_step() {
    gum style --foreground=212 --bold "→ $1"
    log_to_file "[STEP] $1"
}

# Beautiful headers
show_header() {
    clear
    gum style $GUM_STYLE_HEADER "🚀 Martin's Dotfiles Installer"
    gum style --foreground=245 --align=center "Comprehensive Arch Linux + Hyprland Setup"
    echo
}

show_section() {
    echo
    gum style $GUM_STYLE_SECTION "═══ $1 ═══"
    echo
}

# Enhanced confirm with gum
gum_confirm() {
    local prompt="$1"
    local default="${2:-No}"
    
    if [[ "$default" == "Yes" ]]; then
        gum confirm "$prompt" --default=true
    else
        gum confirm "$prompt" --default=false
    fi
}

# System checks with gum feedback
check_system() {
    show_section "System Validation"
    
    local checks=(
        "Checking Arch Linux"
        "Verifying user privileges"
        "Testing internet connection"
        "Validating sudo access"
    )
    
    # Arch Linux check
    gum spin --spinner=dot --title="${checks[0]}" -- sleep 0.5
    if [[ -f /etc/arch-release ]]; then
        gum_success "Running on Arch Linux"
    else
        gum_error "Not running on Arch Linux"
        exit 1
    fi
    
    # User check
    gum spin --spinner=dot --title="${checks[1]}" -- sleep 0.3
    if [[ $EUID -eq 0 ]]; then
        gum_error "Do not run as root"
        exit 1
    else
        gum_success "Running as regular user"
    fi
    
    # Internet check
    gum spin --spinner=dot --title="${checks[2]}" -- sleep 0.5
    if ping -c 1 archlinux.org &>/dev/null; then
        gum_success "Internet connection available"
    else
        gum_error "No internet connection"
        exit 1
    fi
    
    # Sudo check
    gum spin --spinner=dot --title="${checks[3]}" -- sleep 0.3
    if sudo -n true 2>/dev/null; then
        gum_success "Sudo access available"
    elif sudo -v &>/dev/null; then
        gum_warning "Sudo requires password"
    else
        gum_error "No sudo access"
        exit 1
    fi
}

# Install yay with beautiful progress
install_yay() {
    if command -v yay &>/dev/null; then
        gum_success "yay is already installed"
        return 0
    fi
    
    show_section "Installing yay AUR Helper"
    
    gum_step "Installing build dependencies"
    gum spin --spinner=line --title="Installing base-devel and git" -- \
        sudo pacman -S --needed --noconfirm base-devel git
    
    gum_step "Building yay from AUR"
    local temp_dir
    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    gum spin --spinner=line --title="Cloning yay-bin repository" -- \
        git clone https://aur.archlinux.org/yay-bin.git
    
    cd yay-bin
    gum spin --spinner=line --title="Building and installing yay" -- \
        makepkg -si --noconfirm
    
    cd "$DOTFILES_DIR"
    rm -rf "$temp_dir"
    
    if command -v yay &>/dev/null; then
        gum_success "yay installed successfully"
    else
        gum_error "yay installation failed"
        return 1
    fi
}

# Beautiful package installation
install_package_category() {
    local category="$1"
    local package_file="${PACKAGES_DIR}/${category}.txt"
    
    if [[ ! -f "$package_file" ]]; then
        gum_error "Package file not found: $package_file"
        return 1
    fi
    
    show_section "Installing ${category^} Packages"
    
    local packages
    mapfile -t packages < <(grep -v '^#' "$package_file" | grep -v '^$')
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        gum_warning "No packages found in $category"
        return 0
    fi
    
    # Show package preview with gum
    gum_info "Found ${#packages[@]} packages in $category category"
    echo
    gum style --foreground=245 --border=rounded --border-foreground=245 --padding="1 2" \
        "$(printf '%s\n' "${packages[@]}")"
    echo
    
    if ! gum_confirm "Install these ${#packages[@]} packages?"; then
        gum_warning "Skipping $category packages"
        return 0
    fi
    
    # Analyze packages with beautiful progress
    gum_step "Analyzing package sources"
    local official_packages=()
    local aur_packages=()
    
    for package in "${packages[@]}"; do
        if pacman -Si "$package" &>/dev/null 2>&1; then
            official_packages+=("$package")
        else
            aur_packages+=("$package")
        fi
    done
    
    gum_info "Official packages: ${#official_packages[@]} | AUR packages: ${#aur_packages[@]}"
    echo
    
    # Install official packages
    if [[ ${#official_packages[@]} -gt 0 ]]; then
        gum_step "Installing ${#official_packages[@]} official packages"
        gum style --foreground=245 "${official_packages[*]}"
        
        if gum spin --spinner=line --title="Installing official packages" -- \
            sudo pacman -S --needed --noconfirm "${official_packages[@]}"; then
            gum_success "Official packages installed successfully"
        else
            gum_error "Failed to install some official packages"
            if gum_confirm "Continue with installation despite failures?"; then
                gum_warning "Continuing with partial installation"
            else
                gum_error "Installation aborted by user"
                exit 1
            fi
        fi
    fi
    
    # Install AUR packages
    if [[ ${#aur_packages[@]} -gt 0 ]]; then
        gum_step "Installing ${#aur_packages[@]} AUR packages"
        gum style --foreground=245 "${aur_packages[*]}"
        
        if gum spin --spinner=line --title="Installing AUR packages" -- \
            yay -S --needed --noconfirm "${aur_packages[@]}"; then
            gum_success "AUR packages installed successfully"
        else
            gum_error "Failed to install some AUR packages"
            if gum_confirm "Continue with installation despite failures?"; then
                gum_warning "Continuing with partial installation"
            else
                gum_error "Installation aborted by user"
                exit 1
            fi
        fi
    fi
    
    INSTALL_STATE["packages_${category}"]=true
    gum_success "$category packages installation completed"
}

# Beautiful dotfiles deployment
deploy_dotfiles() {
    show_section "Deploying Dotfiles"
    
    local config_dir="$HOME/.config"
    mkdir -p "$config_dir"
    
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
    
    gum_info "Deploying ${#dirs_to_link[@]} configuration directories"
    echo
    
    for dir in "${dirs_to_link[@]}"; do
        local source="${DOTFILES_DIR}/${dir}"
        local target="${config_dir}/${dir}"
        
        if [[ ! -d "$source" ]]; then
            gum_warning "Source directory not found: $source"
            continue
        fi
        
        if [[ -L "$target" ]]; then
            gum_info "Symlink already exists: $dir"
            continue
        fi
        
        if [[ -d "$target" ]]; then
            gum_warning "Config directory already exists: $dir"
            if gum_confirm "Backup existing config and replace?"; then
                mv "$target" "${target}.backup.$(date +%s)"
                gum_success "Backed up existing config: $dir"
            else
                gum_warning "Skipping: $dir"
                continue
            fi
        fi
        
        ln -sf "$source" "$target"
        gum_success "Linked: $dir"
    done
    
    INSTALL_STATE["dotfiles_deployment"]=true
    gum_success "All dotfiles deployed successfully"
}

# Beautiful package selection menu
select_packages() {
    show_section "Package Selection"
    
    local categories=(
        "Essential packages (core system tools)"
        "Development packages (programming tools)"
        "Theming packages (matugen, themes, fonts)"
        "Multimedia packages (media tools)"
        "Gaming packages (Steam, gamemode, wine)"
        "Optional packages (nice-to-have tools)"
    )
    
    local selected_categories
    selected_categories=$(gum choose --no-limit --cursor-prefix="[ ] " --selected-prefix="[✓] " \
        --header="Select package categories to install:" "${categories[@]}")
    
    echo
    gum_info "Selected categories:"
    echo "$selected_categories"
    echo
    
    if ! gum_confirm "Install selected package categories?"; then
        gum_warning "Package installation cancelled"
        return 0
    fi
    
    # Install selected categories
    while IFS= read -r category; do
        case "$category" in
            "Essential packages"*)
                install_package_category "essential" ;;
            "Development packages"*)
                install_package_category "development" ;;
            "Theming packages"*)
                install_package_category "theming" ;;
            "Multimedia packages"*)
                install_package_category "multimedia"
                
                # Multimedia subcategories
                echo
                gum_info "Optional multimedia components:"
                local multimedia_options=(
                    "Creative tools (GIMP, Blender, Audacity, etc.)"
                    "Additional players (VLC, Spotify, LibreOffice, etc.)"
                )
                
                local multimedia_selected
                multimedia_selected=$(gum choose --no-limit --cursor-prefix="[ ] " --selected-prefix="[✓] " \
                    --header="Select optional multimedia components:" "${multimedia_options[@]}" || true)
                
                if [[ -n "$multimedia_selected" ]]; then
                    while IFS= read -r multimedia_cat; do
                        case "$multimedia_cat" in
                            "Creative tools"*)
                                install_package_category "multimedia-creative" ;;
                            "Additional players"*)
                                install_package_category "multimedia-players" ;;
                        esac
                    done <<< "$multimedia_selected"
                fi
                ;;
            "Gaming packages"*)
                install_package_category "gaming"
                
                # Gaming subcategories
                echo
                gum_info "Optional gaming components:"
                local gaming_options=(
                    "Additional gaming platforms (Lutris, Heroic, Bottles, Minecraft)"
                    "Gaming emulators (RetroArch, Dolphin, PCSX2, etc.)"
                    "Advanced gaming tools (Discord, CoreCtrl, controllers)"
                )
                
                local gaming_selected
                gaming_selected=$(gum choose --no-limit --cursor-prefix="[ ] " --selected-prefix="[✓] " \
                    --header="Select optional gaming components:" "${gaming_options[@]}" || true)
                
                if [[ -n "$gaming_selected" ]]; then
                    while IFS= read -r gaming_cat; do
                        case "$gaming_cat" in
                            "Additional gaming platforms"*)
                                install_package_category "gaming-platforms" ;;
                            "Gaming emulators"*)
                                install_package_category "gaming-emulators" ;;
                            "Advanced gaming tools"*)
                                install_package_category "gaming-tools" ;;
                        esac
                    done <<< "$gaming_selected"
                fi
                ;;
            "Optional packages"*)
                install_package_category "optional" ;;
        esac
    done <<< "$selected_categories"
}

# Installation summary with gum
show_summary() {
    show_section "Installation Summary"
    
    local results=""
    for component in "${!INSTALL_STATE[@]}"; do
        local status_icon="✗"
        local status_color="196"
        if [[ "${INSTALL_STATE[$component]}" == "true" ]]; then
            status_icon="✓"
            status_color="46"
        fi
        
        local formatted_name
        formatted_name=$(echo "$component" | tr '_' ' ' | sed 's/packages //')
        results+="$(gum style --foreground=$status_color "$status_icon $formatted_name")\n"
    done
    
    echo -e "$results"
    echo
    gum style --foreground=245 "Log file: $LOG_FILE"
    gum style --foreground=245 "Dotfiles directory: $DOTFILES_DIR"
    echo
    
    if gum_confirm "Installation complete! Reboot system to apply all changes?"; then
        gum spin --spinner=dot --title="Rebooting system in 3 seconds..." -- sleep 3
        sudo reboot
    fi
}

# Main installation flow
main() {
    # Initialize
    init_logging
    show_header
    
    # Welcome screen
    gum style --foreground=75 --align=center \
        "Welcome to Martin's Comprehensive Dotfiles Installer" \
        "" \
        "This installer will help you set up a complete Arch Linux + Hyprland environment" \
        "with theming, development tools, and optimizations."
    echo
    
    if ! gum_confirm "Continue with installation?" "Yes"; then
        gum style --foreground=245 "Installation cancelled"
        exit 0
    fi
    
    # System checks
    check_system
    
    # Install yay
    install_yay
    
    # Package selection and installation
    select_packages
    
    # Configuration options
    echo
    if gum_confirm "Deploy dotfiles configurations?"; then
        deploy_dotfiles
    fi
    
    # Final summary
    show_summary
}

# Run main function
main "$@" 