#!/bin/bash
# Smart Brave Browser Backup Script
# Backs up only essential files, not huge cache/temp data

set -e

BACKUP_DIR="$HOME/brave-backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="brave-essential-$DATE"
BRAVE_PROFILE="$HOME/.config/BraveSoftware/Brave-Browser/Default"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Essential files to backup (small, important data only)
ESSENTIAL_FILES=(
    "Bookmarks"                    # Bookmarks
    "Bookmarks.bak"               # Bookmark backup
    "Preferences"                 # All browser settings
    "Local State"                 # Global preferences
    "Web Data"                    # Form fill data
    "Login Data"                  # Saved passwords (encrypted)
    "Login Data-journal"          # Password database journal
    "Favicons"                    # Website icons
    "Favicons-journal"            # Favicon database journal
    "Extension Cookies"           # Extension data
    "Extension Cookies-journal"   # Extension cookies journal
    "Secure Preferences"          # Secure settings
    "TransportSecurity"           # HTTPS security data
    "Local Extension Settings"    # Extension settings (folder)
    "Extensions"                  # Installed extensions (folder)
    "Extension State"             # Extension state data
)

# Optional files (larger, but sometimes useful)
OPTIONAL_FILES=(
    "Current Session"             # Open tabs (~few KB)
    "Current Tabs"               # Tab state (~few KB)
    "Last Session"               # Previous session (~few KB)
    "Last Tabs"                  # Previous tabs (~few KB)
    "Sessions"                   # Session folder (small)
)

backup_essential() {
    print_info "Creating essential Brave backup..."
    
    # Check if Brave profile exists
    if [[ ! -d "$BRAVE_PROFILE" ]]; then
        print_error "Brave profile not found at: $BRAVE_PROFILE"
        print_info "Make sure Brave is installed and has been run at least once"
        exit 1
    fi
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR/$BACKUP_NAME"
    
    local total_size=0
    local file_count=0
    
    print_info "Backing up essential files..."
    
    # Backup essential files
    for file in "${ESSENTIAL_FILES[@]}"; do
        local source_path="$BRAVE_PROFILE/$file"
        local dest_path="$BACKUP_DIR/$BACKUP_NAME/$file"
        
        if [[ -e "$source_path" ]]; then
            if [[ -d "$source_path" ]]; then
                # It's a directory
                cp -r "$source_path" "$dest_path"
                local size=$(du -sb "$dest_path" | cut -f1)
            else
                # It's a file
                cp "$source_path" "$dest_path"
                local size=$(stat -f%z "$dest_path" 2>/dev/null || stat -c%s "$dest_path")
            fi
            
            total_size=$((total_size + size))
            file_count=$((file_count + 1))
            print_success "  ✓ $file ($(numfmt --to=iec $size))"
        else
            print_warning "  ⚠ $file (not found)"
        fi
    done
    
    # Ask about optional files
    echo
    print_info "Optional files (session data - small but useful for tab restoration):"
    if command -v gum >/dev/null 2>&1; then
        if gum confirm "Include session data (open tabs, etc.)?"; then
            include_sessions=true
        else
            include_sessions=false
        fi
    else
        read -p "Include session data? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            include_sessions=true
        else
            include_sessions=false
        fi
    fi
    
    if [[ "$include_sessions" == "true" ]]; then
        for file in "${OPTIONAL_FILES[@]}"; do
            local source_path="$BRAVE_PROFILE/$file"
            local dest_path="$BACKUP_DIR/$BACKUP_NAME/$file"
            
            if [[ -e "$source_path" ]]; then
                if [[ -d "$source_path" ]]; then
                    cp -r "$source_path" "$dest_path"
                    local size=$(du -sb "$dest_path" | cut -f1)
                else
                    cp "$source_path" "$dest_path"
                    local size=$(stat -f%z "$dest_path" 2>/dev/null || stat -c%s "$dest_path")
                fi
                
                total_size=$((total_size + size))
                file_count=$((file_count + 1))
                print_success "  ✓ $file ($(numfmt --to=iec $size))"
            fi
        done
    fi
    
    # Create backup info file
    cat > "$BACKUP_DIR/$BACKUP_NAME/BACKUP_INFO.txt" << EOF
Brave Browser Essential Backup
Created: $(date)
Files backed up: $file_count
Total size: $(numfmt --to=iec $total_size)
Source: $BRAVE_PROFILE
Backup type: Essential files only (no cache/history)

To restore:
1. Close Brave completely
2. Backup current profile: mv ~/.config/BraveSoftware/Brave-Browser/Default ~/.config/BraveSoftware/Brave-Browser/Default.backup
3. Create new profile directory: mkdir -p ~/.config/BraveSoftware/Brave-Browser/Default
4. Copy files: cp -r $BACKUP_DIR/$BACKUP_NAME/* ~/.config/BraveSoftware/Brave-Browser/Default/
5. Start Brave

Note: Extensions may need to be re-enabled in brave://extensions/
EOF
    
    # Compress backup
    print_info "Compressing backup..."
    cd "$BACKUP_DIR"
    tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME"
    rm -rf "$BACKUP_NAME"
    
    local compressed_size=$(stat -f%z "$BACKUP_NAME.tar.gz" 2>/dev/null || stat -c%s "$BACKUP_NAME.tar.gz")
    
    print_success "Backup completed!"
    print_info "Location: $BACKUP_DIR/$BACKUP_NAME.tar.gz"
    print_info "Size: $(numfmt --to=iec $compressed_size) (vs ~1-3GB for full profile)"
    print_info "Files: $file_count essential files"
}

restore_backup() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        print_error "Please specify backup file to restore"
        print_info "Usage: $0 restore /path/to/backup.tar.gz"
        exit 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        print_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    print_warning "This will replace your current Brave profile!"
    print_info "Current profile will be backed up to: $BRAVE_PROFILE.backup.$(date +%Y%m%d_%H%M%S)"
    
    if command -v gum >/dev/null 2>&1; then
        if ! gum confirm "Continue with restore?"; then
            print_info "Restore cancelled"
            exit 0
        fi
    else
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Restore cancelled"
            exit 0
        fi
    fi
    
    # Check if Brave is running
    if pgrep -x "brave" > /dev/null; then
        print_error "Brave is currently running. Please close it first."
        exit 1
    fi
    
    # Backup current profile
    if [[ -d "$BRAVE_PROFILE" ]]; then
        local backup_name="$BRAVE_PROFILE.backup.$(date +%Y%m%d_%H%M%S)"
        mv "$BRAVE_PROFILE" "$backup_name"
        print_success "Current profile backed up to: $backup_name"
    fi
    
    # Create profile directory
    mkdir -p "$BRAVE_PROFILE"
    
    # Extract and restore
    print_info "Restoring backup..."
    local temp_dir=$(mktemp -d)
    tar -xzf "$backup_file" -C "$temp_dir"
    
    # Find the backup directory (should be only one)
    local backup_dir=$(find "$temp_dir" -maxdepth 1 -type d -name "brave-essential-*" | head -n 1)
    
    if [[ -z "$backup_dir" ]]; then
        print_error "Invalid backup file format"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Copy files
    cp -r "$backup_dir"/* "$BRAVE_PROFILE/"
    rm -rf "$temp_dir"
    
    print_success "Restore completed!"
    print_info "You can now start Brave"
    print_warning "Note: Extensions may need to be re-enabled in brave://extensions/"
}

list_backups() {
    print_info "Available backups in $BACKUP_DIR:"
    echo
    
    if [[ ! -d "$BACKUP_DIR" ]]; then
        print_warning "No backup directory found"
        return
    fi
    
    local backups=($(find "$BACKUP_DIR" -name "brave-essential-*.tar.gz" -type f | sort -r))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        print_warning "No backups found"
        return
    fi
    
    for backup in "${backups[@]}"; do
        local filename=$(basename "$backup")
        local size=$(stat -f%z "$backup" 2>/dev/null || stat -c%s "$backup")
        local date=$(echo "$filename" | sed 's/brave-essential-\(.*\)\.tar\.gz/\1/' | sed 's/_/ /')
        
        echo "📦 $filename"
        echo "   Size: $(numfmt --to=iec $size)"
        echo "   Date: $date"
        echo
    done
}

show_help() {
    echo "Smart Brave Browser Backup Tool"
    echo
    echo "Usage:"
    echo "  $0 backup                    - Create essential backup"
    echo "  $0 restore <backup.tar.gz>   - Restore from backup"
    echo "  $0 list                      - List available backups"
    echo "  $0 help                      - Show this help"
    echo
    echo "Features:"
    echo "  • Backs up only essential files (~5-50MB vs 1-3GB full profile)"
    echo "  • Preserves bookmarks, passwords, settings, extensions"
    echo "  • Excludes cache, history, temporary files"
    echo "  • Compressed backups for easy storage"
    echo
    echo "Backup location: $BACKUP_DIR"
}

# Main script logic
case "${1:-backup}" in
    "backup"|"b")
        backup_essential
        ;;
    "restore"|"r")
        restore_backup "$2"
        ;;
    "list"|"l")
        list_backups
        ;;
    "help"|"h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac 