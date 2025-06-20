#!/bin/bash

# Prerequisites Installation Script
# Author: Martin's Dotfiles - Modular Version
# Description: Install prerequisites for dotfiles installation

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/prerequisites_$(date +%Y%m%d_%H%M%S).log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    echo "Starting prerequisites installation - $(date)" >> "$LOG_FILE"
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

# System checks
check_system() {
    log_info "Performing system validation..."
    
    # Check Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        log_error "Not running on Arch Linux"
        exit 1
    fi
    log_success "Running on Arch Linux"
    
    # Check not running as root
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run as root"
        exit 1
    fi
    log_success "Running as regular user"
    
    # Check internet connection
    if ! ping -c 1 archlinux.org &>/dev/null; then
        log_error "No internet connection"
        exit 1
    fi
    log_success "Internet connection available"
    
    # Check sudo access
    if ! sudo -v &>/dev/null; then
        log_error "No sudo access"
        exit 1
    fi
    log_success "Sudo access available"
}

# Install yay AUR helper
install_yay() {
    if command -v yay &>/dev/null; then
        log_success "yay is already installed"
        return 0
    fi
    
    log_info "Installing yay AUR helper..."
    
    # Install build dependencies
    log_info "Installing build dependencies..."
    sudo pacman -S --needed --noconfirm base-devel git
    
    # Build yay from AUR
    log_info "Building yay from AUR..."
    local temp_dir
    temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    
    cd "$DOTFILES_DIR"
    rm -rf "$temp_dir"
    
    if command -v yay &>/dev/null; then
        log_success "yay installed successfully"
    else
        log_error "yay installation failed"
        exit 1
    fi
}

# Install other prerequisites
install_other_prereqs() {
    log_info "Installing other prerequisites..."
    
    # Install git if not present
    if ! command -v git &>/dev/null; then
        log_info "Installing git..."
        sudo pacman -S --needed --noconfirm git
        log_success "git installed"
    else
        log_success "git already installed"
    fi
    
    # Install curl if not present
    if ! command -v curl &>/dev/null; then
        log_info "Installing curl..."
        sudo pacman -S --needed --noconfirm curl
        log_success "curl installed"
    else
        log_success "curl already installed"
    fi
}

# Show usage
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Prerequisites installation script for dotfiles setup.

OPTIONS:
    -h, --help          Show this help message
    --log-dir DIR       Custom log directory (default: ~/dotfiles/logs)
    --dotfiles-dir DIR  Custom dotfiles directory (default: auto-detect)

DESCRIPTION:
    This script installs the prerequisites needed for the modular dotfiles
    installation system:
    - System validation (Arch Linux, user privileges, internet)
    - yay AUR helper
    - Basic tools (git, curl)

EXAMPLES:
    $SCRIPT_NAME                    # Install prerequisites with defaults
    $SCRIPT_NAME --log-dir /tmp     # Use custom log directory

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
            --log-dir)
                if [[ -n "${2:-}" ]]; then
                    LOG_DIR="$2"
                    LOG_FILE="${LOG_DIR}/prerequisites_$(date +%Y%m%d_%H%M%S).log"
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
    
    echo "=== Prerequisites Installation ==="
    echo "Log file: $LOG_FILE"
    echo "Dotfiles directory: $DOTFILES_DIR"
    echo
    
    check_system
    install_yay
    install_other_prereqs
    
    echo
    log_success "Prerequisites installation completed successfully!"
    echo "Log file: $LOG_FILE"
}

# Run main function
main "$@" 