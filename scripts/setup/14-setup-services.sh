#!/bin/bash

# Services Setup and Management Script
# Configures and manages all dotfiles services

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/services-setup_$(date +%Y%m%d_%H%M%S).log"

# CLI flags
DRY_RUN=false
SKIP_CONFIRMATION=false
ENABLE_ALL=false
DISABLE_ALL=false

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

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                log_info "Running in dry-run mode"
                shift
                ;;
            --yes)
                SKIP_CONFIRMATION=true
                log_info "Skipping confirmations"
                shift
                ;;
            --enable-all)
                ENABLE_ALL=true
                log_info "Enabling all services"
                shift
                ;;
            --disable-all)
                DISABLE_ALL=true
                log_info "Disabling all services"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
Services Setup and Management Script

This script manages all dotfiles-related services and ensures they're properly configured.

Usage: $0 [OPTIONS]

Options:
    --dry-run           Show what would be done without making changes
    --yes               Skip confirmation prompts
    --enable-all        Enable all services automatically
    --disable-all       Disable all services
    --help, -h          Show this help message

Services Managed:
    System Services:
    - emby-server       Media server
    - qbittorrent-nox   Torrent client
    - libvirtd          Virtualization
    - docker            Container platform
    
    User Services:
    - ollama            AI platform
    - pipewire-pulse    Audio system
    - wireplumber       Audio session manager

Examples:
    $0                  Interactive service management
    $0 --enable-all     Enable all services
    $0 --dry-run        Preview service changes

EOF
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi
}

# Service management functions
manage_system_service() {
    local service="$1"
    local action="$2"
    local description="$3"
    
    log_info "Managing $service ($description)..."
    
    # Check if service exists
    if ! systemctl list-unit-files | grep -q "^$service"; then
        log_warning "$service service not found, skipping"
        return 1
    fi
    
    case "$action" in
        "enable")
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "[DRY RUN] Would enable and start $service"
            else
                sudo systemctl enable "$service"
                sudo systemctl start "$service"
                if systemctl is-active --quiet "$service"; then
                    log_success "Enabled and started $service"
                else
                    log_warning "$service failed to start properly"
                fi
            fi
            ;;
        "disable")
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "[DRY RUN] Would stop and disable $service"
            else
                sudo systemctl stop "$service" || true
                sudo systemctl disable "$service"
                log_success "Stopped and disabled $service"
            fi
            ;;
        "status")
            local status
            if systemctl is-enabled --quiet "$service" 2>/dev/null; then
                status="enabled"
            else
                status="disabled"
            fi
            
            local active
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                active="active"
            else
                active="inactive"
            fi
            
            log_info "$service: $status, $active"
            ;;
    esac
}

manage_user_service() {
    local service="$1"
    local action="$2"
    local description="$3"
    
    log_info "Managing user service $service ($description)..."
    
    # Check if service exists
    if ! systemctl --user list-unit-files | grep -q "^$service"; then
        log_warning "User service $service not found, skipping"
        return 1
    fi
    
    case "$action" in
        "enable")
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "[DRY RUN] Would enable and start user service $service"
            else
                systemctl --user enable "$service"
                systemctl --user start "$service"
                if systemctl --user is-active --quiet "$service"; then
                    log_success "Enabled and started user service $service"
                else
                    log_warning "User service $service failed to start properly"
                fi
            fi
            ;;
        "disable")
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "[DRY RUN] Would stop and disable user service $service"
            else
                systemctl --user stop "$service" || true
                systemctl --user disable "$service"
                log_success "Stopped and disabled user service $service"
            fi
            ;;
        "status")
            local status
            if systemctl --user is-enabled --quiet "$service" 2>/dev/null; then
                status="enabled"
            else
                status="disabled"
            fi
            
            local active
            if systemctl --user is-active --quiet "$service" 2>/dev/null; then
                active="active"
            else
                active="inactive"
            fi
            
            log_info "User service $service: $status, $active"
            ;;
    esac
}

# Define all managed services
get_system_services() {
    cat << 'EOF'
emby-server:Media server for movies, TV shows, music, and photos
qbittorrent-nox:Headless torrent client with web interface (port 9090)
libvirtd:KVM/QEMU virtualization daemon
docker:Container platform daemon
NetworkManager:Network connection management
ollama:Local AI platform service (system-wide)
EOF
}

get_user_services() {
    cat << 'EOF'
ollama:Local AI platform (user service)
pipewire-pulse:PipeWire PulseAudio replacement
wireplumber:PipeWire session manager
qbittorrent-nox:Torrent client (user control wrapper, port 9090)
EOF
}

# Show current service status
show_service_status() {
    log_section "Current Service Status"
    
    log_info "System services:"
    while IFS=':' read -r service description; do
        [[ -n "$service" ]] && manage_system_service "$service" "status" "$description"
    done <<< "$(get_system_services)"
    
    log_info ""
    log_info "User services:"
    while IFS=':' read -r service description; do
        [[ -n "$service" ]] && manage_user_service "$service" "status" "$description"
    done <<< "$(get_user_services)"
}

# Enable essential services
enable_essential_services() {
    log_section "Enabling Essential Services"
    
    # Essential system services
    local essential_system=(
        "NetworkManager:Network connection management"
        "libvirtd:Virtualization support"
    )
    
    for service_info in "${essential_system[@]}"; do
        IFS=':' read -r service description <<< "$service_info"
        manage_system_service "$service" "enable" "$description"
    done
    
    # Essential user services
    local essential_user=(
        "pipewire-pulse:Audio system"
        "wireplumber:Audio session manager"
    )
    
    for service_info in "${essential_user[@]}"; do
        IFS=':' read -r service description <<< "$service_info"
        manage_user_service "$service" "enable" "$description"
    done
}

# Enable media services
enable_media_services() {
    log_section "Enabling Media Services"
    
    local media_services=(
        "emby-server:Media server"
        "qbittorrent-nox:Torrent client"
    )
    
    for service_info in "${media_services[@]}"; do
        IFS=':' read -r service description <<< "$service_info"
        manage_system_service "$service" "enable" "$description"
    done
}

# Enable AI services
enable_ai_services() {
    log_section "Enabling AI Services"
    
    # Check if ollama is available as system or user service
    if systemctl list-unit-files | grep -q "^ollama.service"; then
        manage_system_service "ollama" "enable" "AI platform (system)"
    elif systemctl --user list-unit-files | grep -q "^ollama.service"; then
        manage_user_service "ollama" "enable" "AI platform (user)"
    else
        log_warning "Ollama service not found"
    fi
}

# Enable development services
enable_development_services() {
    log_section "Enabling Development Services"
    
    local dev_services=(
        "docker:Container platform"
    )
    
    for service_info in "${dev_services[@]}"; do
        IFS=':' read -r service description <<< "$service_info"
        manage_system_service "$service" "enable" "$description"
    done
}

# Interactive service management
interactive_service_management() {
    log_section "Interactive Service Management"
    
    if [[ "$SKIP_CONFIRMATION" == "false" ]]; then
        echo ""
        echo "Service categories to enable:"
        echo "1. Essential services (NetworkManager, audio)"
        echo "2. Media services (Emby, qBittorrent)"
        echo "3. AI services (Ollama)"
        echo "4. Development services (Docker)"
        echo "5. All services"
        echo "6. Custom selection"
        echo ""
        read -p "Choose option [1-6]: " -n 1 -r choice
        echo ""
        
        case "$choice" in
            1)
                enable_essential_services
                ;;
            2)
                enable_essential_services
                enable_media_services
                ;;
            3)
                enable_essential_services
                enable_ai_services
                ;;
            4)
                enable_essential_services
                enable_development_services
                ;;
            5)
                enable_essential_services
                enable_media_services
                enable_ai_services
                enable_development_services
                ;;
            6)
                custom_service_selection
                ;;
            *)
                log_info "No changes made"
                ;;
        esac
    else
        # Non-interactive mode
        if [[ "$ENABLE_ALL" == "true" ]]; then
            enable_essential_services
            enable_media_services
            enable_ai_services
            enable_development_services
        elif [[ "$DISABLE_ALL" == "true" ]]; then
            disable_all_services
        else
            enable_essential_services
        fi
    fi
}

# Custom service selection
custom_service_selection() {
    log_info "Custom service selection:"
    
    # System services
    while IFS=':' read -r service description; do
        if [[ -n "$service" ]]; then
            echo ""
            read -p "Enable $service ($description)? [y/N]: " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                manage_system_service "$service" "enable" "$description"
            fi
        fi
    done <<< "$(get_system_services)"
    
    # User services
    while IFS=':' read -r service description; do
        if [[ -n "$service" ]]; then
            echo ""
            read -p "Enable user service $service ($description)? [y/N]: " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                manage_user_service "$service" "enable" "$description"
            fi
        fi
    done <<< "$(get_user_services)"
}

# Disable all services
disable_all_services() {
    log_section "Disabling All Services"
    
    while IFS=':' read -r service description; do
        [[ -n "$service" ]] && manage_system_service "$service" "disable" "$description"
    done <<< "$(get_system_services)"
    
    while IFS=':' read -r service description; do
        [[ -n "$service" ]] && manage_user_service "$service" "disable" "$description"
    done <<< "$(get_user_services)"
}

# Verify service health
verify_service_health() {
    log_section "Service Health Check"
    
    local failed_services=()
    
    # Check system services
    while IFS=':' read -r service description; do
        if [[ -n "$service" ]] && systemctl is-enabled --quiet "$service" 2>/dev/null; then
            if ! systemctl is-active --quiet "$service" 2>/dev/null; then
                failed_services+=("$service (system)")
            fi
        fi
    done <<< "$(get_system_services)"
    
    # Check user services
    while IFS=':' read -r service description; do
        if [[ -n "$service" ]] && systemctl --user is-enabled --quiet "$service" 2>/dev/null; then
            if ! systemctl --user is-active --quiet "$service" 2>/dev/null; then
                failed_services+=("$service (user)")
            fi
        fi
    done <<< "$(get_user_services)"
    
    if [[ ${#failed_services[@]} -gt 0 ]]; then
        log_warning "Failed services detected:"
        for service in "${failed_services[@]}"; do
            log_warning "  - $service"
        done
        log_info "Check logs with: journalctl -u <service-name> -n 20"
    else
        log_success "All enabled services are running properly"
    fi
}

# Create service management aliases
create_service_aliases() {
    log_info "Creating service management aliases..."
    
    local alias_file="$HOME/.config/fish/functions/services.fish"
    mkdir -p "$(dirname "$alias_file")"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would create service management aliases"
        return 0
    fi
    
    cat > "$alias_file" << 'EOF'
function services
    switch $argv[1]
        case status list
            echo "System services:"
            for service in emby-server qbittorrent-nox libvirtd docker ollama NetworkManager
                if systemctl list-unit-files | grep -q "^$service.service"
                    set -l status (systemctl is-active $service 2>/dev/null || echo "inactive")
                    set -l enabled (systemctl is-enabled $service 2>/dev/null || echo "disabled")
                    echo "  $service: $status ($enabled)"
                end
            end
            echo ""
            echo "User services:"
            for service in ollama pipewire-pulse wireplumber qbittorrent-nox
                if systemctl --user list-unit-files | grep -q "^$service.service"
                    set -l status (systemctl --user is-active $service 2>/dev/null || echo "inactive")
                    set -l enabled (systemctl --user is-enabled $service 2>/dev/null || echo "disabled")
                    echo "  $service: $status ($enabled)"
                end
            end
        case failed failures
            echo "Failed services:"
            systemctl --failed --no-pager
            echo ""
            echo "Failed user services:"
            systemctl --user --failed --no-pager
        case logs log
            if test (count $argv) -ge 2
                journalctl -u $argv[2] -f
            else
                echo "Usage: services logs <service-name>"
            end
        case restart
            if test (count $argv) -ge 2
                set -l service $argv[2]
                if systemctl list-unit-files | grep -q "^$service.service"
                    sudo systemctl restart $service
                    echo "Restarted system service: $service"
                else if systemctl --user list-unit-files | grep -q "^$service.service"
                    systemctl --user restart $service
                    echo "Restarted user service: $service"
                else
                    echo "Service not found: $service"
                end
            else
                echo "Usage: services restart <service-name>"
            end
        case enable
            if test (count $argv) -ge 2
                set -l service $argv[2]
                if systemctl list-unit-files | grep -q "^$service.service"
                    sudo systemctl enable --now $service
                    echo "Enabled system service: $service"
                else if systemctl --user list-unit-files | grep -q "^$service.service"
                    systemctl --user enable --now $service
                    echo "Enabled user service: $service"
                else
                    echo "Service not found: $service"
                end
            else
                echo "Usage: services enable <service-name>"
            end
        case disable
            if test (count $argv) -ge 2
                set -l service $argv[2]
                if systemctl list-unit-files | grep -q "^$service.service"
                    sudo systemctl disable --now $service
                    echo "Disabled system service: $service"
                else if systemctl --user list-unit-files | grep -q "^$service.service"
                    systemctl --user disable --now $service
                    echo "Disabled user service: $service"
                else
                    echo "Service not found: $service"
                end
            else
                echo "Usage: services disable <service-name>"
            end
        case '*'
            echo "Service management commands:"
            echo "  services status       - Show all service status"
            echo "  services failed       - Show failed services"
            echo "  services logs <name>  - Show service logs"
            echo "  services restart <name> - Restart service"
            echo "  services enable <name>  - Enable service"
            echo "  services disable <name> - Disable service"
    end
end
EOF
    
    log_success "Created service management aliases"
}

# Show final service summary
show_final_summary() {
    log_section "Service Management Summary"
    
    log_info "Service management completed"
    log_info ""
    log_info "Common commands:"
    log_info "  services status       - Check all service status"
    log_info "  services failed       - Show failed services"
    log_info "  services logs <name>  - View service logs"
    log_info "  services restart <name> - Restart a service"
    log_info ""
    log_info "System service logs:"
    log_info "  journalctl -u emby-server -f"
    log_info "  journalctl -u qbittorrent-nox -f"
    log_info "  journalctl -u ollama -f"
    log_info ""
    log_info "User service logs:"
    log_info "  journalctl --user -u ollama -f"
    log_info "  journalctl --user -u pipewire-pulse -f"
    
    if [[ "$DRY_RUN" == "false" ]]; then
        verify_service_health
    fi
}

# Main execution
main() {
    log_section "Services Setup and Management"
    log_info "Starting service configuration for user: $(whoami)"
    log_info "Log file: $LOG_FILE"
    
    check_root
    show_service_status
    
    interactive_service_management
    create_service_aliases
    show_final_summary
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Dry run completed. Use without --dry-run to apply changes."
    else
        log_success "Service setup completed successfully!"
    fi
    
    log_info "Check the log file for details: $LOG_FILE"
}

# Parse arguments and run main function
parse_args "$@"
main