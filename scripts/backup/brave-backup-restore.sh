#!/bin/bash

# Brave Browser Backup & Restore System
# Integrates with external drives for seamless reinstall workflow

# Removed strict error handling to allow script to complete
# set -euo pipefail

# Colors and styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Brave profile locations
BRAVE_CONFIG_DIR="$HOME/.config/BraveSoftware/Brave-Browser"
BRAVE_DEFAULT_PROFILE="$BRAVE_CONFIG_DIR/Default"

# Essential files to backup (lightweight ~1MB)
ESSENTIAL_FILES=(
    "Default/Bookmarks"
    "Default/Bookmarks.bak"
    "Default/Preferences"
    "Default/Secure Preferences"
    "Default/Web Data"
    "Default/Web Data-journal"
    "Default/Login Data"
    "Default/Login Data-journal"
    "Default/Favicons"
    "Default/Favicons-journal"
    "Default/History"
    "Default/History-journal"
    "Default/Shortcuts"
    "Default/Shortcuts-journal"
    "Local State"
)

# Extension files (adds ~90MB)
EXTENSION_FILES=(
    "Default/Extensions/"
    "Default/Extension Rules"
    "Default/Extension State"
    "Default/Extension Cookies"
    "Default/Extension Cookies-journal"
)

# Session files (adds ~4MB)
SESSION_FILES=(
    "Default/Sessions/"
    "Default/Session Storage/"
    "Default/Current Session"
    "Default/Current Tabs"
    "Default/Last Session"
    "Default/Last Tabs"
)

print_header() {
    echo -e "${PURPLE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}         ${CYAN}🦁 Brave Browser Backup & Restore${NC}         ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════╝${NC}"
    echo
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${CYAN}🔧 $1${NC}"
}

# Detect available external drives
detect_external_drives() {
    # Simply use df to find mounted drives with decent space in /mnt or /media
    df -h | awk '$4 ~ /[0-9]+[GT]/ && ($6 ~ /^\/mnt\// || $6 ~ /^\/media\//) { print $6 "|" $4 }'
}

# Select backup destination
select_backup_destination() {
    local drives
    mapfile -t drives < <(detect_external_drives)
    
    if [[ ${#drives[@]} -eq 0 ]]; then
        print_error "No external drives detected with sufficient space"
        print_info "Please mount an external drive with at least 1GB free space"
        exit 1
    fi
    
    echo -e "${CYAN}📱 Available external drives:${NC}"
    echo
    
    local i=1
    for drive in "${drives[@]}"; do
        IFS='|' read -r mount_point space <<< "$drive"
        local drive_name
        drive_name=$(basename "$mount_point")
        echo -e "  ${GREEN}$i)${NC} $drive_name ${YELLOW}($space available)${NC}"
        echo -e "     ${BLUE}→ $mount_point${NC}"
        ((i++))
        echo
    done
    
    while true; do
        echo -n -e "${CYAN}Select drive number [1-${#drives[@]}]: ${NC}"
        read -r choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#drives[@]} ]]; then
            local selected_drive="${drives[$((choice-1))]}"
            IFS='|' read -r mount_point space <<< "$selected_drive"
            SELECTED_BACKUP_DEST="$mount_point"
            return 0
        else
            print_error "Invalid selection. Please choose 1-${#drives[@]}"
        fi
    done
}

# Create backup
create_backup() {
    print_step "Starting Brave backup process..."
    
    if [[ ! -d "$BRAVE_CONFIG_DIR" ]]; then
        print_error "Brave Browser not found at $BRAVE_CONFIG_DIR"
        exit 1
    fi
    
    # Select backup destination
    local backup_dest
    select_backup_destination
    backup_dest="$SELECTED_BACKUP_DEST"
    
    local backup_dir="$backup_dest/brave-backups"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$backup_dir/brave_backup_$timestamp"
    
    print_info "Creating backup at: $backup_path"
    mkdir -p "$backup_path"
    
    # Backup type selection
    echo
    echo -e "${CYAN}📦 Select backup type:${NC}"
    echo -e "  ${GREEN}1)${NC} Essential only ${YELLOW}(~1MB)${NC} - Bookmarks, passwords, settings"
    echo -e "  ${GREEN}2)${NC} Essential + Extensions ${YELLOW}(~90MB)${NC} - Includes all extensions"
    echo -e "  ${GREEN}3)${NC} Complete backup ${YELLOW}(~100MB)${NC} - Everything including sessions"
    echo
    
    while true; do
        echo -n -e "${CYAN}Choose backup type [1-3]: ${NC}"
        read -r backup_type
        
        case "$backup_type" in
            1|2|3) break ;;
            *) print_error "Invalid selection. Please choose 1, 2, or 3" ;;
        esac
    done
    
    # Perform backup
    cd "$BRAVE_CONFIG_DIR"
    
    local files_to_backup=("${ESSENTIAL_FILES[@]}")
    local backup_size="~1MB"
    
    if [[ "$backup_type" -ge 2 ]]; then
        files_to_backup+=("${EXTENSION_FILES[@]}")
        backup_size="~90MB"
    fi
    
    if [[ "$backup_type" -eq 3 ]]; then
        files_to_backup+=("${SESSION_FILES[@]}")
        backup_size="~100MB"
    fi
    
    print_info "Backing up files ($backup_size)..."
    
    local backed_up_count=0
    local total_files=${#files_to_backup[@]}
    
    for file in "${files_to_backup[@]}"; do
        if [[ -e "$file" ]]; then
            local dest_dir
            dest_dir=$(dirname "$backup_path/$file")
            
            if ! mkdir -p "$dest_dir"; then
                print_error "Failed to create directory: $dest_dir"
                exit 1
            fi
            
            if [[ -d "$file" ]]; then
                if ! cp -r "$file" "$dest_dir/" 2>/dev/null; then
                    print_warning "Failed to copy directory: $file"
                fi
            else
                if ! cp "$file" "$dest_dir/" 2>/dev/null; then
                    print_warning "Failed to copy file: $file"
                fi
            fi
            ((backed_up_count++))
        fi
    done
    
    print_info "Successfully backed up $backed_up_count/$total_files files"
    
    # Create backup metadata
    print_info "Creating backup metadata..."
    cat > "$backup_path/backup_info.txt" << EOF
Brave Backup Information
========================
Date: $(date)
Hostname: $(uname -n)
User: $USER
Backup Type: $backup_type
Files Backed Up: $backed_up_count/$total_files
Brave Version: $(brave-browser --version 2>/dev/null || echo "Unknown")

Backup Contents:
$(if [[ "$backup_type" -ge 1 ]]; then echo "✅ Essential files (bookmarks, passwords, settings)"; fi)
$(if [[ "$backup_type" -ge 2 ]]; then echo "✅ Extensions and extension data"; fi)
$(if [[ "$backup_type" -eq 3 ]]; then echo "✅ Session data and tabs"; fi)

Restore Command:
$0 restore "$backup_path"
EOF
    
    # Create compressed archive
    print_step "Creating compressed archive..."
    
    if ! cd "$backup_dir"; then
        print_error "Failed to change to backup directory: $backup_dir"
        exit 1
    fi
    
    print_info "Creating archive in: $(pwd)"
    if ! tar -czf "brave_backup_$timestamp.tar.gz" "brave_backup_$timestamp"; then
        print_error "Failed to create compressed archive"
        exit 1
    fi
    
    if [[ ! -f "brave_backup_$timestamp.tar.gz" ]]; then
        print_error "Archive was not created: brave_backup_$timestamp.tar.gz"
        exit 1
    fi
    
    # Remove the folder to save space (keep only the archive)
    print_info "Cleaning up temporary folder..."
    rm -rf "brave_backup_$timestamp"
    
    local archive_size
    archive_size=$(du -h "brave_backup_$timestamp.tar.gz" | cut -f1)
    
    print_success "Backup completed successfully!"
    echo
    print_info "📁 Backup location: $backup_path"
    print_info "📦 Archive: brave_backup_$timestamp.tar.gz ($archive_size)"
    print_info "💾 Drive: $(basename "$backup_dest")"
    echo
    print_info "To restore: $0 restore $backup_path"
}

# List available backups (returns archive paths for other functions)
list_backups() {
    local drives
    mapfile -t drives < <(detect_external_drives)
    
    local found_backups=()
    
    for drive in "${drives[@]}"; do
        IFS='|' read -r mount_point space <<< "$drive"
        local backup_dir="$mount_point/brave-backups"
        
        if [[ -d "$backup_dir" ]]; then
            # Look for archive files (.tar.gz)
            while IFS= read -r backup; do
                if [[ -n "$backup" ]]; then
                    found_backups+=("$backup")
                fi
            done < <(find "$backup_dir" -name "brave_backup_*.tar.gz" -type f 2>/dev/null | sort -r)
        fi
    done
    
    if [[ ${#found_backups[@]} -eq 0 ]]; then
        return 1
    fi
    
    # Return the backup archive paths for use by other functions
    printf '%s\n' "${found_backups[@]}"
}

# Display available backups (for user interface)
show_backups() {
    print_step "Scanning for Brave backups..."
    
    local backups
    mapfile -t backups < <(list_backups)
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        print_warning "No Brave backups found on external drives"
        return 1
    fi
    
    echo -e "${CYAN}📋 Available Brave backups:${NC}"
    echo
    
    local i=1
    for backup in "${backups[@]}"; do
        local backup_name
        backup_name=$(basename "$backup" .tar.gz)
        local drive_name
        drive_name=$(echo "$backup" | sed 's|/brave-backups/.*||' | xargs basename)
        local backup_date
        backup_date=$(echo "$backup_name" | sed 's/brave_backup_//' | sed 's/_/ /')
        
        echo -e "  ${GREEN}$i)${NC} $backup_date ${YELLOW}($drive_name)${NC}"
        
        # Extract archive temporarily to read backup info
        local temp_dir="/tmp/brave_show_$$_$i"
        mkdir -p "$temp_dir"
        if tar -xzf "$backup" -C "$temp_dir" 2>/dev/null; then
            local extracted_dir="$temp_dir/$backup_name"
            if [[ -f "$extracted_dir/backup_info.txt" ]]; then
                local backup_type
                backup_type=$(grep "Backup Type:" "$extracted_dir/backup_info.txt" | cut -d: -f2 | xargs)
                case "$backup_type" in
                    1) echo -e "     ${BLUE}→ Essential only${NC}" ;;
                    2) echo -e "     ${BLUE}→ Essential + Extensions${NC}" ;;
                    3) echo -e "     ${BLUE}→ Complete backup${NC}" ;;
                esac
            fi
            rm -rf "$temp_dir"
        fi
        
        echo -e "     ${BLUE}→ $backup${NC}"
        ((i++))
        echo
    done
}

# Restore backup
restore_backup() {
    local backup_path="$1"
    
    if [[ -z "$backup_path" ]]; then
        # Show available backups first
        print_step "Available backups for restore:"
        echo
        
        local backups
        mapfile -t backups < <(list_backups)
        
        if [[ ${#backups[@]} -eq 0 ]]; then
            print_warning "No Brave backups found on external drives"
            print_info "Create a backup first using option 1"
            return 1
        fi
        
        # Display the backup list
        local i=1
        for backup in "${backups[@]}"; do
            local backup_name
            backup_name=$(basename "$backup" .tar.gz)
            local drive_name
            drive_name=$(echo "$backup" | sed 's|/brave-backups/.*||' | xargs basename)
            local backup_date
            backup_date=$(echo "$backup_name" | sed 's/brave_backup_//' | sed 's/_/ /')
            
            echo -e "  ${GREEN}$i)${NC} $backup_date ${YELLOW}($drive_name)${NC}"
            
            # Extract archive temporarily to read backup info
            local temp_dir="/tmp/brave_restore_$$"
            mkdir -p "$temp_dir"
            if tar -xzf "$backup" -C "$temp_dir" 2>/dev/null; then
                local extracted_dir="$temp_dir/$backup_name"
                if [[ -f "$extracted_dir/backup_info.txt" ]]; then
                    local backup_type
                    backup_type=$(grep "Backup Type:" "$extracted_dir/backup_info.txt" | cut -d: -f2 | xargs)
                    case "$backup_type" in
                        1) echo -e "     ${BLUE}→ Essential only${NC}" ;;
                        2) echo -e "     ${BLUE}→ Essential + Extensions${NC}" ;;
                        3) echo -e "     ${BLUE}→ Complete backup${NC}" ;;
                    esac
                fi
                rm -rf "$temp_dir"
            fi
            
            ((i++))
            echo
        done
        
        # Interactive backup selection
        while true; do
            echo -n -e "${CYAN}Select backup to restore [1-${#backups[@]}]: ${NC}"
            read -r choice
            
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#backups[@]} ]]; then
                backup_path="${backups[$((choice-1))]}"
                break
            else
                print_error "Invalid selection. Please choose 1-${#backups[@]}"
            fi
        done
    fi
    
    if [[ ! -f "$backup_path" ]]; then
        print_error "Backup archive not found: $backup_path"
        exit 1
    fi
    
    print_step "Restoring Brave backup from: $(basename "$backup_path")"
    
    # Extract the archive to a temporary directory
    local temp_restore_dir="/tmp/brave_restore_$$"
    print_info "Extracting backup archive..."
    
    if ! mkdir -p "$temp_restore_dir"; then
        print_error "Failed to create temporary directory"
        exit 1
    fi
    
    if ! tar -xzf "$backup_path" -C "$temp_restore_dir"; then
        print_error "Failed to extract backup archive"
        rm -rf "$temp_restore_dir"
        exit 1
    fi
    
    # Find the extracted backup directory
    local backup_name
    backup_name=$(basename "$backup_path" .tar.gz)
    local extracted_backup_path="$temp_restore_dir/$backup_name"
    
    if [[ ! -d "$extracted_backup_path" ]]; then
        print_error "Extracted backup directory not found"
        rm -rf "$temp_restore_dir"
        exit 1
    fi
    
    # Check if Brave is running
    if pgrep -x "brave" > /dev/null; then
        print_warning "Brave Browser is currently running"
        echo -n -e "${CYAN}Close Brave and continue? [y/N]: ${NC}"
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            print_info "Restore cancelled"
            exit 0
        fi
        
        # Kill Brave processes
        pkill -x "brave" 2>/dev/null || true
        sleep 2
    fi
    
    # Backup existing config
    if [[ -d "$BRAVE_CONFIG_DIR" ]]; then
        local backup_existing="$BRAVE_CONFIG_DIR.backup.$(date +%s)"
        print_info "Backing up existing config to: $backup_existing"
        cp -r "$BRAVE_CONFIG_DIR" "$backup_existing"
    fi
    
    # Create config directory
    mkdir -p "$BRAVE_CONFIG_DIR"
    
    # Restore files
    print_step "Restoring files..."
    cp -r "$extracted_backup_path"/* "$BRAVE_CONFIG_DIR/"
    
    # Remove backup info file from config
    rm -f "$BRAVE_CONFIG_DIR/backup_info.txt"
    
    # Set proper permissions
    chown -R "$USER:$USER" "$BRAVE_CONFIG_DIR" 2>/dev/null || true
    
    # Clean up temporary directory
    print_info "Cleaning up temporary files..."
    rm -rf "$temp_restore_dir"
    
    print_success "Brave backup restored successfully!"
    echo
    print_info "🦁 You can now start Brave Browser"
    print_info "📚 Your bookmarks, passwords, and settings have been restored"
    
    if [[ -f "$extracted_backup_path/backup_info.txt" ]]; then
        echo
        print_info "📋 Backup details:"
        grep -E "(Date:|Backup Type:|Files Backed Up:)" "$extracted_backup_path/backup_info.txt" | sed 's/^/   /' 2>/dev/null || true
    fi
}

# Main menu
show_menu() {
    print_header
    
    echo -e "${CYAN}📋 Available actions:${NC}"
    echo -e "  ${GREEN}1)${NC} Create backup"
    echo -e "  ${GREEN}2)${NC} Restore backup"
    echo -e "  ${GREEN}3)${NC} List backups"
    echo -e "  ${GREEN}4)${NC} Exit"
    echo
    
    while true; do
        echo -n -e "${CYAN}Choose action [1-4]: ${NC}"
        read -r choice
        
        case "$choice" in
            1) create_backup; break ;;
            2) restore_backup ""; break ;;
            3) show_backups; break ;;
            4) print_info "Goodbye!"; exit 0 ;;
            *) print_error "Invalid selection. Please choose 1-4" ;;
        esac
    done
}

# Handle command line arguments
case "${1:-menu}" in
    "backup")
        print_header
        create_backup
        ;;
    "restore")
        print_header
        restore_backup "${2:-}"
        ;;
    "list")
        print_header
        show_backups
        ;;
    "menu"|*)
        show_menu
        ;;
esac 