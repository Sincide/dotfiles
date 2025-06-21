#!/bin/bash

# Dotfiles Deployment Script
# Author: Martin's Dotfiles - Modular Version
# Description: Deploy dotfiles configurations with backup and conflict handling

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/deploy-dotfiles_$(date +%Y%m%d_%H%M%S).log"
readonly CONFIG_DIR="$HOME/.config"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Flags
FORCE_OVERWRITE=false
SKIP_BACKUP=false
SKIP_CONFIRMATION=false
DRY_RUN=false

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    echo "Starting dotfiles deployment - $(date)" >> "$LOG_FILE"
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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if dotfiles directory exists
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi
    log_success "Dotfiles directory found: $DOTFILES_DIR"
    
    # Create config directory if it doesn't exist
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
        log_success "Created config directory: $CONFIG_DIR"
    else
        log_success "Config directory exists: $CONFIG_DIR"
    fi
    
    log_success "Prerequisites check passed"
}

# Create backup of existing configuration
backup_existing() {
    local target="$1"
    local backup_dir="$HOME/.config/dotfiles-backups/$(date +%Y%m%d_%H%M%S)"
    
    if [[ "$SKIP_BACKUP" == "true" ]]; then
        return 0
    fi
    
    if [[ -e "$target" ]]; then
        log_info "Creating backup of existing: $(basename "$target")"
        mkdir -p "$backup_dir"
        
        if cp -r "$target" "$backup_dir/"; then
            log_success "Backed up to: $backup_dir/$(basename "$target")"
            return 0
        else
            log_error "Failed to create backup"
            return 1
        fi
    fi
    
    return 0
}

# Deploy a single configuration directory/file
deploy_config() {
    local config_name="$1"
    local source_path="$DOTFILES_DIR/$config_name"
    local target_path="$CONFIG_DIR/$config_name"
    
    # Check if source exists
    if [[ ! -e "$source_path" ]]; then
        log_warning "Source not found, skipping: $config_name"
        return 0
    fi
    
    # Skip empty directories
    if [[ -d "$source_path" && -z "$(ls -A "$source_path" 2>/dev/null)" ]]; then
        log_info "Skipping empty directory: $config_name"
        return 0
    fi
    
    log_info "Deploying: $config_name"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would link: $source_path → $target_path"
        return 0
    fi
    
    # Handle existing configuration
    if [[ -L "$target_path" ]]; then
        # It's already a symlink
        local current_target
        current_target=$(readlink "$target_path")
        if [[ "$current_target" == "$source_path" ]]; then
            log_success "Already linked correctly: $config_name"
            return 0
        else
            log_warning "Symlink exists but points to different location: $current_target"
            if [[ "$FORCE_OVERWRITE" == "true" ]]; then
                rm "$target_path"
                log_info "Removed existing symlink"
            else
                if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
                    read -p "Replace existing symlink for $config_name? (y/N): " -r
                    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                        log_info "Skipped: $config_name"
                        return 0
                    fi
                fi
                rm "$target_path"
            fi
        fi
    elif [[ -e "$target_path" ]]; then
        # It's a regular file/directory
        log_warning "Existing configuration found: $config_name"
        
        if [[ "$FORCE_OVERWRITE" == "true" ]]; then
            backup_existing "$target_path"
            rm -rf "$target_path"
            log_info "Removed existing configuration"
        else
            if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
                read -p "Backup and replace existing $config_name? (y/N): " -r
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    log_info "Skipped: $config_name"
                    return 0
                fi
            fi
            backup_existing "$target_path"
            rm -rf "$target_path"
        fi
    fi
    
    # Create the symlink
    if ln -sf "$source_path" "$target_path"; then
        log_success "Linked: $config_name"
    else
        log_error "Failed to link: $config_name"
        return 1
    fi
    
    return 0
}

# Deploy special configurations (files, not directories)
deploy_special_configs() {
    log_section "Deploying Special Configurations"
    
    # Starship config (single file)
    local starship_source="$DOTFILES_DIR/starship/starship.toml"
    local starship_target="$CONFIG_DIR/starship.toml"
    
    if [[ -f "$starship_source" ]]; then
        log_info "Deploying: starship.toml"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "DRY RUN - Would link: $starship_source → $starship_target"
        else
            if [[ -e "$starship_target" && "$FORCE_OVERWRITE" != "true" ]]; then
                if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
                    read -p "Replace existing starship.toml? (y/N): " -r
                    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                        log_info "Skipped: starship.toml"
                    else
                        backup_existing "$starship_target"
                        ln -sf "$starship_source" "$starship_target"
                        log_success "Linked: starship.toml"
                    fi
                else
                    backup_existing "$starship_target"
                    ln -sf "$starship_source" "$starship_target"
                    log_success "Linked: starship.toml"
                fi
            else
                backup_existing "$starship_target"
                ln -sf "$starship_source" "$starship_target"
                log_success "Linked: starship.toml"
            fi
        fi
    fi
    
    # Themes directory (special location)
    local themes_source="$DOTFILES_DIR/themes"
    local themes_target="$HOME/.themes"
    
    if [[ -d "$themes_source" ]]; then
        log_info "Deploying: themes directory"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "DRY RUN - Would link: $themes_source → $themes_target"
        else
            if [[ -e "$themes_target" && "$FORCE_OVERWRITE" != "true" ]]; then
                if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
                    read -p "Replace existing .themes directory? (y/N): " -r
                    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                        log_info "Skipped: themes directory"
                    else
                        backup_existing "$themes_target"
                        ln -sf "$themes_source" "$themes_target"
                        log_success "Linked: themes directory"
                    fi
                else
                    backup_existing "$themes_target"
                    ln -sf "$themes_source" "$themes_target"
                    log_success "Linked: themes directory"
                fi
            else
                backup_existing "$themes_target"
                ln -sf "$themes_source" "$themes_target"
                log_success "Linked: themes directory"
            fi
        fi
    fi
}

# Get list of configuration directories to deploy
get_config_directories() {
    local configs=(
        "ags"
        "hypr"
        "waybar"
        "kitty"
        "fish"
        "dunst"
        "fuzzel"
        "swappy"
        "matugen"
        "quickshell"
        "gtk-3.0"
        "gtk-4.0"
    )
    printf '%s\n' "${configs[@]}"
}

# Show deployment summary
show_summary() {
    log_section "Deployment Summary"
    
    readarray -t configs < <(get_config_directories)
    local total_configs=$((${#configs[@]} + 2)) # +2 for starship.toml and themes
    
    log_info "Configuration directories to deploy: ${#configs[@]}"
    log_info "Special configurations: 2 (starship.toml, themes)"
    log_info "Total configurations: $total_configs"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN MODE - No changes will be made"
    fi
    
    if [[ "$SKIP_CONFIRMATION" != "true" && "$DRY_RUN" != "true" ]]; then
        echo
        read -p "Continue with deployment? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Deployment cancelled by user"
            exit 0
        fi
    fi
}

# Show usage
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Deploy dotfiles configurations by creating symlinks.

OPTIONS:
    -h, --help              Show this help message
    -n, --dry-run           Show what would be deployed without deploying
    -f, --force             Force overwrite existing configurations
    -y, --yes               Skip confirmation prompts
    --no-backup             Skip creating backups of existing configs
    --log-dir DIR           Custom log directory (default: ~/dotfiles/logs)
    --dotfiles-dir DIR      Custom dotfiles directory (default: auto-detect)

DESCRIPTION:
    This script deploys dotfiles by creating symlinks from ~/.config/* to
    the dotfiles directory. It handles existing configurations gracefully
    by offering backup options and conflict resolution.

CONFIGURATIONS DEPLOYED:
    • hypr, waybar, kitty, fish, dunst, fuzzel, swappy, matugen, quickshell
    • GTK configurations (gtk-3.0, gtk-4.0)
    • starship.toml (single file)
    • themes directory (→ ~/.themes)

SAFETY FEATURES:
    • Automatic backups of existing configurations
    • Symlink validation and repair
    • Dry run mode for testing
    • Handles both fresh and existing installations

EXAMPLES:
    $SCRIPT_NAME                    # Deploy with confirmations
    $SCRIPT_NAME -f -y              # Force deploy without confirmations
    $SCRIPT_NAME -n                 # Dry run to see what would be deployed
    $SCRIPT_NAME --no-backup        # Deploy without creating backups

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
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE_OVERWRITE=true
                shift
                ;;
            -y|--yes)
                SKIP_CONFIRMATION=true
                shift
                ;;
            --no-backup)
                SKIP_BACKUP=true
                shift
                ;;
            --log-dir)
                if [[ -n "${2:-}" ]]; then
                    LOG_DIR="$2"
                    LOG_FILE="${LOG_DIR}/deploy-dotfiles_$(date +%Y%m%d_%H%M%S).log"
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
    
    echo "=== Dotfiles Deployment ==="
    echo "Log file: $LOG_FILE"
    echo "Dotfiles directory: $DOTFILES_DIR"
    echo "Config directory: $CONFIG_DIR"
    echo
    
    check_prerequisites
    show_summary
    
    echo
    log_info "Starting dotfiles deployment..."
    
    # Deploy configuration directories
    log_section "Deploying Configuration Directories"
    readarray -t configs < <(get_config_directories)
    local deployed_count=0
    local failed_count=0
    
    for config in "${configs[@]}"; do
        if deploy_config "$config"; then
            deployed_count=$((deployed_count + 1))
        else
            failed_count=$((failed_count + 1))
        fi
    done
    
    # Deploy special configurations
    deploy_special_configs
    
    echo
    if [[ "$DRY_RUN" == "true" ]]; then
        log_success "Dry run completed - no changes were made"
    else
        log_success "Dotfiles deployment completed!"
        log_info "Successfully processed: $deployed_count configurations"
        if [[ $failed_count -gt 0 ]]; then
            log_warning "Failed: $failed_count configurations"
        fi
    fi
    
    echo "Log file: $LOG_FILE"
    
    if [[ "$SKIP_BACKUP" != "true" && "$DRY_RUN" != "true" ]]; then
        echo
        log_info "Backups are stored in: ~/.config/dotfiles-backups/"
    fi
}

# Run main function
main "$@" 