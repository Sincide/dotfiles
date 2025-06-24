#!/bin/bash
# NixOS Installation Script for Dotfiles Migration
# Automated installation helper for migrating from Arch + Hyprland

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_REPO="https://github.com/yourusername/dotfiles.git"  # Update this
NIXOS_CONFIG_DIR="/etc/nixos"
MIGRATION_DIR="nixos-migration"

# Logging
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root for system operations
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Don't run this script as root. Use sudo when prompted."
        exit 1
    fi
}

# Check if NixOS is installed
check_nixos() {
    if [[ ! -f /etc/NIXOS ]]; then
        log_error "This script is for NixOS systems only."
        log_info "Install NixOS first, then run this script."
        exit 1
    fi
}

# Enable flakes and new nix command
enable_flakes() {
    log_info "Enabling Nix flakes and new command..."
    
    # Create nix config directory if it doesn't exist
    mkdir -p ~/.config/nix
    
    # Enable experimental features
    cat > ~/.config/nix/nix.conf << EOF
experimental-features = nix-command flakes
auto-optimise-store = true
EOF

    # System-wide flakes (requires sudo)
    if [[ ! -f /etc/nix/nix.conf ]] || ! grep -q "experimental-features" /etc/nix/nix.conf; then
        log_info "Enabling flakes system-wide (requires sudo)..."
        sudo mkdir -p /etc/nix
        sudo tee /etc/nix/nix.conf > /dev/null << EOF
experimental-features = nix-command flakes
auto-optimise-store = true
max-jobs = auto
cores = 0
EOF
    fi

    log_success "Flakes enabled"
}

# Clone or update dotfiles
setup_dotfiles() {
    log_info "Setting up dotfiles..."
    
    if [[ -d ~/dotfiles ]]; then
        log_info "Dotfiles directory exists, updating..."
        cd ~/dotfiles
        git pull origin main || git pull origin master
    else
        log_info "Cloning dotfiles repository..."
        git clone "$DOTFILES_REPO" ~/dotfiles
        cd ~/dotfiles
    fi

    # Ensure migration directory exists
    if [[ ! -d ~/dotfiles/$MIGRATION_DIR ]]; then
        log_error "Migration directory not found: ~/dotfiles/$MIGRATION_DIR"
        log_info "Make sure you're using the correct dotfiles repository with NixOS migration files."
        exit 1
    fi

    log_success "Dotfiles ready"
}

# Backup existing configuration
backup_config() {
    log_info "Backing up existing NixOS configuration..."
    
    local backup_dir="$HOME/nixos-backup-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    if [[ -d $NIXOS_CONFIG_DIR ]]; then
        sudo cp -r $NIXOS_CONFIG_DIR "$backup_dir/etc-nixos"
        log_info "Backed up to: $backup_dir"
    fi
    
    # Backup existing Home Manager config
    if [[ -d ~/.config/home-manager ]]; then
        cp -r ~/.config/home-manager "$backup_dir/home-manager"
    fi
    
    log_success "Configuration backed up to: $backup_dir"
}

# Deploy system configuration
deploy_system_config() {
    log_info "Deploying NixOS system configuration..."
    
    local migration_path="$HOME/dotfiles/$MIGRATION_DIR"
    
    # Generate hardware configuration for current system
    log_info "Generating hardware configuration..."
    sudo nixos-generate-config --root /
    
    # Copy our system configuration
    log_info "Copying system configuration files..."
    sudo cp "$migration_path"/flake.nix $NIXOS_CONFIG_DIR/
    sudo cp -r "$migration_path"/system/* $NIXOS_CONFIG_DIR/
    
    # Set permissions
    sudo chown -R root:root $NIXOS_CONFIG_DIR
    sudo chmod -R 644 $NIXOS_CONFIG_DIR
    sudo chmod 755 $NIXOS_CONFIG_DIR $NIXOS_CONFIG_DIR/modules
    
    log_success "System configuration deployed"
}

# Update system configuration for your hardware
update_hardware_config() {
    log_info "Please update the hardware configuration for your system:"
    log_warning "Edit /etc/nixos/configuration.nix and update:"
    log_warning "  - networking.hostName (line ~8)"
    log_warning "  - time.timeZone (line ~42)"
    log_warning "  - users.users.martin.description (line ~106)"
    log_warning "  - Any hardware-specific settings"
    
    read -p "Press Enter after updating the configuration..."
}

# Build and switch to new configuration
switch_configuration() {
    log_info "Building and switching to new NixOS configuration..."
    log_warning "This will rebuild your entire system. Continue? (y/N)"
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log_info "Skipping system rebuild. You can do this manually later with:"
        log_info "  sudo nixos-rebuild switch --flake /etc/nixos#nixos-hyprland"
        return
    fi
    
    # Build first to check for errors
    log_info "Building configuration (dry run)..."
    sudo nixos-rebuild build --flake /etc/nixos#nixos-hyprland
    
    if [[ $? -eq 0 ]]; then
        log_success "Build successful, switching..."
        sudo nixos-rebuild switch --flake /etc/nixos#nixos-hyprland
        log_success "System configuration applied!"
    else
        log_error "Build failed. Check the error messages above."
        log_info "You may need to fix configuration issues before rebuilding."
        exit 1
    fi
}

# Setup Home Manager
setup_home_manager() {
    log_info "Setting up Home Manager..."
    
    # Home Manager will be installed via the flake, but we need to set up the config
    local migration_path="$HOME/dotfiles/$MIGRATION_DIR"
    
    # Copy Home Manager configuration
    mkdir -p ~/.config/home-manager
    cp -r "$migration_path"/home/* ~/.config/home-manager/
    
    # Update personal information
    log_warning "Please update personal information in ~/.config/home-manager/home.nix:"
    log_warning "  - home.username (line ~17)"
    log_warning "  - programs.git.userEmail (line ~105)"
    log_warning "  - programs.git.userName (line ~104)"
    
    read -p "Press Enter after updating the configuration..."
    
    # Apply Home Manager configuration
    log_info "Applying Home Manager configuration..."
    home-manager switch --flake ~/.config/home-manager#martin
    
    if [[ $? -eq 0 ]]; then
        log_success "Home Manager configuration applied!"
    else
        log_error "Home Manager setup failed. Check the error messages above."
    fi
}

# Install Ollama models
setup_ollama_models() {
    log_info "Setting up Ollama AI models..."
    
    if ! systemctl is-active --quiet ollama; then
        log_warning "Ollama service is not running. Starting it..."
        sudo systemctl start ollama
        sleep 5
    fi
    
    log_info "Installing essential AI models (this may take a while)..."
    
    # Essential models from your current setup
    models=(
        "llama3.2:3b"
        "codegemma:7b"
        "qwen2.5-coder:latest"
        "nomic-embed-text:latest"
    )
    
    for model in "${models[@]}"; do
        log_info "Installing model: $model"
        ollama pull "$model" || log_warning "Failed to install $model"
    done
    
    log_success "Ollama models installation completed"
}

# Test critical functionality
test_installation() {
    log_info "Testing critical functionality..."
    
    # Test Hyprland
    if command -v hyprctl &> /dev/null; then
        log_success "✓ Hyprland installed"
    else
        log_error "✗ Hyprland not found"
    fi
    
    # Test Waybar
    if command -v waybar &> /dev/null; then
        log_success "✓ Waybar installed"
    else
        log_error "✗ Waybar not found"
    fi
    
    # Test Matugen (critical for theming)
    if command -v matugen &> /dev/null; then
        log_success "✓ Matugen installed"
        matugen --version
    else
        log_error "✗ Matugen not found (CRITICAL)"
    fi
    
    # Test Ollama
    if command -v ollama &> /dev/null; then
        log_success "✓ Ollama installed"
        ollama list
    else
        log_error "✗ Ollama not found"
    fi
    
    # Test GPU monitoring
    if [[ -d /sys/class/drm/card1/device/hwmon/ ]]; then
        log_success "✓ AMD GPU monitoring available"
    else
        log_warning "⚠ AMD GPU monitoring may not work"
    fi
}

# Post-installation instructions
post_install_instructions() {
    log_success "🎉 NixOS migration installation completed!"
    echo
    log_info "Next steps:"
    echo "1. Reboot your system to ensure all services start properly"
    echo "2. Log into Hyprland desktop environment"
    echo "3. Test theming system: matugen image ~/Pictures/wallpaper.jpg"
    echo "4. Configure your personal data and preferences"
    echo "5. Test AI git automation: cd ~/dotfiles && scripts/git/dotfiles.fish sync"
    echo
    log_info "Useful commands:"
    echo "  • System rebuild: sudo nixos-rebuild switch --flake /etc/nixos#nixos-hyprland"
    echo "  • Home Manager: home-manager switch --flake ~/.config/home-manager#martin"
    echo "  • Rollback system: sudo nixos-rebuild --rollback"
    echo "  • Rollback home: home-manager generations && home-manager switch --switch-generation <num>"
    echo
    log_info "Documentation: ~/dotfiles/$MIGRATION_DIR/docs/"
    echo "  • MIGRATION_GUIDE.md - Complete migration guide"
    echo "  • TROUBLESHOOTING.md - Common issues and solutions"
    echo "  • PACKAGE_MAPPING.md - Package compatibility information"
}

# Main installation flow
main() {
    log_info "🚀 Starting NixOS dotfiles migration installation"
    
    check_root
    check_nixos
    
    log_info "This script will:"
    echo "  1. Enable Nix flakes and new command"
    echo "  2. Setup/update dotfiles repository"
    echo "  3. Backup existing configuration"
    echo "  4. Deploy NixOS system configuration"
    echo "  5. Setup Home Manager"
    echo "  6. Install Ollama AI models"
    echo "  7. Test critical functionality"
    echo
    
    read -p "Continue with installation? (y/N): " -r
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled."
        exit 0
    fi
    
    enable_flakes
    setup_dotfiles
    backup_config
    deploy_system_config
    update_hardware_config
    switch_configuration
    setup_home_manager
    setup_ollama_models
    test_installation
    post_install_instructions
    
    log_success "🎉 Installation completed successfully!"
}

# Run main function
main "$@"