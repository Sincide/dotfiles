#!/bin/bash

# User Groups Setup Script
# Configures all necessary user groups for the dotfiles system

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/user-groups-setup_$(date +%Y%m%d_%H%M%S).log"

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

# Check if user is in group
user_in_group() {
    local group="$1"
    groups "$(whoami)" | grep -q "\b$group\b"
}

# Add user to group safely
add_user_to_group() {
    local group="$1"
    local description="$2"
    
    # Check if group exists
    if ! getent group "$group" >/dev/null 2>&1; then
        log_warning "Group '$group' doesn't exist, skipping"
        return 1
    fi
    
    # Check if user is already in group
    if user_in_group "$group"; then
        log_info "Already in $group group"
        return 0
    fi
    
    # Add user to group
    log_info "Adding $(whoami) to $group group ($description)"
    if sudo usermod -a -G "$group" "$(whoami)"; then
        log_success "Added to $group group"
        echo "$group" >> "$LOG_DIR/groups_added_$(date +%Y%m%d).log"
        return 0
    else
        log_error "Failed to add user to $group group"
        return 1
    fi
}

# Create system groups if they don't exist
create_system_groups() {
    log_info "Creating system groups if needed..."
    
    local system_groups=(
        "media:For media server access"
        "render:For GPU rendering access"
    )
    
    for group_info in "${system_groups[@]}"; do
        IFS=':' read -r group_name group_desc <<< "$group_info"
        
        if ! getent group "$group_name" >/dev/null 2>&1; then
            log_info "Creating $group_name group ($group_desc)"
            if sudo groupadd "$group_name"; then
                log_success "Created $group_name group"
            else
                log_error "Failed to create $group_name group"
            fi
        else
            log_info "$group_name group already exists"
        fi
    done
}

# Setup essential user groups
setup_essential_groups() {
    log_section "Essential User Groups"
    
    # Essential groups for basic system functionality
    local essential_groups=(
        "wheel:Sudo access and administrative privileges"
        "users:Standard user group"
        "audio:Audio device access"
        "video:Video device access"
        "input:Input device access"
        "storage:Storage device access"
        "optical:Optical drive access"
        "scanner:Scanner device access"
        "power:Power management access"
    )
    
    local groups_added=0
    
    for group_info in "${essential_groups[@]}"; do
        IFS=':' read -r group_name group_desc <<< "$group_info"
        if add_user_to_group "$group_name" "$group_desc"; then
            ((groups_added++))
        fi
    done
    
    if [[ $groups_added -gt 0 ]]; then
        log_success "Added user to $groups_added essential groups"
    else
        log_info "User already in all essential groups"
    fi
}

# Setup hardware-specific groups
setup_hardware_groups() {
    log_section "Hardware-Specific Groups"
    
    # Hardware access groups
    local hardware_groups=(
        "render:GPU rendering and compute access"
        "kvm:KVM virtualization access"
        "libvirt:Libvirt virtualization management"
        "docker:Docker container management"
        "vboxusers:VirtualBox access"
        "wireshark:Network packet capture"
        "uucp:Serial device access"
        "lock:Lock file access"
        "rfkill:Radio frequency management"
    )
    
    local groups_added=0
    
    for group_info in "${hardware_groups[@]}"; do
        IFS=':' read -r group_name group_desc <<< "$group_info"
        if add_user_to_group "$group_name" "$group_desc"; then
            ((groups_added++))
        fi
    done
    
    if [[ $groups_added -gt 0 ]]; then
        log_success "Added user to $groups_added hardware groups"
    else
        log_info "User already in all available hardware groups"
    fi
}

# Setup media and service groups
setup_service_groups() {
    log_section "Service-Specific Groups"
    
    # Service and media groups
    local service_groups=(
        "media:Media server and file access"
        "transmission:Transmission torrent client"
        "deluge:Deluge torrent client"
        "rtkit:Real-time kit for audio"
        "gamemode:GameMode optimization"
    )
    
    local groups_added=0
    
    for group_info in "${service_groups[@]}"; do
        IFS=':' read -r group_name group_desc <<< "$group_info"
        if add_user_to_group "$group_name" "$group_desc"; then
            ((groups_added++))
        fi
    done
    
    if [[ $groups_added -gt 0 ]]; then
        log_success "Added user to $groups_added service groups"
    else
        log_info "User already in all available service groups"
    fi
}

# Setup development groups
setup_development_groups() {
    log_section "Development Groups"
    
    # Development and debugging groups
    local dev_groups=(
        "debugfs:Debug filesystem access"
        "systemd-journal:Journal log access"
        "systemd-network:Network management"
        "systemd-resolve:DNS resolution management"
        "git:Git repository access"
        "builders:Build system access"
    )
    
    local groups_added=0
    
    for group_info in "${dev_groups[@]}"; do
        IFS=':' read -r group_name group_desc <<< "$group_info"
        if add_user_to_group "$group_name" "$group_desc"; then
            ((groups_added++))
        fi
    done
    
    if [[ $groups_added -gt 0 ]]; then
        log_success "Added user to $groups_added development groups"
    else
        log_info "User already in all available development groups"
    fi
}

# Show current user groups
show_current_groups() {
    log_section "Current User Groups"
    
    local current_groups
    current_groups=$(groups "$(whoami)" | cut -d':' -f2 | tr ' ' '\n' | sort | tr '\n' ' ')
    
    log_info "User $(whoami) is member of:"
    echo "$current_groups" | tr ' ' '\n' | while read -r group; do
        if [[ -n "$group" ]]; then
            log_info "  - $group"
        fi
    done
}

# Check for groups that require logout
check_logout_required() {
    log_section "Group Changes Summary"
    
    local today_log="$LOG_DIR/groups_added_$(date +%Y%m%d).log"
    
    if [[ -f "$today_log" ]] && [[ -s "$today_log" ]]; then
        log_warning "New groups were added today:"
        while read -r group; do
            log_warning "  - $group"
        done < "$today_log"
        
        echo "" | tee -a "$LOG_FILE"
        log_warning "⚠️  IMPORTANT: You must log out and back in for group changes to take effect!"
        log_info "After logging back in, verify with: groups"
        
        # Create a reminder script
        cat > "$HOME/.group-change-reminder" << 'EOF'
#!/bin/bash
echo "🔄 Remember: You added new user groups today."
echo "📝 Verify your groups with: groups"
echo "🗑️  Remove this reminder with: rm ~/.group-change-reminder"
EOF
        chmod +x "$HOME/.group-change-reminder"
        
        log_info "Created reminder script: ~/.group-change-reminder"
    else
        log_success "No new groups added - no logout required"
    fi
}

# Create group management aliases
create_group_aliases() {
    log_info "Creating group management aliases..."
    
    local alias_file="$HOME/.config/fish/functions/groups_info.fish"
    mkdir -p "$(dirname "$alias_file")"
    
    cat > "$alias_file" << 'EOF'
function groups_info
    switch $argv[1]
        case list show
            echo "Current user groups:"
            groups (whoami) | string split ' ' | sort
        case check verify
            echo "Group membership verification:"
            set -l important_groups wheel audio video input storage render media libvirt docker
            for group in $important_groups
                if groups (whoami) | grep -q "\b$group\b"
                    echo "✅ $group"
                else
                    echo "❌ $group (not a member)"
                end
            end
        case media
            echo "Media-related groups:"
            groups (whoami) | string match -r '\b(media|audio|video|render|optical)\b'
        case dev development
            echo "Development-related groups:"
            groups (whoami) | string match -r '\b(wheel|docker|libvirt|kvm|git|builders)\b'
        case hardware hw
            echo "Hardware access groups:"
            groups (whoami) | string match -r '\b(render|video|audio|input|storage|kvm|rfkill)\b'
        case '*'
            echo "Group information commands:"
            echo "  groups_info list      - Show all user groups"
            echo "  groups_info check     - Verify important groups"
            echo "  groups_info media     - Show media groups"
            echo "  groups_info dev       - Show development groups"
            echo "  groups_info hardware  - Show hardware groups"
    end
end
EOF
    
    log_success "Created group management aliases"
}

# Main execution
main() {
    log_section "User Groups Setup"
    log_info "Starting user groups configuration for: $(whoami)"
    log_info "Log file: $LOG_FILE"
    
    check_root
    
    # Show current state
    show_current_groups
    
    # Setup groups
    create_system_groups
    setup_essential_groups
    setup_hardware_groups
    setup_service_groups
    setup_development_groups
    
    # Create management tools
    create_group_aliases
    
    # Final status
    show_current_groups
    check_logout_required
    
    log_success "User groups setup completed!"
    log_info "Check the log file for details: $LOG_FILE"
}

# Run main function
main "$@"