#!/bin/bash

# qBittorrent-nox Setup Script
# Author: Martin's Dotfiles
# Description: Setup qbittorrent-nox with custom configuration and systemd service

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/qbittorrent_setup_$(date +%Y%m%d_%H%M%S).log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# qBittorrent configuration
readonly QBITTORRENT_CONFIG_DIR="$HOME/.config/qBittorrent"
readonly QBITTORRENT_LOCAL_DIR="$HOME/.local/share/qBittorrent"
readonly DOWNLOADS_DIR="/mnt/Media"
readonly INCOMPLETE_DIR="/mnt/Stuff/temp"
readonly WEBUI_PORT=9090
readonly DEFAULT_USERNAME="admin"
readonly DEFAULT_PASSWORD="adminpass"

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    echo "Starting qBittorrent-nox setup - $(date)" >> "$LOG_FILE"
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

log_section() {
    local msg="$1"
    echo -e "${CYAN}=== $msg ===${NC}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [SECTION] $msg" >> "$LOG_FILE"
}

# Install qbittorrent-nox if not already installed
install_qbittorrent_nox() {
    log_info "Checking if qbittorrent-nox is installed..."
    
    if command -v qbittorrent-nox &>/dev/null; then
        log_success "qbittorrent-nox is already installed"
        return 0
    fi
    
    log_info "qbittorrent-nox not found, installing..."
    
    # Check if yay is available
    if ! command -v yay &>/dev/null; then
        log_error "yay is not installed. Please install yay first."
        exit 1
    fi
    
    # Install qbittorrent-nox
    if yay -S --needed --noconfirm qbittorrent-nox; then
        log_success "qbittorrent-nox installed successfully"
    else
        log_error "Failed to install qbittorrent-nox"
        exit 1
    fi
    
    # Verify installation
    if ! command -v qbittorrent-nox &>/dev/null; then
        log_error "qbittorrent-nox installation verification failed"
        exit 1
    fi
    
    log_success "qbittorrent-nox installation verified"
}

# Create necessary directories
create_directories() {
    log_section "Creating directories"
    
    local dirs=(
        "$QBITTORRENT_CONFIG_DIR"
        "$QBITTORRENT_LOCAL_DIR"
        "$DOWNLOADS_DIR"
        "$INCOMPLETE_DIR"
    )
    
    for dir in "${dirs[@]}"; do
        if mkdir -p "$dir"; then
            log_success "Created directory: $dir"
        else
            log_error "Failed to create directory: $dir"
            exit 1
        fi
    done
}

# Deploy configuration
deploy_configuration() {
    log_section "Deploying qBittorrent configuration"
    
    local source_config="${DOTFILES_DIR}/qbittorrent/qBittorrent.conf"
    local target_config="${QBITTORRENT_CONFIG_DIR}/qBittorrent.conf"
    
    if [[ ! -f "$source_config" ]]; then
        log_error "Source configuration not found: $source_config"
        exit 1
    fi
    
    # Backup existing configuration if it exists
    if [[ -f "$target_config" ]]; then
        local backup_file="${target_config}.backup.$(date +%Y%m%d_%H%M%S)"
        if cp "$target_config" "$backup_file"; then
            log_info "Backed up existing config to: $backup_file"
        fi
    fi
    
    # Deploy new configuration
    if cp "$source_config" "$target_config"; then
        log_success "Deployed qBittorrent configuration"
    else
        log_error "Failed to deploy configuration"
        exit 1
    fi
    
    # Set correct permissions
    chmod 600 "$target_config"
    log_success "Set configuration permissions"
}

# Setup systemd service
setup_systemd_service() {
    log_section "Setting up systemd user service"
    
    local source_service="${DOTFILES_DIR}/qbittorrent/qbittorrent-nox.service"
    local target_service_dir="$HOME/.local/share/systemd/user"
    local target_service="${target_service_dir}/qbittorrent-nox.service"
    
    # Create systemd user directory
    mkdir -p "$target_service_dir"
    
    if [[ ! -f "$source_service" ]]; then
        log_error "Source service file not found: $source_service"
        exit 1
    fi
    
    # Deploy service file
    if cp "$source_service" "$target_service"; then
        log_success "Deployed systemd service file"
    else
        log_error "Failed to deploy service file"
        exit 1
    fi
    
    # Reload systemd and enable service
    if systemctl --user daemon-reload; then
        log_success "Reloaded systemd user daemon"
    else
        log_error "Failed to reload systemd daemon"
        exit 1
    fi
    
    if systemctl --user enable qbittorrent-nox.service; then
        log_success "Enabled qbittorrent-nox service"
    else
        log_error "Failed to enable service"
        exit 1
    fi
}

# Start the service
start_service() {
    log_section "Starting qBittorrent service"
    
    # Stop service if already running
    if systemctl --user is-active --quiet qbittorrent-nox.service; then
        log_info "Stopping existing qbittorrent-nox service..."
        systemctl --user stop qbittorrent-nox.service
    fi
    
    # Start the service
    if systemctl --user start qbittorrent-nox.service; then
        log_success "Started qbittorrent-nox service"
    else
        log_error "Failed to start service"
        exit 1
    fi
    
    # Check service status
    sleep 2
    if systemctl --user is-active --quiet qbittorrent-nox.service; then
        log_success "qBittorrent-nox is running successfully"
    else
        log_error "Service failed to start properly"
        systemctl --user status qbittorrent-nox.service
        exit 1
    fi
}

# Show access information
show_access_info() {
    log_section "Access Information"
    
    echo
    log_info "qBittorrent-nox Web UI Access:"
    echo "  URL: http://127.0.0.1:${WEBUI_PORT}"
    echo "  Username: ${DEFAULT_USERNAME}"
    echo "  Password: ${DEFAULT_PASSWORD}"
    echo
    log_warning "IMPORTANT: Change the default password after first login!"
    echo
    log_info "Download directories:"
    echo "  Complete: ${DOWNLOADS_DIR}"
    echo "  Incomplete: ${INCOMPLETE_DIR}"
    echo
    log_info "Service management:"
    echo "  Status:  systemctl --user status qbittorrent-nox"
    echo "  Stop:    systemctl --user stop qbittorrent-nox"
    echo "  Start:   systemctl --user start qbittorrent-nox"
    echo "  Restart: systemctl --user restart qbittorrent-nox"
    echo "  Logs:    journalctl --user -u qbittorrent-nox -f"
}

# Clean up any failed installation
cleanup_failed_installation() {
    log_section "Cleaning up any failed installation"
    
    # Stop service if running
    if systemctl --user is-active --quiet qbittorrent-nox.service 2>/dev/null; then
        log_info "Stopping qbittorrent-nox service..."
        systemctl --user stop qbittorrent-nox.service
    fi
    
    # Remove lock files if they exist
    local lock_files=(
        "$QBITTORRENT_LOCAL_DIR/logs/qbittorrent.lock"
        "$QBITTORRENT_CONFIG_DIR/qBittorrent-data.conf.lock"
    )
    
    for lock_file in "${lock_files[@]}"; do
        if [[ -f "$lock_file" ]]; then
            rm -f "$lock_file"
            log_info "Removed lock file: $lock_file"
        fi
    done
    
    # Kill any hanging processes
    if pgrep -x qbittorrent-nox >/dev/null; then
        log_info "Killing existing qbittorrent-nox processes..."
        pkill -x qbittorrent-nox
        sleep 2
    fi
}

# Main function
main() {
    init_logging
    
    echo "=== qBittorrent-nox Setup ==="
    echo "Log file: $LOG_FILE"
    echo "Web UI Port: $WEBUI_PORT"
    echo
    
    cleanup_failed_installation
    install_qbittorrent_nox
    create_directories
    deploy_configuration
    setup_systemd_service
    start_service
    
    echo
    log_success "qBittorrent-nox setup completed successfully!"
    echo
    
    show_access_info
}

# Run main function
main "$@" 