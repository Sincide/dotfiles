#!/bin/bash
# Post-Installation Script
# Run this AFTER booting into the new NixOS system

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running on installed NixOS system
check_system() {
    if [[ ! -f /etc/NIXOS ]]; then
        log_error "This must be run on an installed NixOS system!"
        exit 1
    fi
    
    if [[ ! -d ~/dotfiles ]]; then
        log_error "Dotfiles not found! Please clone first:"
        log_info "git clone https://gitlab.com/marerm/dotfiles.git ~/dotfiles"
        exit 1
    fi
}

# Enable flakes for user
setup_flakes() {
    log_info "Setting up Nix flakes..."
    
    mkdir -p ~/.config/nix
    echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
    
    log_success "Flakes enabled"
}

# Replace system configuration with advanced config
upgrade_system() {
    log_info "Upgrading to advanced system configuration..."
    
    # Backup current config
    sudo cp -r /etc/nixos /etc/nixos.backup
    
    # Copy advanced configuration
    sudo cp -r ~/dotfiles/nixos-migration/system/* /etc/nixos/
    sudo cp ~/dotfiles/nixos-migration/flake.nix /etc/nixos/
    
    # Restore hardware config
    sudo cp /etc/nixos.backup/hardware-configuration.nix /etc/nixos/
    
    # Update hostname in config (get current hostname)
    current_hostname=$(hostname)
    sudo sed -i "s/nixos-hyprland/$current_hostname/" /etc/nixos/configuration.nix
    sudo sed -i "s/nixos-hyprland/$current_hostname/" /etc/nixos/flake.nix
    
    log_info "Rebuilding system with advanced configuration..."
    sudo nixos-rebuild switch --flake /etc/nixos#$current_hostname
    
    log_success "System upgraded!"
}

# Setup Home Manager
setup_home_manager() {
    log_info "Setting up Home Manager..."
    
    # Copy Home Manager config
    mkdir -p ~/.config/home-manager
    cp -r ~/dotfiles/nixos-migration/home/* ~/.config/home-manager/
    
    # Update username in config (get current user)
    current_user=$(whoami)
    sed -i "s/martin/$current_user/" ~/.config/home-manager/home.nix
    
    # Update git email (prompt user)
    read -p "Enter your git email: " git_email
    sed -i "s/your.email@example.com/$git_email/" ~/.config/home-manager/home.nix
    
    # Apply Home Manager config
    log_info "Applying Home Manager configuration..."
    home-manager switch --flake ~/.config/home-manager#$current_user
    
    log_success "Home Manager configured!"
}

# Install Ollama models
setup_ollama() {
    log_info "Setting up Ollama AI models..."
    
    # Wait for Ollama service to be ready
    log_info "Waiting for Ollama service..."
    while ! systemctl is-active --quiet ollama; do
        sleep 2
    done
    
    # Install essential models
    log_info "Installing AI models (this will take time)..."
    
    models=(
        "llama3.2:3b"
        "codegemma:7b"
        "qwen2.5-coder:latest"
        "nomic-embed-text:latest"
    )
    
    for model in "${models[@]}"; do
        log_info "Installing $model..."
        ollama pull "$model" || log_warning "Failed to install $model"
    done
    
    log_success "Ollama models installed!"
}

# Setup wallpapers and themes
setup_theming() {
    log_info "Setting up theming system..."
    
    # Create wallpaper directories
    mkdir -p ~/Pictures/wallpapers/{space,nature,gaming,minimal,dark,abstract}
    
    # Copy example wallpapers if they exist
    if [[ -d ~/dotfiles/assets/wallpapers ]]; then
        cp -r ~/dotfiles/assets/wallpapers/* ~/Pictures/wallpapers/
    fi
    
    # Test matugen
    if command -v matugen >/dev/null 2>&1; then
        log_success "Matugen available for theming"
    else
        log_warning "Matugen not found - theming may not work"
    fi
    
    log_success "Theming system ready!"
}

# Final verification
verify_installation() {
    log_info "Verifying installation..."
    
    # Check critical components
    local checks_passed=0
    local checks_total=6
    
    # Hyprland
    if command -v hyprctl >/dev/null 2>&1; then
        log_success "✓ Hyprland installed"
        ((checks_passed++))
    else
        log_error "✗ Hyprland missing"
    fi
    
    # Waybar
    if command -v waybar >/dev/null 2>&1; then
        log_success "✓ Waybar installed"
        ((checks_passed++))
    else
        log_error "✗ Waybar missing"
    fi
    
    # Matugen
    if command -v matugen >/dev/null 2>&1; then
        log_success "✓ Matugen installed"
        ((checks_passed++))
    else
        log_error "✗ Matugen missing"
    fi
    
    # Ollama
    if systemctl is-active --quiet ollama; then
        log_success "✓ Ollama service running"
        ((checks_passed++))
    else
        log_error "✗ Ollama service not running"
    fi
    
    # Home Manager
    if command -v home-manager >/dev/null 2>&1; then
        log_success "✓ Home Manager available"
        ((checks_passed++))
    else
        log_error "✗ Home Manager missing"
    fi
    
    # Git
    if command -v git >/dev/null 2>&1; then
        log_success "✓ Git installed"
        ((checks_passed++))
    else
        log_error "✗ Git missing"
    fi
    
    echo
    log_info "Verification: $checks_passed/$checks_total checks passed"
    
    if [[ $checks_passed -eq $checks_total ]]; then
        log_success "🎉 All components working!"
    else
        log_warning "Some components need attention"
    fi
}

# Main post-install process
main() {
    log_info "🔧 NixOS Post-Installation Setup"
    echo
    log_info "This will configure your advanced dotfiles setup"
    echo
    
    check_system
    
    read -p "Continue with post-installation setup? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Setup cancelled"
        exit 0
    fi
    
    setup_flakes
    upgrade_system
    setup_home_manager
    setup_ollama
    setup_theming
    verify_installation
    
    log_success "🎉 Post-installation complete!"
    echo
    log_info "What's ready:"
    echo "  • Advanced NixOS configuration with flakes"
    echo "  • Home Manager with your dotfiles"
    echo "  • Hyprland desktop environment"  
    echo "  • Dynamic theming system"
    echo "  • AI integration with Ollama"
    echo "  • GPU monitoring (if AMD GPU)"
    echo
    log_info "Next steps:"
    echo "  1. Reboot to ensure all services start: sudo reboot"
    echo "  2. Start Hyprland: Hyprland"
    echo "  3. Test theming: wallpaper-manager"
    echo "  4. Test AI: ollama run llama3.2:3b 'Hello world'"
}

main "$@"