#!/usr/bin/env fish

# Evil Space Dotfiles Repository Cleanup Script
# This script safely removes clutter while preserving important files

set DOTFILES_DIR (pwd)
set LOG_RETENTION_DAYS 30
set BACKUP_DIR "$HOME/.dotfiles-cleanup-backup"

function info
    echo "🔵 $argv"
end

function success
    echo "✅ $argv"
end

function warning
    echo "⚠️  $argv"
end

function error
    echo "❌ $argv"
end

function confirm
    echo -n "🤔 $argv (y/N): "
    read -l response
    test "$response" = "y" -o "$response" = "Y"
end

# Backup important files before cleanup
function create_cleanup_backup
    info "Creating safety backup in $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    # Backup any files we're about to delete
    if test -f starship.toml
        cp starship.toml "$BACKUP_DIR/"
    end
    
    if test -f starship/starship-dynamic.toml.save
        mkdir -p "$BACKUP_DIR/starship"
        cp starship/starship-dynamic.toml.save "$BACKUP_DIR/starship/"
    end
    
    success "Backup created"
end

# Clean up log files
function cleanup_logs
    info "Cleaning up log files older than $LOG_RETENTION_DAYS days..."
    
    if not test -d logs
        warning "No logs directory found"
        return
    end
    
    set old_logs (find logs/ -name "*.log" -mtime +$LOG_RETENTION_DAYS 2>/dev/null)
    
    if test (count $old_logs) -eq 0
        info "No old log files to clean"
        return
    end
    
    echo "Found "(count $old_logs)" old log files:"
    for log in $old_logs
        echo "  - $log"
    end
    
    if confirm "Delete these old log files?"
        for log in $old_logs
            rm -f "$log"
            success "Deleted $log"
        end
    end
    
    # Clean up massive recent logs (>5MB)
    set large_logs (find logs/ -name "*.log" -size +5M 2>/dev/null)
    if test (count $large_logs) -gt 0
        echo "Found "(count $large_logs)" large log files (>5MB):"
        for log in $large_logs
            set size (du -h "$log" | cut -f1)
            echo "  - $log ($size)"
        end
        
        if confirm "Delete these large log files?"
            for log in $large_logs
                rm -f "$log"
                success "Deleted $log"
            end
        end
    end
end

# Remove duplicate and backup files
function cleanup_duplicates
    info "Cleaning up duplicate and backup files..."
    
    # Remove root starship.toml (duplicate of starship/starship.toml)
    if test -f starship.toml
        if confirm "Remove duplicate starship.toml in root? (starship/starship.toml will remain)"
            rm -f starship.toml
            success "Removed duplicate starship.toml"
        end
    end
    
    # Remove .save backup files
    set save_files (find . -name "*.save" -type f 2>/dev/null)
    if test (count $save_files) -gt 0
        echo "Found "(count $save_files)" .save backup files:"
        for file in $save_files
            echo "  - $file"
        end
        
        if confirm "Delete these backup files?"
            for file in $save_files
                rm -f "$file"
                success "Deleted $file"
            end
        end
    end
    
    # Remove other backup files (excluding scripts/backup directory)
    set backup_files (find . -name "*backup*" -name "*.backup" -o -name "*-backup" 2>/dev/null | grep -v "scripts/backup")
    if test (count $backup_files) -gt 0
        echo "Found "(count $backup_files)" other backup files:"
        for file in $backup_files
            echo "  - $file"
        end
        
        if confirm "Delete these backup files?"
            for file in $backup_files
                rm -f "$file"
                success "Deleted $file"
            end
        end
    end
end

# Clean up excessive theme variants
function cleanup_theme_variants
    info "Cleaning up excessive theme variants..."
    
    # Count theme directories
    set theme_count (find themes/ -maxdepth 1 -type d | wc -l)
    echo "Current theme directories: $theme_count"
    
    # List hdpi/xhdpi variants
    set dpi_variants (find themes/ -maxdepth 1 -type d -name "*-hdpi" -o -name "*-xhdpi" 2>/dev/null)
    
    if test (count $dpi_variants) -gt 0
        echo "Found "(count $dpi_variants)" DPI variant themes:"
        for theme in $dpi_variants
            echo "  - $theme"
        end
        
        warning "DPI variants are rarely needed unless you have specific high-DPI displays"
        if confirm "Remove DPI variant themes? (Keep only standard versions)"
            for theme in $dpi_variants
                rm -rf "$theme"
                success "Removed $theme"
            end
        end
    end
    
    # List compact variants
    set compact_variants (find themes/ -maxdepth 1 -type d -name "*-Compact*" 2>/dev/null)
    
    if test (count $compact_variants) -gt 0
        echo "Found "(count $compact_variants)" Compact variant themes:"
        for theme in $compact_variants
            echo "  - $theme"
        end
        
        if confirm "Remove Compact variant themes? (Keep only standard versions)"
            for theme in $compact_variants
                rm -rf "$theme"
                success "Removed $theme"
            end
        end
    end
end

# Clean up research documentation
function cleanup_research_docs
    info "Cleaning up old research documentation..."
    
    if not test -d docs/research
        return
    end
    
    set research_files (find docs/research -name "*.md" -type f)
    if test (count $research_files) -gt 0
        echo "Found "(count $research_files)" research documents:"
        for file in $research_files
            echo "  - $file"
        end
        
        warning "These are research documents that might be outdated"
        if confirm "Archive research documents to a single compressed file?"
            set archive_name "docs/archived-research-"(date +%Y%m%d)".tar.gz"
            tar -czf "$archive_name" docs/research/
            success "Archived research to: $archive_name"
            
            if confirm "Remove original research directory?"
                rm -rf docs/research/
                success "Removed docs/research directory"
            end
        end
    end
end

# Show space savings
function show_space_savings
    info "Repository cleanup complete!"
    
    set current_size (du -sh . | cut -f1)
    echo "Current repository size: $current_size"
    
    success "Cleanup completed successfully"
    warning "Safety backup available at: $BACKUP_DIR"
    info "You can remove the backup once you're satisfied with the cleanup"
    
    # Show what was preserved
    echo ""
    info "🔒 Preserved integrated components:"
    echo "  • Fuzzel launcher - Integrated with Hyprland keybinds and theming"
    echo "  • dashboard/ - Integrated with system monitoring and theming API"
    echo "  • nixos-migration/ - Active migration project"
    echo "  • unified-theming-migration/ - Active migration project"
end

# Main cleanup function
function main
    echo "🧹 Evil Space Dotfiles Repository Cleanup"
    echo "========================================"
    
    if not test (basename (pwd)) = "dotfiles"
        error "Please run this script from your dotfiles directory"
        exit 1
    end
    
    warning "This script will clean up clutter in your dotfiles repository"
    warning "A safety backup will be created before any changes"
    info ""
    info "🔍 Analysis shows that fuzzel launcher and dashboard/ are deeply"
    info "    integrated with your dotfiles system and should remain in this repo."
    
    if not confirm "Continue with cleanup?"
        info "Cleanup cancelled"
        exit 0
    end
    
    create_cleanup_backup
    cleanup_logs
    cleanup_duplicates
    cleanup_theme_variants
    cleanup_research_docs
    show_space_savings
end

# Run main function
main $argv 