#!/bin/bash

# Emby Server Setup Script
# Sets up Emby media server with proper media access and permissions

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/emby-setup_$(date +%Y%m%d_%H%M%S).log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Logging functions
log_info() {
    local msg="$1"
    echo -e "\033[36m[INFO]\033[0m $msg" | tee -a "$LOG_FILE"
}

log_success() {
    local msg="$1"
    echo -e "\033[32m[SUCCESS]\033[0m $msg" | tee -a "$LOG_FILE"
}

log_error() {
    local msg="$1"
    echo -e "\033[31m[ERROR]\033[0m $msg" | tee -a "$LOG_FILE"
}

log_warning() {
    local msg="$1"
    echo -e "\033[33m[WARNING]\033[0m $msg" | tee -a "$LOG_FILE"
}

log_section() {
    local msg="$1"
    echo -e "\n\033[35m=== $msg ===\033[0m" | tee -a "$LOG_FILE"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi
}

# Check if emby-server is installed
check_emby_installed() {
    if ! command -v emby-server &> /dev/null && ! systemctl list-unit-files | grep -q emby-server; then
        log_error "emby-server is not installed. Please run package installation script first."
        exit 1
    fi
    log_success "emby-server is installed"
}

# Create media group and add user
setup_media_group() {
    log_info "Setting up media group and permissions..."
    
    # Create media group if it doesn't exist
    if ! getent group media >/dev/null 2>&1; then
        sudo groupadd media
        log_success "Created media group"
    else
        log_info "media group already exists"
    fi
    
    # Add current user to media group
    if ! groups "$(whoami)" | grep -q "\bmedia\b"; then
        sudo usermod -a -G media "$(whoami)"
        log_success "Added $(whoami) to media group"
        log_warning "You'll need to log out and back in for group changes to take effect"
    else
        log_info "$(whoami) is already in media group"
    fi
}

# Create media directories
setup_media_directories() {
    log_info "Setting up media directories..."
    
    local media_dirs=(
        "/mnt/Media"
        "/mnt/Media/Movies"
        "/mnt/Media/TV Shows"
        "/mnt/Media/Music"
        "/mnt/Media/Photos"
    )
    
    for dir in "${media_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            sudo mkdir -p "$dir"
            log_success "Created directory: $dir"
        else
            log_info "Directory already exists: $dir"
        fi
        
        # Set proper permissions for media group
        sudo chown root:media "$dir"
        sudo chmod 775 "$dir"
    done
    
    log_success "Media directories configured with proper permissions"
}

# Create Emby systemd service override
create_emby_service_override() {
    log_info "Creating Emby service override for media access..."
    
    local override_dir="/etc/systemd/system/emby-server.service.d"
    local override_file="$override_dir/override.conf"
    
    # Create override directory
    sudo mkdir -p "$override_dir"
    
    # Create override configuration
    sudo tee "$override_file" > /dev/null << 'EOF'
[Service]
SupplementaryGroups=media
ReadWritePaths=/mnt/Media
UMask=0002
EOF
    
    log_success "Created Emby service override"
}

# Check for port conflicts
check_port_conflicts() {
    log_info "Checking for port conflicts on 8096..."
    
    if netstat -tuln 2>/dev/null | grep -q ":8096 "; then
        log_warning "Port 8096 is already in use."
        local existing_process=$(sudo lsof -ti:8096 2>/dev/null || echo "unknown")
        if [[ "$existing_process" != "unknown" ]]; then
            log_info "Process using port 8096: PID $existing_process"
            if pgrep -f emby-server >/dev/null; then
                log_info "Emby is already running, will restart it"
                sudo systemctl stop emby-server.service || true
                sleep 2
            else
                log_warning "Another service is using port 8096. You may need to stop it manually."
            fi
        fi
    else
        log_success "Port 8096 is available"
    fi
}

# Enable and start Emby service
enable_and_start_emby() {
    log_info "Enabling and starting Emby service..."
    
    # Reload systemd to pick up override
    sudo systemctl daemon-reload
    
    # Enable the service
    sudo systemctl enable emby-server.service
    log_success "Enabled emby-server.service"
    
    # Start the service
    sudo systemctl start emby-server.service
    
    # Wait a moment for service to start
    sleep 3
    
    # Check if service started successfully
    if sudo systemctl is-active --quiet emby-server.service; then
        log_success "Emby service started successfully"
    else
        log_warning "Emby service failed to start. Check logs with: journalctl -u emby-server.service"
        return 1
    fi
}

# Wait for Emby web interface to be ready
wait_for_emby_web() {
    log_info "Waiting for Emby web interface to be ready..."
    
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -s --connect-timeout 2 http://localhost:8096 >/dev/null 2>&1; then
            log_success "Emby web interface is ready"
            return 0
        fi
        
        log_info "Attempt $attempt/$max_attempts: Waiting for Emby to start..."
        sleep 2
        ((attempt++))
    done
    
    log_warning "Emby web interface did not become ready within 60 seconds"
    log_info "You can check manually at http://localhost:8096"
    return 1
}

# Detect Emby data directory
detect_emby_data_dir() {
    local possible_dirs=(
        "/var/lib/private/emby"
        "/var/lib/emby"
        "/home/emby/.config/emby-server"
    )
    
    for dir in "${possible_dirs[@]}"; do
        if [[ -d "$dir" ]] && sudo test -w "$dir" 2>/dev/null; then
            echo "$dir"
            return 0
        fi
    done
    
    # If no existing directory, return the most likely one
    echo "/var/lib/private/emby"
}

# Setup Emby data directory permissions
setup_emby_data_permissions() {
    log_info "Setting up Emby data directory permissions..."
    
    local emby_data_dir
    emby_data_dir=$(detect_emby_data_dir)
    
    if [[ -d "$emby_data_dir" ]]; then
        # Get the Emby service user
        local emby_user="emby"
        if systemctl show emby-server.service -p User --value | grep -q "^emby$"; then
            emby_user="emby"
        elif getent passwd emby-server >/dev/null 2>&1; then
            emby_user="emby-server"
        fi
        
        # Ensure emby user is in media group
        if getent passwd "$emby_user" >/dev/null 2>&1; then
            sudo usermod -a -G media "$emby_user" 2>/dev/null || true
            log_success "Added $emby_user to media group"
        fi
        
        log_success "Emby data directory permissions configured"
    else
        log_info "Emby data directory will be created on first run"
    fi
}

# Show access information
show_access_info() {
    log_section "Emby Setup Complete"
    
    echo "Emby Server Access:" | tee -a "$LOG_FILE"
    echo "  Web Interface: http://localhost:8096" | tee -a "$LOG_FILE"
    echo "  Setup: Follow the initial setup wizard on first visit" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "Media Directories:" | tee -a "$LOG_FILE"
    echo "  Main: /mnt/Media" | tee -a "$LOG_FILE"
    echo "  Movies: /mnt/Media/Movies" | tee -a "$LOG_FILE"
    echo "  TV Shows: /mnt/Media/TV Shows" | tee -a "$LOG_FILE"
    echo "  Music: /mnt/Media/Music" | tee -a "$LOG_FILE"
    echo "  Photos: /mnt/Media/Photos" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "Service Management:" | tee -a "$LOG_FILE"
    echo "  Start:   sudo systemctl start emby-server.service" | tee -a "$LOG_FILE"
    echo "  Stop:    sudo systemctl stop emby-server.service" | tee -a "$LOG_FILE"
    echo "  Restart: sudo systemctl restart emby-server.service" | tee -a "$LOG_FILE"
    echo "  Status:  sudo systemctl status emby-server.service" | tee -a "$LOG_FILE"
    echo "  Logs:    journalctl -u emby-server.service -f" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    
    if groups "$(whoami)" | grep -q "\bmedia\b"; then
        echo "✅ You have access to media directories" | tee -a "$LOG_FILE"
    else
        echo "⚠️  Log out and back in for media group access to take effect" | tee -a "$LOG_FILE"
    fi
}

# Create media management aliases
create_media_aliases() {
    log_info "Creating media management aliases..."
    
    local alias_file="$HOME/.config/fish/functions/media.fish"
    mkdir -p "$(dirname "$alias_file")"
    
    cat > "$alias_file" << 'EOF'
function media
    switch $argv[1]
        case ls list
            echo "Media directories:"
            ls -la /mnt/Media/ 2>/dev/null || echo "Media drive not mounted"
        case space usage
            echo "Media storage usage:"
            df -h /mnt/Media 2>/dev/null || echo "Media drive not mounted"
        case perms permissions
            echo "Media directory permissions:"
            ls -ld /mnt/Media* 2>/dev/null || echo "Media directories not found"
        case emby
            echo "Emby service status:"
            systemctl status emby-server.service --no-pager -l
        case '*'
            echo "Media management commands:"
            echo "  media ls          - List media directories"
            echo "  media space       - Show storage usage"
            echo "  media perms       - Check permissions"
            echo "  media emby        - Show Emby status"
    end
end
EOF
    
    log_success "Created media management aliases"
}

# Main execution
main() {
    log_section "Emby Server Setup"
    log_info "Starting Emby setup for user: $(whoami)"
    log_info "Log file: $LOG_FILE"
    
    check_root
    check_emby_installed
    setup_media_group
    setup_media_directories
    create_emby_service_override
    setup_emby_data_permissions
    check_port_conflicts
    enable_and_start_emby
    
    if wait_for_emby_web; then
        create_media_aliases
        show_access_info
        log_success "Emby setup completed successfully!"
    else
        log_warning "Emby setup completed but web interface may need more time to start"
        show_access_info
    fi
    
    log_info "Check the log file for details: $LOG_FILE"
}

# Run main function
main "$@"