#!/bin/bash

# Chaotic-AUR Repository Setup Script
# Author: Martin's Dotfiles - Modular Version
# Description: Setup Chaotic-AUR repository for pre-built binaries

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/chaotic-aur_$(date +%Y%m%d_%H%M%S).log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Flags
FORCE_SETUP=false
SKIP_CONFIRMATION=false

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    echo "Starting Chaotic-AUR setup - $(date)" >> "$LOG_FILE"
    echo "[LOG] Script: $SCRIPT_NAME" >> "$LOG_FILE"
}

# Logging functions
log_info() {
    local msg="[INFO] $1"
    echo -e "${BLUE}$msg${NC}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') $msg" >> "$LOG_FILE"
}

log_success() {
    local msg="[SUCCESS] $1"
    echo -e "${GREEN}✓ $msg${NC}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') $msg" >> "$LOG_FILE"
}

log_error() {
    local msg="[ERROR] $1"
    echo -e "${RED}✗ $msg${NC}" >&2
    echo "$(date +'%Y-%m-%d %H:%M:%S') $msg" >> "$LOG_FILE"
}

log_warning() {
    local msg="[WARNING] $1"
    echo -e "${YELLOW}⚠ $msg${NC}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') $msg" >> "$LOG_FILE"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if running on Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        log_error "Not running on Arch Linux"
        exit 1
    fi
    
    # Check if pacman is working
    if ! command -v pacman &>/dev/null; then
        log_error "pacman not found"
        exit 1
    fi
    
    # Check sudo access
    if ! sudo -v &>/dev/null; then
        log_error "No sudo access"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Fix broken pacman.conf if it exists
fix_broken_chaotic_aur() {
    if grep -q '\[chaotic-aur\]' /etc/pacman.conf && [[ ! -f /etc/pacman.d/chaotic-mirrorlist ]]; then
        log_warning "Found broken Chaotic-AUR entry in pacman.conf without mirrorlist"
        log_info "Fixing broken pacman.conf..."
        
        # Create backup
        sudo cp /etc/pacman.conf "/etc/pacman.conf.backup.$(date +%s)"
        
        # Remove broken chaotic-aur section
        sudo sed -i '/^\[chaotic-aur\]/,/^$/d' /etc/pacman.conf
        log_success "Removed broken Chaotic-AUR entries from pacman.conf"
    fi
}

# Check and fix pacman keyring
fix_pacman_keyring() {
    if [[ ! -d /etc/pacman.d/gnupg ]] || ! sudo pacman-key --list-keys >/dev/null 2>&1; then
        log_warning "Pacman keyring needs initialization"
        log_info "Initializing pacman keyring (this may take a moment)..."
        
        # Remove any broken keyring
        sudo rm -rf /etc/pacman.d/gnupg
        
        if ! sudo pacman-key --init; then
            log_error "Failed to initialize pacman keyring"
            return 1
        fi
        
        log_info "Populating Arch Linux keyring..."
        if ! sudo pacman-key --populate archlinux; then
            log_error "Failed to populate Arch Linux keyring"
            return 1
        fi
        
        log_success "Pacman keyring initialized successfully"
    fi
    
    return 0
}

# Test pacman functionality
test_pacman() {
    log_info "Testing pacman functionality..."
    if ! sudo pacman -Sy >/dev/null 2>&1; then
        log_error "Pacman is not working properly"
        return 1
    fi
    log_success "Pacman is working correctly"
    return 0
}

# Setup Chaotic-AUR repository
setup_chaotic_aur() {
    log_info "Setting up Chaotic-AUR repository..."
    log_info "🔄 Chaotic-AUR provides pre-built binaries for faster installations"
    log_info "📦 This can reduce WhiteSur installation from 25 minutes to 3 minutes"
    
    # Step 1: Fix broken configuration
    fix_broken_chaotic_aur
    
    # Step 2: Check and fix pacman keyring
    if ! fix_pacman_keyring; then
        log_error "Failed to fix pacman keyring"
        return 1
    fi
    
    # Step 3: Test pacman
    if ! test_pacman; then
        log_error "Pacman test failed"
        return 1
    fi
    
    # Step 4: Ask user confirmation (unless skipped)
    if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
        echo
        read -p "Add Chaotic-AUR repository for faster package installations? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping Chaotic-AUR repository setup"
            log_info "📦 Packages will be built from source (slower but more control)"
            return 0
        fi
    fi
    
    # Step 5: Import Chaotic-AUR key
    log_info "Importing Chaotic-AUR GPG key..."
    if ! sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com; then
        log_error "Failed to receive Chaotic-AUR key"
        return 1
    fi
    
    if ! sudo pacman-key --lsign-key 3056513887B78AEB; then
        log_error "Failed to locally sign Chaotic-AUR key"
        return 1
    fi
    
    # Step 6: Install keyring and mirrorlist packages
    log_info "Installing Chaotic-AUR keyring and mirrorlist..."
    if ! sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'; then
        log_error "Failed to install chaotic-keyring"
        return 1
    fi
    
    if ! sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'; then
        log_error "Failed to install chaotic-mirrorlist"
        return 1
    fi
    
    # Step 7: Add repository to pacman.conf
    if [[ -f /etc/pacman.d/chaotic-mirrorlist ]]; then
        if ! grep -q '\[chaotic-aur\]' /etc/pacman.conf; then
            log_info "Adding Chaotic-AUR repository to pacman.conf..."
            echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf >/dev/null
            log_success "Added Chaotic-AUR repository to pacman.conf"
        else
            log_info "Chaotic-AUR repository already configured"
        fi
    else
        log_error "Chaotic-AUR mirrorlist not found after installation"
        return 1
    fi
    
    # Step 8: Sync package database
    log_info "Syncing package database..."
    if ! sudo pacman -Sy; then
        log_warning "Failed to sync package database, but Chaotic-AUR should still work"
    fi
    
    log_success "Chaotic-AUR repository setup completed successfully"
    log_info "📦 Pre-built binaries now available for faster installations"
    
    return 0
}

# Show usage
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Chaotic-AUR repository setup script for faster package installations.

OPTIONS:
    -h, --help          Show this help message
    -f, --force         Force setup even if already configured
    -y, --yes           Skip confirmation prompts
    --log-dir DIR       Custom log directory (default: ~/dotfiles/logs)
    --dotfiles-dir DIR  Custom dotfiles directory (default: auto-detect)

DESCRIPTION:
    This script sets up the Chaotic-AUR repository which provides pre-built
    binaries for AUR packages, significantly reducing installation times.
    
    Benefits:
    - Faster installations (WhiteSur: 25min → 3min)
    - Reduced compilation load
    - Pre-compiled popular packages

EXAMPLES:
    $SCRIPT_NAME                    # Setup with confirmation
    $SCRIPT_NAME -y                 # Setup without confirmation
    $SCRIPT_NAME -f                 # Force setup even if exists

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -f|--force)
                FORCE_SETUP=true
                shift
                ;;
            -y|--yes)
                SKIP_CONFIRMATION=true
                shift
                ;;
            --log-dir)
                if [[ -n "${2:-}" ]]; then
                    LOG_DIR="$2"
                    LOG_FILE="${LOG_DIR}/chaotic-aur_$(date +%Y%m%d_%H%M%S).log"
                    shift 2
                else
                    log_error "--log-dir requires a directory path"
                    exit 1
                fi
                ;;
            --dotfiles-dir)
                if [[ -n "${2:-}" ]]; then
                    DOTFILES_DIR="$2"
                    shift 2
                else
                    log_error "--dotfiles-dir requires a directory path"
                    exit 1
                fi
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Main function
main() {
    parse_args "$@"
    init_logging
    
    echo "=== Chaotic-AUR Repository Setup ==="
    echo "Log file: $LOG_FILE"
    echo "Dotfiles directory: $DOTFILES_DIR"
    echo
    
    check_prerequisites
    
    # Check if already configured and not forcing
    if grep -q '\[chaotic-aur\]' /etc/pacman.conf && [[ -f /etc/pacman.d/chaotic-mirrorlist ]] && [[ "$FORCE_SETUP" != "true" ]]; then
        log_success "Chaotic-AUR is already configured"
        log_info "Use --force to reconfigure"
        exit 0
    fi
    
    if setup_chaotic_aur; then
        echo
        log_success "Chaotic-AUR setup completed successfully!"
        log_info "You can now install packages faster with pre-built binaries"
    else
        echo
        log_error "Chaotic-AUR setup failed"
        log_info "📦 Packages will be built from source instead"
        exit 1
    fi
    
    echo "Log file: $LOG_FILE"
}

# Run main function
main "$@" 