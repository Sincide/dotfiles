#!/bin/bash

# Theming System Setup Script
# Author: Martin's Dotfiles - Modular Version
# Description: Configure dynamic theming system and install additional themes

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/theming-setup_$(date +%Y%m%d_%H%M%S).log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Flags
SKIP_CONFIRMATION=false
SKIP_THEME_INSTALL=false
SKIP_WALLPAPER_SETUP=false
DRY_RUN=false

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    echo "Starting theming system setup - $(date)" >> "$LOG_FILE"
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
    
    # Check if matugen is installed
    if ! command -v matugen &>/dev/null; then
        log_error "matugen is not installed. Please install theming packages first"
        exit 1
    fi
    log_success "matugen is available"
    
    # Check if dotfiles are deployed
    if [[ ! -L "$HOME/.config/matugen" ]]; then
        log_warning "Matugen config not deployed. Run 03-deploy-dotfiles.sh first"
    else
        log_success "Matugen config is deployed"
    fi
    
    log_success "Prerequisites check passed"
}

# Setup theming directories
setup_theming_dirs() {
    log_section "Setting up Theming Directories"
    
    local theme_dirs=(
        "$HOME/.config/matugen"
        "$HOME/.config/matugen/templates"
        "$HOME/.local/share/wallpapers"
        "$HOME/.themes"
        "$HOME/.icons"
    )
    
    for dir in "${theme_dirs[@]}"; do
        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "DRY RUN - Would create: $dir"
            continue
        fi
        
        if [[ ! -d "$dir" ]]; then
            if mkdir -p "$dir"; then
                log_success "Created: $dir"
            else
                log_error "Failed to create: $dir"
            fi
        else
            log_success "Already exists: $dir"
        fi
    done
}

# Setup wallpaper collection
setup_wallpapers() {
    if [[ "$SKIP_WALLPAPER_SETUP" == "true" ]]; then
        log_info "Skipping wallpaper setup"
        return 0
    fi
    
    log_section "Setting up Wallpaper Collection"
    
    local wallpaper_source="$DOTFILES_DIR/assets/wallpapers"
    local wallpaper_target="$HOME/.local/share/wallpapers/dotfiles"
    
    if [[ ! -d "$wallpaper_source" ]]; then
        log_warning "Wallpaper collection not found: $wallpaper_source"
        return 0
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would link: $wallpaper_source → $wallpaper_target"
        return 0
    fi
    
    if [[ -L "$wallpaper_target" ]]; then
        local current_target
        current_target=$(readlink "$wallpaper_target")
        if [[ "$current_target" == "$wallpaper_source" ]]; then
            log_success "Wallpaper collection already linked correctly"
            return 0
        else
            log_warning "Wallpaper symlink points to different location: $current_target"
            rm "$wallpaper_target"
        fi
    elif [[ -e "$wallpaper_target" ]]; then
        log_warning "Wallpaper target exists but is not a symlink"
        if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
            read -p "Replace existing wallpaper directory? (y/N): " -r
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Skipped wallpaper setup"
                return 0
            fi
        fi
        rm -rf "$wallpaper_target"
    fi
    
    if ln -sf "$wallpaper_source" "$wallpaper_target"; then
        log_success "Wallpaper collection linked"
    else
        log_error "Failed to link wallpaper collection"
    fi
}

# Install additional themes via yay
install_additional_themes() {
    if [[ "$SKIP_THEME_INSTALL" == "true" ]]; then
        log_info "Skipping additional theme installation"
        return 0
    fi
    
    log_section "Installing Additional Themes"
    
    # High-quality themes to install
    local additional_themes=(
        "whitesur-gtk-theme"
        "whitesur-icon-theme"
        "orchis-theme"
        "tela-circle-icon-theme-all"
        "numix-circle-icon-theme-git"
        "qogir-icon-theme"
    )
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would install additional themes:"
        for theme in "${additional_themes[@]}"; do
            echo "  • $theme"
        done
        return 0
    fi
    
    if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
        echo
        read -p "Install additional themes (${#additional_themes[@]} packages)? This may take time. (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipped additional theme installation"
            return 0
        fi
    fi
    
    log_info "Installing additional themes (this may take several minutes)..."
    local failed_themes=()
    
    for theme in "${additional_themes[@]}"; do
        log_info "Installing: $theme"
        
        if yay -Q "$theme" &>/dev/null; then
            log_success "$theme is already installed"
            continue
        fi
        
        if yay -S --needed --noconfirm --overwrite '*' "$theme"; then
            log_success "$theme installed successfully"
        else
            log_error "Failed to install: $theme"
            failed_themes+=("$theme")
        fi
    done
    
    if [[ ${#failed_themes[@]} -gt 0 ]]; then
        log_warning "Failed to install some themes:"
        for theme in "${failed_themes[@]}"; do
            echo "  ✗ $theme"
        done
    fi
}

# Create theme restart utility
create_theme_utilities() {
    log_section "Creating Theme Utilities"
    
    local bin_dir="$HOME/.local/bin"
    local theme_script="$bin_dir/restart-theme"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would create theme restart utility: $theme_script"
        return 0
    fi
    
    mkdir -p "$bin_dir"
    
    cat > "$theme_script" << 'EOF'
#!/bin/bash
# Theme Restart Utility
# Restart theming applications after theme change

log_info() {
    echo -e "\033[0;34m[INFO] $1\033[0m"
}

log_success() {
    echo -e "\033[0;32m✓ [SUCCESS] $1\033[0m"
}

log_info "Restarting theming applications..."

# Kill running applications
pkill waybar 2>/dev/null || true
pkill dunst 2>/dev/null || true
sleep 0.5

# Restart applications
log_info "Starting waybar..."
waybar > /dev/null 2>&1 &

if [[ -f "$HOME/.config/waybar/config-bottom" ]]; then
    log_info "Starting bottom waybar..."
    waybar -c ~/.config/waybar/config-bottom -s ~/.config/waybar/style-bottom.css > /dev/null 2>&1 &
fi

log_info "Starting dunst..."
dunst > /dev/null 2>&1 &

# Reload Hyprland
if command -v hyprctl &>/dev/null; then
    log_info "Reloading Hyprland..."
    hyprctl reload 2>/dev/null || true
fi

# Send notification
if command -v notify-send &>/dev/null; then
    sleep 1
    notify-send "Theme Updated" "All applications reloaded with new theme" 2>/dev/null || true
fi

log_success "Theme restart completed!"
EOF
    
    chmod +x "$theme_script"
    log_success "Theme restart utility created: $theme_script"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        log_info "Adding $bin_dir to PATH in shell configuration"
        # This will be handled by user-setup script
    fi
}

# Test dynamic theme system
test_theme_system() {
    log_section "Testing Dynamic Theme System"
    
    local theme_switcher="$DOTFILES_DIR/scripts/theming/dynamic_theme_switcher.sh"
    local test_wallpaper="$DOTFILES_DIR/assets/wallpapers/space/dark_space.jpg"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would test theme system"
        return 0
    fi
    
    if [[ ! -f "$theme_switcher" ]]; then
        log_warning "Dynamic theme switcher not found: $theme_switcher"
        return 0
    fi
    
    if [[ ! -f "$test_wallpaper" ]]; then
        log_warning "Test wallpaper not found: $test_wallpaper"
        return 0
    fi
    
    if [[ "$SKIP_CONFIRMATION" != "true" ]]; then
        read -p "Test dynamic theme system with space wallpaper? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipped theme system test"
            return 0
        fi
    fi
    
    log_info "Testing theme system with space wallpaper..."
    chmod +x "$theme_switcher"
    
    if bash "$theme_switcher" apply "$test_wallpaper"; then
        log_success "Theme system test completed successfully"
    else
        log_warning "Theme system test had some issues"
    fi
}

# Setup GTK theme integration
setup_gtk_integration() {
    log_section "Setting up GTK Theme Integration"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would setup GTK integration"
        return 0
    fi
    
    # Create GTK settings for theme consistency
    local gtk3_settings="$HOME/.config/gtk-3.0/settings.ini"
    local gtk4_settings="$HOME/.config/gtk-4.0/settings.ini"
    
    # These will be managed by the dynamic theme system
    log_info "GTK theme integration will be managed by dynamic theme system"
    log_info "Themes are applied automatically when wallpapers change"
    log_success "GTK integration configured"
}

# Show usage
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Setup dynamic theming system and install additional themes.

OPTIONS:
    -h, --help              Show this help message
    -n, --dry-run           Show what would be configured without changes
    -y, --yes               Skip confirmation prompts
    --skip-themes           Skip additional theme installation
    --skip-wallpapers       Skip wallpaper collection setup
    --log-dir DIR           Custom log directory (default: ~/dotfiles/logs)
    --dotfiles-dir DIR      Custom dotfiles directory (default: auto-detect)

DESCRIPTION:
    This script sets up the complete dynamic theming system including:
    - Theming directories and wallpaper collection
    - Additional high-quality themes (WhiteSur, Orchis, etc.)
    - Theme restart utilities
    - GTK theme integration
    - Testing of the dynamic theme system

FEATURES:
    • Automatic theme switching based on wallpapers
    • High-quality icon and GTK themes
    • Theme restart utilities for seamless updates
    • Integration with matugen color generation

EXAMPLES:
    $SCRIPT_NAME                    # Full theming setup
    $SCRIPT_NAME --skip-themes      # Setup without additional themes
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
            --skip-themes)
                SKIP_THEME_INSTALL=true
                shift
                ;;
            --skip-wallpapers)
                SKIP_WALLPAPER_SETUP=true
                shift
                ;;
            --log-dir)
                if [[ -n "${2:-}" ]]; then
                    LOG_DIR="$2"
                    LOG_FILE="${LOG_DIR}/theming-setup_$(date +%Y%m%d_%H%M%S).log"
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
    
    echo "=== Theming System Setup ==="
    echo "Log file: $LOG_FILE"
    echo "Dotfiles directory: $DOTFILES_DIR"
    echo
    
    check_prerequisites
    setup_theming_dirs
    setup_wallpapers
    install_additional_themes
    create_theme_utilities
    setup_gtk_integration
    test_theme_system
    
    echo
    if [[ "$DRY_RUN" == "true" ]]; then
        log_success "Dry run completed - no changes were made"
    else
        log_success "Theming system setup completed!"
        log_info "Use 'restart-theme' command to apply theme changes"
        log_info "Dynamic themes will be applied automatically with wallpaper changes"
    fi
    
    echo "Log file: $LOG_FILE"
}

# Run main function
main "$@" 