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

# Parse package file into subcategories
parse_package_subcategories() {
    local package_file="$1"
    local -n subcategories_ref="$2"
    local -n packages_ref="$3"
    
    local current_category=""
    local line_num=0
    
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        
        # Skip empty lines
        [[ -z "$line" ]] && continue
        
        # Check if line is a comment (subcategory)
        if [[ "$line" =~ ^#[[:space:]]*(.+)$ ]]; then
            local comment="${BASH_REMATCH[1]}"
            # Skip the main header comment
            if [[ $line_num -gt 3 ]]; then
                current_category="$comment"
                subcategories_ref["$current_category"]=""
            fi
        elif [[ "$line" =~ ^[^#] ]] && [[ -n "$current_category" ]]; then
            # Add package to current subcategory
            if [[ -n "${subcategories_ref[$current_category]}" ]]; then
                subcategories_ref["$current_category"]+=" $line"
            else
                subcategories_ref["$current_category"]="$line"
            fi
            packages_ref["$line"]="$current_category"
        fi
    done < "$package_file"
}

# Beautiful package installation with subcategory selection
install_package_category() {
    local category="$1"
    local package_file="${PACKAGES_DIR}/${category}.txt"
    
    if [[ ! -f "$package_file" ]]; then
        gum_error "Package file not found: $package_file"
        return 1
    fi
    
    show_section "Installing ${category^} Packages"
    
    # Parse subcategories from package file
    declare -A subcategories
    declare -A package_to_category
    parse_package_subcategories "$package_file" subcategories package_to_category
    
    # If no subcategories found, fall back to old behavior
    if [[ ${#subcategories[@]} -eq 0 ]]; then
        local packages
        mapfile -t packages < <(grep -v '^#' "$package_file" | grep -v '^$')
        
        if [[ ${#packages[@]} -eq 0 ]]; then
            gum_warning "No packages found in $category"
            return 0
        fi
        
        gum_info "Found ${#packages[@]} packages in $category category"
        echo
        gum style --foreground=245 --border=rounded --border-foreground=245 --padding="1 2" \
            "$(printf '%s\n' "${packages[@]}")"
        echo
        
        if ! gum_confirm "Install these ${#packages[@]} packages?"; then
            gum_warning "Skipping $category packages"
            return 0
        fi
        
        # Continue with old logic for packages without subcategories
        local selected_packages=("${packages[@]}")
    else
        # Show subcategories for selection
        local subcategory_options=()
        for subcat in "${!subcategories[@]}"; do
            local pkg_count
            pkg_count=$(echo "${subcategories[$subcat]}" | wc -w)
            subcategory_options+=("$subcat ($pkg_count packages)")
        done
        
        gum_info "Found ${#subcategory_options[@]} subcategories in $category"
        echo
        
        local selected_subcategories
        selected_subcategories=$(gum choose --no-limit --cursor-prefix="[ ] " --selected-prefix="[✓] " \
            --header="Select subcategories to install:" "${subcategory_options[@]}" || true)
        
        if [[ -z "$selected_subcategories" ]]; then
            gum_warning "No subcategories selected, skipping $category"
            return 0
        fi
        
        # Collect packages from selected subcategories
        local selected_packages=()
        while IFS= read -r selected_option; do
            # Extract subcategory name (remove package count)
            local subcat_name="${selected_option% (*}"
            
            # Add packages from this subcategory
            local subcat_packages
            read -ra subcat_packages <<< "${subcategories[$subcat_name]}"
            selected_packages+=("${subcat_packages[@]}")
        done <<< "$selected_subcategories"
        
        if [[ ${#selected_packages[@]} -eq 0 ]]; then
            gum_warning "No packages selected, skipping $category"
            return 0
        fi
        
        # Show final package list
        echo
        gum_info "Selected ${#selected_packages[@]} packages for installation:"
        echo
        gum style --foreground=245 --border=rounded --border-foreground=245 --padding="1 2" \
            "$(printf '%s\n' "${selected_packages[@]}")"
        echo
        
        if ! gum_confirm "Install these ${#selected_packages[@]} packages?"; then
            gum_warning "Skipping $category packages"
            return 0
        fi
    fi
    
    # Analyze packages with beautiful progress
    gum_step "Analyzing package sources"
    local official_packages=()
    local aur_packages=()
    
    for package in "${selected_packages[@]}"; do
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
    
    # Also create themes symlink for custom GTK theme
    if [[ -d "${DOTFILES_DIR}/themes" ]]; then
        ln -sf "${DOTFILES_DIR}/themes" "$HOME/.themes"
        gum_success "Linked: themes directory"
    fi
    
    gum_info "Deploying ${#dirs_to_link[@]} configuration directories"
    echo
    
    for dir in "${dirs_to_link[@]}"; do
        local source="${DOTFILES_DIR}/${dir}"
        local target="${config_dir}/${dir}"
        
        if [[ ! -d "$source" ]]; then
            gum_warning "Source directory not found: $source"
            continue
        fi
        
        # Skip empty directories
        if [[ -z "$(ls -A "$source" 2>/dev/null)" ]]; then
            gum_info "Skipping empty directory: $dir"
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
    
    # Note: GTK themes are now handled by the dynamic theme system
    gum_info "GTK themes will be managed by the dynamic theme switcher"
    
    INSTALL_STATE["dotfiles_deployment"]=true
    gum_success "All dotfiles deployed successfully"
}

# Simple package selection menu
select_packages() {
    show_section "Package Selection"
    
    gum_info "Choose installation approach:"
    echo
    
    local install_type
    install_type=$(gum choose \
        "Quick install (recommended packages only)" \
        "Custom install (choose specific packages)" \
        "Skip packages (dotfiles only)")
    
    case "$install_type" in
        "Quick install"*)
            # Install essential packages only
            gum_info "Installing essential packages for Arch Linux + Hyprland..."
            install_package_category "essential"
            ;;
        "Custom install"*)
            # Show all package categories for custom selection
            custom_package_selection
            ;;
        "Skip packages"*)
            gum_info "Skipping package installation"
            ;;
    esac
}

# Simple package selection by category
custom_package_selection() {
    gum_info "Select package categories you want to install:"
    echo
    
    local categories=(
        "Essential packages"
        "Development packages"
        "Theming packages"
        "Multimedia packages"
        "Gaming packages"
        "Optional packages"
    )
    
    local selected_categories
    selected_categories=$(gum choose --no-limit --cursor-prefix="[ ] " --selected-prefix="[✓] " \
        --header="Select categories to install:" "${categories[@]}" || true)
    
    if [[ -z "$selected_categories" ]]; then
        gum_warning "No categories selected"
        return 0
    fi
    
    echo
    gum_info "Selected categories:"
    echo "$selected_categories"
    echo
    
    if ! gum_confirm "Install selected categories?"; then
        gum_warning "Package installation cancelled"
        return 0
    fi
    
    # Install selected categories
    local all_installed_packages=()
    while IFS= read -r category; do
        echo
        gum_info "🚀 Processing category: $category"
        local category_packages=()
        case "$category" in
            "Essential packages")
                install_simple_category_no_setup "essential" 
                mapfile -t category_packages < <(grep -v '^#' "${PACKAGES_DIR}/essential.txt" | grep -v '^$')
                ;;
            "Development packages")
                install_simple_category_no_setup "development"
                mapfile -t category_packages < <(grep -v '^#' "${PACKAGES_DIR}/development.txt" | grep -v '^$')
                ;;
            "Theming packages")
                install_simple_category_no_setup "theming"
                mapfile -t category_packages < <(grep -v '^#' "${PACKAGES_DIR}/theming.txt" | grep -v '^$')
                ;;
            "Multimedia packages")
                install_simple_category_no_setup "multimedia"
                mapfile -t category_packages < <(grep -v '^#' "${PACKAGES_DIR}/multimedia.txt" | grep -v '^$')
                ;;
            "Gaming packages")
                install_simple_category_no_setup "gaming"
                mapfile -t category_packages < <(grep -v '^#' "${PACKAGES_DIR}/gaming.txt" | grep -v '^$')
                ;;
            "Optional packages")
                install_simple_category_no_setup "optional"
                mapfile -t category_packages < <(grep -v '^#' "${PACKAGES_DIR}/optional.txt" | grep -v '^$')
                ;;
        esac
        all_installed_packages+=("${category_packages[@]}")
        gum_info "✅ Finished processing: $category"
    done <<< "$selected_categories"
    
    echo
    gum_success "🎉 All selected categories have been processed!"
    
    # Run post-installation setup once for all packages
    if [[ ${#all_installed_packages[@]} -gt 0 ]]; then
        echo
        gum_info "🔧 Running post-installation setup for all packages..."
        post_install_setup "all" "${all_installed_packages[@]}"
    fi
}

# Simplified category installation (no subcategory selection)
install_simple_category() {
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
    
    gum_info "Installing ${#packages[@]} $category packages..."
    
    # Install packages directly without showing the list (for simplicity)
    install_packages_list "${packages[@]}"
    
    # Post-installation setup for specific packages
    post_install_setup "$category" "${packages[@]}"
    
    INSTALL_STATE["packages_${category}"]=true
    gum_success "$category packages installation completed"
}

# Category installation without post-setup (for multi-category processing)
install_simple_category_no_setup() {
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
    
    gum_info "Installing ${#packages[@]} $category packages..."
    
    # Install packages directly without showing the list (for simplicity)
    install_packages_list "${packages[@]}"
    
    INSTALL_STATE["packages_${category}"]=true
    gum_success "$category packages installation completed"
}

# Post-installation setup for specific packages
post_install_setup() {
    local category="$1"
    shift
    local packages=("$@")
    
    gum_info "🔧 Running post-installation setup for $category packages..."
    gum_info "📦 Checking packages: ${packages[*]}"
    
    # Check for packages that need special setup
    for package in "${packages[@]}"; do
        gum_info "🔍 Checking package: $package"
        case "$package" in
            "virt-manager")
                gum_info "🖥️ Found virt-manager, setting up..."
                setup_virt_manager
                ;;
            "docker")
                gum_info "🐳 Found docker, setting up..."
                setup_docker
                ;;
            "qemu")
                gum_info "⚙️ Found qemu, setting up..."
                setup_qemu
                ;;
            "ollama")
                gum_info "🤖 Found ollama, setting up..."
                setup_ollama
                ;;
        esac
    done
    
    gum_info "✅ Post-installation setup completed for $category"
}

# Setup Virtual Machine Manager (virt-manager)
setup_virt_manager() {
    if ! pacman -Qi virt-manager &>/dev/null; then
        return 0  # Not installed, skip setup
    fi
    
    gum_step "🖥️ Setting up Virtual Machine Manager"
    
    # Install additional virtualization packages
    local virt_packages=(
        "qemu-desktop"
        "libvirt"
        "edk2-ovmf"
        "bridge-utils"
        "dnsmasq"
        "openbsd-netcat"
    )
    
    gum_info "Installing virtualization dependencies..."
    for pkg in "${virt_packages[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            if sudo pacman -S --needed --noconfirm "$pkg" &>/dev/null; then
                gum style --foreground=46 "  ✓ $pkg"
            else
                gum_error "  ✗ Failed to install: $pkg"
            fi
        else
            gum style --foreground=245 "  ✓ $pkg (already installed)"
        fi
    done
    
    # Add user to libvirt group
    gum_info "Adding user to libvirt group..."
    if sudo usermod -aG libvirt "$USER"; then
        gum style --foreground=46 "  ✓ User added to libvirt group"
    else
        gum_error "  ✗ Failed to add user to libvirt group"
    fi
    
    # Enable and start libvirt services
    gum_info "Enabling virtualization services..."
    local services=("libvirtd" "virtlogd")
    for service in "${services[@]}"; do
        if sudo systemctl enable "$service" &>/dev/null && sudo systemctl start "$service" &>/dev/null; then
            gum style --foreground=46 "  ✓ $service enabled and started"
        else
            gum_error "  ✗ Failed to enable/start $service"
        fi
    done
    
    # Configure libvirt network
    gum_info "Configuring default network..."
    if sudo virsh net-start default &>/dev/null && sudo virsh net-autostart default &>/dev/null; then
        gum style --foreground=46 "  ✓ Default network configured"
    else
        gum_warning "  ⚠ Default network may need manual configuration"
    fi
    
    # Set up UEFI firmware path
    gum_info "Configuring UEFI firmware..."
    if [[ -f /usr/share/edk2-ovmf/x64/OVMF_CODE.fd ]]; then
        gum style --foreground=46 "  ✓ UEFI firmware available"
    else
        gum_warning "  ⚠ UEFI firmware may not be properly configured"
    fi
    
    gum_success "🖥️ Virtual Machine Manager setup completed!"
    gum_info "💡 Note: You may need to log out and back in for group changes to take effect"
}

# Setup Docker (placeholder for future)
setup_docker() {
    if ! pacman -Qi docker &>/dev/null; then
        return 0
    fi
    
    gum_info "🐳 Setting up Docker..."
    sudo usermod -aG docker "$USER"
    sudo systemctl enable docker
    sudo systemctl start docker
    gum_success "🐳 Docker setup completed!"
}

# Setup QEMU (placeholder for future)
setup_qemu() {
    if ! pacman -Qi qemu &>/dev/null; then
        return 0
    fi
    
    gum_info "⚙️ QEMU detected - configuration handled by virt-manager setup"
}

# Global flag to prevent multiple ollama setups
OLLAMA_SETUP_DONE=false

# Setup Ollama and AI models
setup_ollama() {
    gum_info "🔍 setup_ollama() called - checking ollama installation..."
    
    # Check if we've already done ollama setup
    if [[ "$OLLAMA_SETUP_DONE" == "true" ]]; then
        gum_info "⏭️ Ollama setup already completed, skipping..."
        return 0
    fi
    
    # Debug: Check ollama status
    if pacman -Qi ollama &>/dev/null; then
        gum_success "✅ Ollama package found in package database"
    else
        gum_warning "⚠️ Ollama package not found in package database"
    fi
    
    if command -v ollama &>/dev/null; then
        gum_success "✅ Ollama binary found in PATH"
    else
        gum_warning "⚠️ Ollama binary not found in PATH"
    fi
    
    # Check if ollama is installed by looking for the package OR if the binary exists
    if ! pacman -Qi ollama &>/dev/null && ! command -v ollama &>/dev/null; then
        gum_error "❌ Ollama not found, skipping setup"
        return 0
    fi
    
    gum_info "🤖 Setting up Ollama AI platform..."
    
    # Enable and start ollama service
    if sudo systemctl enable ollama; then
        gum_success "✅ Ollama service enabled"
    else
        gum_error "❌ Failed to enable ollama service"
    fi
    
    if sudo systemctl start ollama; then
        gum_success "✅ Ollama service started"
    else
        gum_error "❌ Failed to start ollama service"
    fi
    
    # Wait for service to be ready
    gum_info "⏳ Waiting for ollama service to be ready..."
    sleep 5
    
    # Verify service is running
    if systemctl is-active --quiet ollama; then
        gum_success "✅ Ollama service is running"
    else
        gum_error "❌ Ollama service failed to start"
        gum_info "📋 Service status:"
        systemctl status ollama || true
        return 1
    fi
    
    gum_success "🚀 Ollama service enabled and started"
    
    if gum_confirm "Install AI language models?"; then
        install_ollama_models
    else
        gum_info "⏭️ Skipping model installation"
    fi
    
    # Mark ollama setup as completed
    OLLAMA_SETUP_DONE=true
}

# Install Ollama models with interactive selection
install_ollama_models() {
    gum_info "🧠 Select AI models to install:"
    echo
    
    # Model information with descriptions
    local model_info=(
        "phi4:latest|Fast efficient model for coding and general tasks|2.5GB|⭐ Recommended for beginners"
        "llava:latest|Multimodal model with vision capabilities|4.7GB|🎯 RECOMMENDED FOR VISION TASKS"
        "llama3.2:latest|Great all-around model from Meta|2GB|⭐ Popular choice"
        "codellama:7b|Specialized for code generation|3.8GB|💻 Best for programming"
        "qwen2.5-coder:7b|Excellent coding assistant|4.2GB|💻 Advanced programming"
        "mistral:7b|Fast multilingual model|4.1GB|🌍 Good for languages"
        "llama3.1:8b|Meta's latest, great for complex tasks|4.7GB|🚀 High performance"
        "deepseek-coder:6.7b|Excellent coding assistant|3.8GB|💻 Pro development"
        "moondream:latest|Lightweight vision model|1.7GB|👁️ Fast vision tasks"
        "phi3.5:latest|Very fast, good for quick tasks|2.2GB|⚡ Lightweight"
        "tinyllama:latest|Ultra-lightweight model|637MB|⚡ Minimal resource use"
    )
    
    # Create formatted choices with descriptions
    local choices=()
    for info in "${model_info[@]}"; do
        IFS='|' read -r model desc size badge <<< "$info"
        choices+=("$model - $desc ($size) $badge")
    done
    
    local selected_models
    selected_models=$(gum choose --no-limit --cursor-prefix="[ ] " --selected-prefix="[✓] " \
        --header="Select models to install (use space to select, enter to confirm):" \
        "${choices[@]}" || true)
    
    if [[ -z "$selected_models" ]]; then
        gum_warning "No models selected"
        return 0
    fi
    
    echo
    gum_info "Selected models:"
    echo "$selected_models"
    echo
    
    # Calculate total size
    local total_size=0
    while IFS= read -r choice; do
        if [[ "$choice" =~ \(([0-9.]+)(GB|MB)\) ]]; then
            local size="${BASH_REMATCH[1]}"
            local unit="${BASH_REMATCH[2]}"
            if [[ "$unit" == "GB" ]]; then
                total_size=$(echo "$total_size + $size" | bc -l 2>/dev/null || echo "$total_size")
            else
                # Convert MB to GB
                size=$(echo "scale=2; $size / 1024" | bc -l 2>/dev/null || echo "0")
                total_size=$(echo "$total_size + $size" | bc -l 2>/dev/null || echo "$total_size")
            fi
        fi
    done <<< "$selected_models"
    
    if command -v bc &>/dev/null; then
        gum_info "💾 Total download size: ~${total_size%.*}GB"
    fi
    echo
    
    if ! gum_confirm "Download and install selected models?"; then
        gum_warning "Model installation cancelled"
        return 0
    fi
    
    # Install selected models
    while IFS= read -r choice; do
        if [[ "$choice" =~ ^([^[:space:]]+) ]]; then
            local model="${BASH_REMATCH[1]}"
            echo
            gum_info "📥 Installing model: $model"
            
            if timeout 1800 ollama pull "$model"; then  # 30 minute timeout
                gum_success "✅ Successfully installed: $model"
            else
                gum_error "❌ Failed to install: $model"
            fi
        fi
    done <<< "$selected_models"
    
    echo
    gum_success "🤖 Ollama setup completed!"
    gum_info "💡 You can chat with models using: ollama run <model-name>"
    gum_info "💡 List installed models with: ollama list"
}

# Install a list of packages (shared function)
install_packages_list() {
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        gum_warning "No packages to install"
        return 0
    fi
    
    # Analyze packages
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
    
    # Install official packages one by one
    if [[ ${#official_packages[@]} -gt 0 ]]; then
        gum_step "Installing ${#official_packages[@]} official packages"
        local failed_official=()
        
        for package in "${official_packages[@]}"; do
            # Check if package is already installed
            if pacman -Qi "$package" &>/dev/null; then
                gum style --foreground=245 "  ✓ $package (already installed)"
                continue
            fi
            
            gum style --foreground=75 "  → Installing $package"
            if ! sudo pacman -S --needed --noconfirm "$package" &>/dev/null; then
                failed_official+=("$package")
                gum_error "  ✗ Failed to install: $package"
            else
                gum style --foreground=46 "  ✓ $package"
            fi
        done
        
        if [[ ${#failed_official[@]} -gt 0 ]]; then
            echo
            gum_error "❌ OFFICIAL PACKAGES FAILED ❌"
            gum_info "Failed official packages (${#failed_official[@]}):"
            for pkg in "${failed_official[@]}"; do
                echo "  • $pkg"
            done
            echo
            
            local choices=("Continue with remaining packages" "Abort installation")
            local choice
            choice=$(gum choose --header="What would you like to do?" "${choices[@]}" < /dev/tty)
            
            case "$choice" in
                "Continue with remaining packages")
                    gum_warning "Continuing installation (${#failed_official[@]} packages skipped)"
                    ;;
                "Abort installation")
                    gum_error "Installation aborted by user"
                    exit 1
                    ;;
            esac
        else
            gum_success "All official packages installed successfully"
        fi
    fi
    
    # Install AUR packages one by one
    if [[ ${#aur_packages[@]} -gt 0 ]]; then
        gum_step "Installing ${#aur_packages[@]} AUR packages"
        local failed_aur=()
        
        for package in "${aur_packages[@]}"; do
            # Check if package is already installed
            if pacman -Qi "$package" &>/dev/null; then
                gum style --foreground=245 "  ✓ $package (already installed)"
                continue
            fi
            
            gum style --foreground=75 "  → Installing $package"
            if ! yay -S --needed --noconfirm "$package" &>/dev/null; then
                failed_aur+=("$package")
                gum_error "  ✗ Failed to install: $package"
            else
                gum style --foreground=46 "  ✓ $package"
            fi
        done
        
        if [[ ${#failed_aur[@]} -gt 0 ]]; then
            echo
            gum_error "❌ AUR PACKAGES FAILED ❌"
            gum_info "Failed AUR packages (${#failed_aur[@]}):"
            for pkg in "${failed_aur[@]}"; do
                echo "  • $pkg"
            done
            echo
            
            local choices=("Continue with remaining packages" "Abort installation")
            local choice
            choice=$(gum choose --header="What would you like to do?" "${choices[@]}" < /dev/tty)
            
            case "$choice" in
                "Continue with remaining packages")
                    gum_warning "Continuing installation (${#failed_aur[@]} packages skipped)"
                    ;;
                "Abort installation")
                    gum_error "Installation aborted by user"
                    exit 1
                    ;;
            esac
        else
            gum_success "All AUR packages installed successfully"
        fi
    fi
}

# User environment setup
user_setup() {
    show_section "User Environment Setup"
    
    gum_info "Configuring user environment and permissions..."
    
    # Set up user directories
    gum_step "Creating user directories"
    local user_dirs=(
        "$HOME/Documents"
        "$HOME/Downloads"
        "$HOME/Pictures/Screenshots"
        "$HOME/Videos"
        "$HOME/Development"
        "$HOME/.local/bin"
    )
    
    for dir in "${user_dirs[@]}"; do
        if mkdir -p "$dir" 2>/dev/null; then
            gum style --foreground=46 "  ✓ $dir"
        else
            gum_error "  ✗ Failed to create: $dir"
        fi
    done
    
    # Configure shell environment
    gum_step "Configuring shell environment"
    if [[ "$SHELL" != */fish ]]; then
        if gum_confirm "Change default shell to fish?"; then
            if chsh -s "$(which fish)" 2>/dev/null; then
                gum_success "  ✓ Default shell changed to fish"
            else
                gum_error "  ✗ Failed to change shell"
            fi
        fi
    else
        gum_success "  ✓ Fish is already default shell"
    fi
    
    # Set up development environment
    gum_step "Setting up development environment"
    if [[ ! -f "$HOME/.gitconfig" ]]; then
        if gum_confirm "Configure Git user settings?"; then
            echo "Enter your Git username:"
            read -r git_username
            echo "Enter your Git email:"
            read -r git_email
            
            git config --global user.name "$git_username"
            git config --global user.email "$git_email"
            git config --global init.defaultBranch main
            gum_success "  ✓ Git configured"
        fi
    else
        gum_success "  ✓ Git already configured"
    fi
    
    INSTALL_STATE["user_setup"]=true
    gum_success "User environment setup completed!"
}

# System optimization
system_optimization() {
    show_section "System Optimization"
    
    gum_info "Applying system performance optimizations..."
    
    # Enable multilib repository
    gum_step "Configuring package repositories"
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        if gum_confirm "Enable multilib repository for 32-bit support?"; then
            echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf >/dev/null
            sudo pacman -Sy
            gum_success "  ✓ Multilib repository enabled"
        fi
    else
        gum_success "  ✓ Multilib repository already enabled"
    fi
    
    # Configure makepkg for faster compilation
    gum_step "Optimizing compilation settings"
    local makepkg_conf="/etc/makepkg.conf"
    local cpu_cores=$(nproc)
    
    if sudo sed -i "s/^#MAKEFLAGS=.*/MAKEFLAGS=\"-j$cpu_cores\"/" "$makepkg_conf" 2>/dev/null; then
        gum_success "  ✓ Compilation optimized for $cpu_cores cores"
    else
        gum_warning "  ⚠ Could not optimize compilation settings"
    fi
    
    # Enable colored output in pacman
    gum_step "Configuring package manager"
    if sudo sed -i 's/^#Color/Color/' /etc/pacman.conf 2>/dev/null; then
        gum_success "  ✓ Pacman colored output enabled"
    else
        gum_warning "  ⚠ Could not enable pacman colors"
    fi
    
    # Configure swap settings for better performance
    gum_step "Optimizing system performance"
    if echo 'vm.swappiness=10' | sudo tee /etc/sysctl.d/99-swappiness.conf >/dev/null; then
        gum_success "  ✓ Swappiness optimized"
    else
        gum_warning "  ⚠ Could not optimize swappiness"
    fi
    
    INSTALL_STATE["system_optimization"]=true
    gum_success "System optimization completed!"
}

# Dynamic theme system installation
install_dynamic_themes() {
    show_section "Dynamic Theme System Installation"
    
    gum_info "Installing comprehensive dynamic theming system..."
    echo
    
    if ! gum_confirm "Install dynamic theme system? This will download multiple theme packages." "Yes"; then
        gum_warning "Skipping dynamic theme installation"
        return 0
    fi
    
    # Essential themes and dependencies
    gum_step "Installing essential theming packages"
    local essential_packages=(
        "papirus-icon-theme"
        "bibata-cursor-git"     # Modern cursor theme with hyprcursor support
        "cinnamon-desktop"      # Fixes Nemo warnings
        "nemo"                  # File manager (nemo-fileroller is auto included)
    )
    
    for package in "${essential_packages[@]}"; do
        gum spin --spinner=line --title="Installing $package" -- \
            yay -S --needed --noconfirm "$package" 2>/dev/null || gum_warning "Failed to install $package"
    done
    
    # GTK themes
    gum_step "Installing GTK themes"
    local gtk_themes=(
        "orchis-theme"              # Material Design (official repo)
        "arc-gtk-theme"             # Popular flat theme (AUR)
        "everforest-gtk-theme-git"  # Nature-inspired theme (AUR)
    )
    
    for theme in "${gtk_themes[@]}"; do
        if gum_confirm "Install $theme?"; then
            gum spin --spinner=line --title="Installing $theme" -- \
                yay -S --needed --noconfirm "$theme" 2>/dev/null || gum_warning "Failed to install $theme"
        fi
    done
    
    # Install modern theme suites from AUR
    gum_step "Installing modern theme suites"
    local theme_suites=(
        "whitesur-gtk-theme"     # macOS-like theme
        "whitesur-icon-theme"    # Matching icon theme
    )
    
    for package in "${theme_suites[@]}"; do
        if gum_confirm "Install $package (macOS-like theme suite)?"; then
            gum spin --spinner=line --title="Installing $package" -- \
                yay -S --needed --noconfirm "$package" 2>/dev/null || gum_warning "Failed to install $package"
        fi
    done
    
    # Additional icon themes
    gum_step "Installing additional icon themes"
    local icon_packages=(
        "tela-icon-theme-git"        # Correct AUR package name
        "numix-circle-icon-theme-git" 
        "qogir-icon-theme-git"       # Correct AUR package name
    )
    
    for package in "${icon_packages[@]}"; do
        if gum_confirm "Install $package?"; then
            gum spin --spinner=line --title="Installing $package" -- \
                yay -S --needed --noconfirm "$package" 2>/dev/null || gum_warning "Failed to install $package"
        fi
    done
    
    # Cursor themes
    gum_step "Installing additional cursor themes"
    local cursor_packages=(
        "capitaine-cursors"
        "oreo-cursors-git"
    )
    
    for package in "${cursor_packages[@]}"; do
        if gum_confirm "Install $package?"; then
            gum spin --spinner=line --title="Installing $package" -- \
                yay -S --needed --noconfirm "$package" 2>/dev/null || gum_warning "Failed to install $package"
        fi
    done
    
    # Setup theme cache system
    gum_step "Setting up theme cache system"
    local cache_manager="$DOTFILES_DIR/scripts/theming/theme_cache_manager.sh"
    if [[ -f "$cache_manager" ]]; then
        chmod +x "$cache_manager"
        
        # Option to pre-cache themes
        if gum_confirm "Pre-cache themes to avoid re-downloading on fresh installs?"; then
            gum_info "📦 Caching git-based themes to ~/dotfiles/themes/cached/"
            gum_info "This will save themes locally for faster future installations."
            echo
            
            gum spin --spinner=line --title="Downloading and caching themes..." -- \
                bash "$cache_manager" cache-all
            
            gum_success "  ✓ Themes cached successfully"
            
            # Show cache status
            echo
            gum_info "Cache summary:"
            bash "$cache_manager" list
        fi
    else
        gum_warning "  ⚠ Theme cache manager not found"
    fi

    # Setup dynamic theme switcher
    gum_step "Configuring dynamic theme system"
    local theme_switcher="$DOTFILES_DIR/scripts/theming/dynamic_theme_switcher.sh"
    if [[ -f "$theme_switcher" ]]; then
        chmod +x "$theme_switcher"
        
        # Create configuration
        gum spin --spinner=dot --title="Creating theme configuration" -- \
            bash "$theme_switcher" config
        
        gum_success "  ✓ Dynamic theme switcher configured"
        
        # Test the system
        if gum_confirm "Test dynamic theme system with space wallpaper?"; then
            local test_wallpaper="$DOTFILES_DIR/assets/wallpapers/space/dark_space.jpg"
            if [[ -f "$test_wallpaper" ]]; then
                gum spin --spinner=line --title="Testing theme application" -- \
                    bash "$theme_switcher" apply "$test_wallpaper"
                gum_success "  ✓ Theme system test completed"
            else
                gum_warning "  ⚠ Test wallpaper not found"
            fi
        fi
    else
        gum_error "  ✗ Dynamic theme switcher not found"
    fi
    
    gum_success "Dynamic theme system installation completed!"
}

# Theming system setup
theming_setup() {
    show_section "Theming System Configuration"
    
    gum_info "Setting up dynamic theming system..."
    
    # Create theming directories
    gum_step "Creating theming directories"
    local theme_dirs=(
        "$HOME/.config/matugen"
        "$HOME/.config/matugen/templates"
        "$HOME/.local/share/wallpapers"
        "$HOME/.themes"
        "$HOME/.icons"
    )
    
    for dir in "${theme_dirs[@]}"; do
        if mkdir -p "$dir" 2>/dev/null; then
            gum style --foreground=46 "  ✓ $dir"
        else
            gum_error "  ✗ Failed to create: $dir"
        fi
    done
    
    # Set up wallpaper symlinks
    gum_step "Setting up wallpaper collection"
    if [[ -d "$DOTFILES_DIR/assets/wallpapers" ]]; then
        ln -sf "$DOTFILES_DIR/assets/wallpapers" "$HOME/.local/share/wallpapers/dotfiles"
        gum_success "  ✓ Wallpaper collection linked"
    else
        gum_warning "  ⚠ Wallpaper collection not found"
    fi
    
    # Install dynamic themes
    install_dynamic_themes
    
    # Create theme restart script
    gum_step "Installing theme utilities"
    mkdir -p "$HOME/.local/bin"
    local theme_script="$HOME/.local/bin/restart-theme"
    cat > "$theme_script" << 'EOF'
#!/bin/bash
# Restart theming applications after theme change
pkill waybar 2>/dev/null || true
pkill dunst 2>/dev/null || true
sleep 0.5
waybar > /dev/null 2>&1 &
waybar -c ~/.config/waybar/config-bottom -s ~/.config/waybar/style-bottom.css > /dev/null 2>&1 &
dunst > /dev/null 2>&1 &
hyprctl reload 2>/dev/null || true
notify-send "Theme Updated" "All applications reloaded with new theme" 2>/dev/null || true
EOF
    chmod +x "$theme_script"
    gum_success "  ✓ Theme restart utility installed"
    
    # Fix Nemo file manager integration
    gum_step "Configuring Nemo file manager"
    if command -v nemo >/dev/null 2>&1; then
        # Install missing Nemo dependencies
        yay -S --needed --noconfirm cinnamon-desktop nemo-fileroller 2>/dev/null || true
        
        # Set Nemo as default file manager
        if gum_confirm "Set Nemo as default file manager?"; then
            xdg-mime default nemo.desktop inode/directory 2>/dev/null || true
            gum_success "  ✓ Nemo configured as default file manager"
        fi
    fi
    
    INSTALL_STATE["theming"]=true
    gum_success "Theming system setup completed!"
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
    gum_info "📦 Package installation completed. Moving to configuration phase..."
    echo
    if gum_confirm "Deploy dotfiles configurations?"; then
        deploy_dotfiles
    fi
    
    # Additional setup options
    echo
    if gum_confirm "Run user environment setup?"; then
        user_setup
    fi
    
    echo
    if gum_confirm "Apply system optimizations?"; then
        system_optimization
    fi
    
    echo
    if gum_confirm "Configure theming system?"; then
        theming_setup
    fi
    
    # Final summary
    echo
    gum_info "🏁 Moving to final summary..."
    show_summary
}

# Run main function
main "$@" 