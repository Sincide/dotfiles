#!/bin/bash

# Storage Setup Script
# Configures automatic mounting for additional drives and storage

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/storage-setup_$(date +%Y%m%d_%H%M%S).log"

# CLI flags
DRY_RUN=false
SKIP_CONFIRMATION=false
AUTO_DETECT=true

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
            --no-auto-detect)
                AUTO_DETECT=false
                log_info "Disabling auto-detection"
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
Storage Setup Script

This script configures automatic mounting for additional drives.

Usage: $0 [OPTIONS]

Options:
    --dry-run           Show what would be done without making changes
    --yes               Skip confirmation prompts
    --no-auto-detect    Disable automatic drive detection
    --help, -h          Show this help message

Examples:
    $0                  Interactive setup with auto-detection
    $0 --dry-run        Preview changes without applying them
    $0 --yes            Automated setup without prompts

EOF
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi
}

# Detect available drives and their information
detect_drives() {
    log_info "Detecting available drives..."
    
    # Get all block devices that are disks and not mounted on /
    mapfile -t drives < <(lsblk -no NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT | grep -E "^sd[a-z]|^nvme[0-9]n[0-9]" | grep -v "/$")
    
    if [[ ${#drives[@]} -eq 0 ]]; then
        log_warning "No unmounted drives detected"
        return 1
    fi
    
    log_info "Found ${#drives[@]} potential drives:"
    for drive in "${drives[@]}"; do
        log_info "  $drive"
    done
}

# Show current storage status
show_storage_status() {
    log_section "Current Storage Status"
    
    log_info "Currently mounted filesystems:"
    df -h | grep -E "(^/dev|Size)" | while read -r line; do
        log_info "  $line"
    done
    
    log_info ""
    log_info "Available block devices:"
    lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT | while read -r line; do
        log_info "  $line"
    done
}

# Check if drive is already configured in fstab
is_drive_in_fstab() {
    local device="$1"
    grep -q "$device" /etc/fstab 2>/dev/null
}

# Get drive label or UUID
get_drive_identifier() {
    local device="$1"
    
    # Try to get LABEL first
    local label
    label=$(lsblk -no LABEL "/dev/$device" 2>/dev/null | head -1)
    if [[ -n "$label" ]]; then
        echo "LABEL=$label"
        return 0
    fi
    
    # Fall back to UUID
    local uuid
    uuid=$(lsblk -no UUID "/dev/$device" 2>/dev/null | head -1)
    if [[ -n "$uuid" ]]; then
        echo "UUID=$uuid"
        return 0
    fi
    
    # Last resort: device path
    echo "/dev/$device"
}

# Setup common mount points
setup_mount_points() {
    log_info "Setting up common mount points..."
    
    local mount_points=(
        "/mnt/Media"
        "/mnt/Stuff"
        "/mnt/Storage"
        "/mnt/Backup"
    )
    
    for mount_point in "${mount_points[@]}"; do
        if [[ ! -d "$mount_point" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                log_info "[DRY RUN] Would create: $mount_point"
            else
                sudo mkdir -p "$mount_point"
                log_success "Created mount point: $mount_point"
            fi
        else
            log_info "Mount point already exists: $mount_point"
        fi
    done
}

# Configure drive for automatic mounting
configure_drive_mount() {
    local device="$1"
    local mount_point="$2"
    local filesystem="$3"
    local label="$4"
    
    log_info "Configuring $device for automatic mounting..."
    
    # Get device identifier
    local identifier
    identifier=$(get_drive_identifier "$device")
    
    # Check if already in fstab
    if is_drive_in_fstab "$identifier"; then
        log_warning "$identifier is already configured in fstab"
        return 0
    fi
    
    # Determine mount options based on filesystem
    local mount_options="nosuid,nodev,nofail,x-gvfs-show"
    case "$filesystem" in
        ntfs)
            mount_options="$mount_options,uid=1000,gid=1000,umask=022"
            ;;
        vfat|fat32)
            mount_options="$mount_options,uid=1000,gid=1000,umask=022"
            ;;
        ext4|btrfs|xfs)
            mount_options="$mount_options"
            ;;
    esac
    
    # Create fstab entry
    local fstab_entry="$identifier $mount_point auto $mount_options 0 0"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would add to /etc/fstab: $fstab_entry"
    else
        # Backup fstab
        sudo cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d_%H%M%S)
        
        # Add entry to fstab
        echo "$fstab_entry" | sudo tee -a /etc/fstab >/dev/null
        log_success "Added to fstab: $fstab_entry"
        
        # Test mount
        if sudo mount "$mount_point" 2>/dev/null; then
            log_success "Successfully mounted $device at $mount_point"
        else
            log_warning "Failed to mount $device. Check configuration manually."
        fi
    fi
}

# Interactive drive configuration
interactive_setup() {
    log_section "Interactive Storage Setup"
    
    if ! detect_drives; then
        log_info "No additional drives to configure"
        return 0
    fi
    
    log_info "Setting up automatic mounting for detected drives..."
    
    # Common drive configurations based on your current setup
    local known_configs=(
        "Media:/mnt/Media:1.8T"
        "Stuff:/mnt/Stuff:3.6T"
    )
    
    # Check for drives with known labels
    for device in $(lsblk -no NAME,LABEL | grep -E "Media|Stuff" | cut -d' ' -f1); do
        local label
        label=$(lsblk -no LABEL "/dev/$device" 2>/dev/null)
        local filesystem
        filesystem=$(lsblk -no FSTYPE "/dev/$device" 2>/dev/null)
        
        case "$label" in
            "Media")
                configure_drive_mount "$device" "/mnt/Media" "$filesystem" "$label"
                ;;
            "Stuff")
                configure_drive_mount "$device" "/mnt/Stuff" "$filesystem" "$label"
                ;;
        esac
    done
}

# Setup storage-related groups and permissions
setup_storage_permissions() {
    log_info "Setting up storage permissions..."
    
    # Ensure user is in appropriate groups
    local storage_groups=("disk" "storage")
    
    for group in "${storage_groups[@]}"; do
        if getent group "$group" >/dev/null 2>&1; then
            if ! groups "$(whoami)" | grep -q "\b$group\b"; then
                if [[ "$DRY_RUN" == "true" ]]; then
                    log_info "[DRY RUN] Would add $(whoami) to $group group"
                else
                    sudo usermod -a -G "$group" "$(whoami)"
                    log_success "Added $(whoami) to $group group"
                fi
            else
                log_info "$(whoami) is already in $group group"
            fi
        fi
    done
}

# Create storage management aliases
create_storage_aliases() {
    log_info "Creating storage management aliases..."
    
    local alias_file="$HOME/.config/fish/functions/storage.fish"
    mkdir -p "$(dirname "$alias_file")"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would create storage management aliases"
        return 0
    fi
    
    cat > "$alias_file" << 'EOF'
function storage
    switch $argv[1]
        case list ls
            echo "Mounted storage devices:"
            df -h | grep -E "/mnt|/media"
        case usage space
            echo "Storage usage summary:"
            df -h --total | tail -n 1
            echo ""
            echo "Per-device usage:"
            df -h | grep -E "/mnt|/media" | while read -r line
                echo "  $line"
            end
        case mounts
            echo "All mount points:"
            mount | grep -E "/mnt|/media"
        case fstab
            echo "Storage entries in fstab:"
            grep -E "/mnt|/media" /etc/fstab
        case health check
            echo "Storage health check:"
            for mount in /mnt/*
                if mountpoint -q "$mount"
                    echo "✅ $mount is mounted"
                else
                    echo "❌ $mount is not mounted"
                end
            end
        case remount
            echo "Remounting all storage devices..."
            sudo mount -a
        case '*'
            echo "Storage management commands:"
            echo "  storage list      - Show mounted storage"
            echo "  storage usage     - Show storage usage"
            echo "  storage mounts    - Show all mounts"
            echo "  storage fstab     - Show fstab entries"
            echo "  storage health    - Check mount status"
            echo "  storage remount   - Remount all devices"
    end
end
EOF
    
    log_success "Created storage management aliases"
}

# Show final storage configuration
show_final_config() {
    log_section "Storage Configuration Summary"
    
    log_info "Configured mount points:"
    if [[ -f /etc/fstab ]]; then
        grep -E "/mnt|/media" /etc/fstab | while read -r line; do
            log_info "  $line"
        done
    fi
    
    log_info ""
    log_info "Currently mounted storage:"
    df -h | grep -E "/mnt|/media" | while read -r line; do
        log_info "  $line"
    done || log_info "  No additional storage currently mounted"
    
    log_info ""
    log_info "Storage management:"
    log_info "  View usage:    storage usage"
    log_info "  Check health:  storage health"
    log_info "  Remount all:   storage remount"
    log_info "  Manual mount:  sudo mount /mnt/Media"
    
    if [[ "$DRY_RUN" == "false" ]]; then
        if groups "$(whoami)" | grep -q "disk\|storage"; then
            log_success "✅ User has storage access permissions"
        else
            log_warning "⚠️  Log out and back in for group changes to take effect"
        fi
    fi
}

# Main execution
main() {
    log_section "Storage Setup"
    log_info "Starting storage setup for user: $(whoami)"
    log_info "Log file: $LOG_FILE"
    
    check_root
    show_storage_status
    
    if [[ "$SKIP_CONFIRMATION" == "false" && "$DRY_RUN" == "false" ]]; then
        echo ""
        read -p "Do you want to proceed with storage setup? [y/N]: " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Storage setup cancelled by user"
            exit 0
        fi
    fi
    
    setup_mount_points
    
    if [[ "$AUTO_DETECT" == "true" ]]; then
        interactive_setup
    fi
    
    setup_storage_permissions
    create_storage_aliases
    show_final_config
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Dry run completed. Use without --dry-run to apply changes."
    else
        log_success "Storage setup completed successfully!"
    fi
    
    log_info "Check the log file for details: $LOG_FILE"
}

# Parse arguments and run main function
parse_args "$@"
main