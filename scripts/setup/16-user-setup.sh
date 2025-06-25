#!/bin/bash

# User Environment Setup Script
# Author: Martin's Dotfiles - Modular Version
# Description: Final user environment configuration and shell setup

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/user-setup_$(date +%Y%m%d_%H%M%S).log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Flags
SKIP_CONFIRMATION=false
SKIP_SHELL_CONFIG=false
SKIP_PERMISSIONS=false
SKIP_DIRECTORIES=false
DRY_RUN=false

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    echo "Starting user environment setup - $(date)" >> "$LOG_FILE"
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
    
    # Check if running as regular user
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run as root"
        exit 1
    fi
    
    # Check if dotfiles are deployed
    if [[ ! -L "$HOME/.config/fish" ]]; then
        log_warning "Fish configuration not found. Run 03-deploy-dotfiles.sh first"
    fi
    
    log_success "Prerequisites check passed"
}

# Setup user directories
setup_user_directories() {
    if [[ "$SKIP_DIRECTORIES" == "true" ]]; then
        log_info "Skipping user directories setup"
        return 0
    fi
    
    log_section "Setting up User Directories"
    
    local user_dirs=(
        "$HOME/.local/bin"
        "$HOME/.local/share/applications"
        "$HOME/.local/share/fonts"
        "$HOME/.local/share/wallpapers"
        "$HOME/.config/systemd/user"
        "$HOME/Projects"
        "$HOME/Scripts"
        "$HOME/Downloads/Software"
        "$HOME/Documents/Templates"
    )
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would create user directories:"
        for dir in "${user_dirs[@]}"; do
            echo "  • $dir"
        done
        return 0
    fi
    
    local created_count=0
    for dir in "${user_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            if mkdir -p "$dir"; then
                log_success "Created: $dir"
                created_count=$((created_count + 1))
            else
                log_warning "Failed to create: $dir"
            fi
        else
            log_info "Already exists: $dir"
        fi
    done
    
    log_success "Created $created_count new directories"
}

# Configure shell environment
configure_shell_environment() {
    if [[ "$SKIP_SHELL_CONFIG" == "true" ]]; then
        log_info "Skipping shell configuration"
        return 0
    fi
    
    log_section "Configuring Shell Environment"
    
    # Check current shell
    local current_shell
    current_shell=$(basename "$SHELL")
    log_info "Current shell: $current_shell"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would configure shell environment"
        return 0
    fi
    
    # Configure Fish shell if available
    if command -v fish &>/dev/null; then
        log_info "Configuring Fish shell..."
        
        # Ensure Fish config directory exists
        mkdir -p "$HOME/.config/fish/functions"
        mkdir -p "$HOME/.config/fish/completions"
        
        # Add ~/.local/bin to PATH if not already there
        local fish_config="$HOME/.config/fish/config.fish"
        if [[ -f "$fish_config" ]]; then
            if ! grep -q "\.local/bin" "$fish_config"; then
                echo 'set -gx PATH $HOME/.local/bin $PATH' >> "$fish_config"
                log_success "Added ~/.local/bin to Fish PATH"
            fi
        fi
        
        # Set Fish as default shell if requested
        if [[ "$current_shell" != "fish" ]]; then
            if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
                read -p "Set Fish as default shell? (y/N): " -r
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    if chsh -s "$(which fish)"; then
                        log_success "Fish set as default shell"
                        log_info "Please logout and login for changes to take effect"
                    else
                        log_warning "Failed to set Fish as default shell"
                    fi
                fi
            fi
        else
            log_success "Fish is already the default shell"
        fi
    else
        log_warning "Fish shell not installed"
    fi
    
    # Configure bash environment as fallback
    local bashrc="$HOME/.bashrc"
    if [[ -f "$bashrc" ]]; then
        if ! grep -q "\.local/bin" "$bashrc"; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$bashrc"
            log_success "Added ~/.local/bin to Bash PATH"
        fi
    fi
}

# Fix file permissions
fix_file_permissions() {
    if [[ "$SKIP_PERMISSIONS" == "true" ]]; then
        log_info "Skipping permissions fix"
        return 0
    fi
    
    log_section "Fixing File Permissions"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would fix file permissions"
        return 0
    fi
    
    # Fix executable permissions for scripts
    local script_dirs=(
        "$HOME/.local/bin"
        "$DOTFILES_DIR/scripts"
    )
    
    for dir in "${script_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_info "Fixing permissions in: $dir"
            find "$dir" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
            find "$dir" -type f -executable -exec chmod 755 {} \; 2>/dev/null || true
        fi
    done
    
    # Fix config file permissions
    local config_dirs=(
        "$HOME/.config"
        "$HOME/.local/share"
    )
    
    for dir in "${config_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_info "Fixing config permissions in: $dir"
            find "$dir" -type d -exec chmod 755 {} \; 2>/dev/null || true
            find "$dir" -type f -exec chmod 644 {} \; 2>/dev/null || true
        fi
    done
    
    # Fix SSH permissions if directory exists
    if [[ -d "$HOME/.ssh" ]]; then
        log_info "Fixing SSH permissions"
        chmod 700 "$HOME/.ssh"
        find "$HOME/.ssh" -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true
        find "$HOME/.ssh" -type f -name "*.pub" -exec chmod 644 {} \; 2>/dev/null || true
        [[ -f "$HOME/.ssh/config" ]] && chmod 600 "$HOME/.ssh/config"
        [[ -f "$HOME/.ssh/authorized_keys" ]] && chmod 600 "$HOME/.ssh/authorized_keys"
    fi
    
    log_success "File permissions fixed"
}

# Setup desktop integration
setup_desktop_integration() {
    log_section "Setting up Desktop Integration"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would setup desktop integration"
        return 0
    fi
    
    # Update desktop database
    if command -v update-desktop-database &>/dev/null; then
        log_info "Updating desktop database..."
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
        log_success "Desktop database updated"
    fi
    
    # Update font cache
    if command -v fc-cache &>/dev/null; then
        log_info "Updating font cache..."
        fc-cache -f "$HOME/.local/share/fonts" 2>/dev/null || true
        log_success "Font cache updated"
    fi
    
    # Update mime database
    if command -v update-mime-database &>/dev/null; then
        log_info "Updating MIME database..."
        update-mime-database "$HOME/.local/share/mime" 2>/dev/null || true
        log_success "MIME database updated"
    fi
}

# Create useful aliases and functions
create_shell_utilities() {
    log_section "Creating Shell Utilities"
    
    local aliases_file="$HOME/.config/fish/functions/aliases.fish"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would create shell utilities"
        return 0
    fi
    
    mkdir -p "$(dirname "$aliases_file")"
    
    # Create useful Fish functions
    cat > "$aliases_file" << 'EOF'
# Useful aliases for dotfiles system
# Generated by modular installer

function ll
    ls -la $argv
end

function la
    ls -A $argv
end

function l
    ls -CF $argv
end

function ..
    cd ..
end

function ...
    cd ../..
end

function grep
    command grep --color=auto $argv
end

function df
    command df -h $argv
end

function free
    command free -h $argv
end

function ps
    command ps aux $argv
end

# Git aliases
function g
    git $argv
end

function gs
    git status $argv
end

function ga
    git add $argv
end

function gc
    git commit $argv
end

function gp
    git push $argv
end

function gl
    git log --oneline $argv
end

# System management
function sysinfo
    system-monitor all
end

function logs
    journalctl -f $argv
end

function ports
    netstat -tuln $argv
end

# Development shortcuts
function mkcd
    mkdir -p $argv[1]; and cd $argv[1]
end

function extract
    if test -f $argv[1]
        switch $argv[1]
            case '*.tar.bz2'
                tar xjf $argv[1]
            case '*.tar.gz'
                tar xzf $argv[1]
            case '*.bz2'
                bunzip2 $argv[1]
            case '*.rar'
                unrar x $argv[1]
            case '*.gz'
                gunzip $argv[1]
            case '*.tar'
                tar xf $argv[1]
            case '*.tbz2'
                tar xjf $argv[1]
            case '*.tgz'
                tar xzf $argv[1]
            case '*.zip'
                unzip $argv[1]
            case '*.Z'
                uncompress $argv[1]
            case '*.7z'
                7z x $argv[1]
            case '*'
                echo "'$argv[1]' cannot be extracted via extract()"
        end
    else
        echo "'$argv[1]' is not a valid file"
    end
end
EOF
    
    log_success "Shell utilities created: $aliases_file"
}

# Generate system summary
generate_system_summary() {
    log_section "Generating System Summary"
    
    local summary_file="$HOME/.local/share/dotfiles-setup-summary.txt"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would generate system summary"
        return 0
    fi
    
    cat > "$summary_file" << EOF
# Dotfiles Modular Installation Summary
# Generated on: $(date)

## System Information
- User: $USER
- Hostname: $(cat /etc/hostname 2>/dev/null || echo "${HOSTNAME:-unknown}")
- Kernel: $(uname -r)
- Shell: $SHELL
- Desktop: ${XDG_CURRENT_DESKTOP:-Unknown}

## Installation Directory
- Dotfiles: $DOTFILES_DIR
- Logs: $LOG_DIR

## Quick Commands
- Theme restart: restart-theme
- System monitor: system-monitor
- VM management: vm-manager
- Ollama chat: ollama-chat
- Brave backup: brave-backup

## Configuration Files
- Fish config: ~/.config/fish/config.fish
- Hypr config: ~/.config/hypr/hyprland.conf
- Waybar config: ~/.config/waybar/config
- Kitty terminal: ~/.config/kitty/kitty.conf

## Log Files Location
All installation logs are stored in:
$LOG_DIR

## Support
For issues or questions, check the documentation in:
$DOTFILES_DIR/docs/

Last updated: $(date)
EOF
    
    log_success "System summary created: $summary_file"
    
    # Display summary
    echo
    log_info "=== Installation Summary ==="
    echo "Total scripts run: $(ls "$LOG_DIR"/*.log 2>/dev/null | wc -l)"
    echo "Configuration files deployed: $(find "$HOME/.config" -type l 2>/dev/null | wc -l) symlinks"
    echo "User utilities created: $(find "$HOME/.local/bin" -type f -executable 2>/dev/null | wc -l) scripts"
    echo "Summary file: $summary_file"
}

# Show usage
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Final user environment configuration and shell setup.

OPTIONS:
    -h, --help              Show this help message
    -n, --dry-run           Show what would be done without making changes
    -y, --yes               Skip confirmation prompts
    --skip-shell-config     Skip shell environment configuration
    --skip-permissions      Skip file permissions fix
    --skip-directories      Skip user directories creation
    --log-dir DIR           Custom log directory (default: ~/dotfiles/logs)
    --dotfiles-dir DIR      Custom dotfiles directory (default: auto-detect)

DESCRIPTION:
    This script performs final user environment setup including shell
    configuration, directory creation, permissions fixing, and system integration.

FEATURES:
    • User directory structure creation
    • Shell environment configuration (Fish/Bash)
    • File permissions optimization
    • Desktop integration setup
    • Useful aliases and functions
    • System summary generation

DIRECTORIES CREATED:
    • ~/.local/bin           - User executable scripts
    • ~/.local/share/fonts   - User fonts
    • ~/Projects             - Development projects
    • ~/Scripts              - User scripts
    • And other standard directories

SHELL CONFIGURATION:
    • PATH environment setup
    • Useful aliases and functions
    • Default shell configuration
    • Fish shell optimization

EXAMPLES:
    $SCRIPT_NAME                    # Complete user environment setup
    $SCRIPT_NAME --skip-shell-config # Skip shell configuration
    $SCRIPT_NAME -n                 # Dry run to see what would be done
    $SCRIPT_NAME -y                 # Setup without confirmations

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
            -y|--yes)
                SKIP_CONFIRMATION=true
                shift
                ;;
            --skip-shell-config)
                SKIP_SHELL_CONFIG=true
                shift
                ;;
            --skip-permissions)
                SKIP_PERMISSIONS=true
                shift
                ;;
            --skip-directories)
                SKIP_DIRECTORIES=true
                shift
                ;;
            --log-dir)
                if [[ -n "${2:-}" ]]; then
                    LOG_DIR="$2"
                    LOG_FILE="${LOG_DIR}/user-setup_$(date +%Y%m%d_%H%M%S).log"
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
    
    echo "=== User Environment Setup ==="
    echo "Log file: $LOG_FILE"
    echo "Dotfiles directory: $DOTFILES_DIR"
    echo
    
    check_prerequisites
    setup_user_directories
    configure_shell_environment
    fix_file_permissions
    setup_desktop_integration
    create_shell_utilities
    generate_system_summary
    
    echo
    if [[ "$DRY_RUN" == "true" ]]; then
        log_success "Dry run completed - no changes were made"
    else
        log_success "User environment setup completed!"
        log_info "🎉 Dotfiles modular installation is now complete!"
        log_info "Check ~/.local/share/dotfiles-setup-summary.txt for details"
        
        if [[ "$SHELL" != *"fish"* ]]; then
            log_info "💡 Consider logging out and back in to apply all changes"
        fi
    fi
    
    echo "Log file: $LOG_FILE"
}

# Run main function
main "$@" 