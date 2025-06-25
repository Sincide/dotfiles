#!/bin/bash

# Complete Dotfiles Installation Script
# Orchestrates the entire installation process for 100% automation

set -euo pipefail

readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/complete-installation_$(date +%Y%m%d_%H%M%S).log"
readonly SETUP_DIR="${DOTFILES_DIR}/scripts/setup"

# CLI flags
DRY_RUN=false
SKIP_CONFIRMATION=false
MINIMAL_INSTALL=false
SKIP_SERVICES=false

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
            --minimal)
                MINIMAL_INSTALL=true
                log_info "Minimal installation mode"
                shift
                ;;
            --skip-services)
                SKIP_SERVICES=true
                log_info "Skipping service setup"
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
Complete Dotfiles Installation Script

This script orchestrates the entire installation process to achieve 100% automation.

Usage: $0 [OPTIONS]

Options:
    --dry-run           Show what would be done without making changes
    --yes               Skip all confirmation prompts
    --minimal           Install only essential components
    --skip-services     Skip service configuration
    --help, -h          Show this help message

Installation Phases:
    Phase 1: Prerequisites & System Setup
    Phase 2: Package Installation  
    Phase 3: Dotfiles Deployment
    Phase 4: Theming & Customization
    Phase 5: Services & Media Setup
    Phase 6: User Configuration
    Phase 7: Final Optimization

Examples:
    $0                  Interactive full installation
    $0 --yes            Automated full installation
    $0 --minimal        Essential components only
    $0 --dry-run        Preview installation steps

EOF
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        exit 1
    fi
}

# Run a setup script safely
run_setup_script() {
    local script="$1"
    local description="$2"
    local required="$3"
    local script_path="$SETUP_DIR/$script"
    
    log_info "Running: $script ($description)"
    
    if [[ ! -f "$script_path" ]]; then
        if [[ "$required" == "required" ]]; then
            log_error "Required script not found: $script"
            return 1
        else
            log_warning "Optional script not found: $script"
            return 0
        fi
    fi
    
    if [[ ! -x "$script_path" ]]; then
        chmod +x "$script_path"
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute: $script"
        return 0
    fi
    
    # Pass through flags to sub-scripts
    local script_args=()
    [[ "$SKIP_CONFIRMATION" == "true" ]] && script_args+=("--yes")
    [[ "$DRY_RUN" == "true" ]] && script_args+=("--dry-run")
    
    if "$script_path" "${script_args[@]}"; then
        log_success "Completed: $script"
        return 0
    else
        local exit_code=$?
        if [[ "$required" == "required" ]]; then
            log_error "Required script failed: $script (exit code: $exit_code)"
            return 1
        else
            log_warning "Optional script failed: $script (exit code: $exit_code)"
            return 0
        fi
    fi
}

# Phase 1: Prerequisites and System Setup
phase_1_prerequisites() {
    log_section "Phase 1: Prerequisites & System Setup"
    
    run_setup_script "01-prerequisites.sh" "System prerequisites check" "required"
    run_setup_script "02-setup-chaotic-aur.sh" "Chaotic AUR repository" "required"
}

# Phase 2: Package Installation
phase_2_packages() {
    log_section "Phase 2: Package Installation"
    
    run_setup_script "03-install-packages.sh" "Core package installation" "required"
}

# Phase 3: Dotfiles and Configuration
phase_3_dotfiles() {
    log_section "Phase 3: Dotfiles Deployment"
    
    run_setup_script "04-deploy-dotfiles.sh" "Deploy configuration files" "required"
    run_setup_script "05-setup-theming.sh" "Theming system setup" "required"
}

# Phase 4: Storage and External Setup
phase_4_storage_external() {
    log_section "Phase 4: Storage & External Setup"
    
    if [[ "$MINIMAL_INSTALL" == "false" ]]; then
        run_setup_script "06-setup-external-drives.sh" "External drive setup" "optional"
        run_setup_script "07-setup-brave-backup.sh" "Brave browser backup" "optional"
    else
        log_info "Skipping external setup (minimal install)"
    fi
}

# Phase 5: AI and Virtualization
phase_5_ai_virtualization() {
    log_section "Phase 5: AI & Virtualization Setup"
    
    run_setup_script "08-setup-ollama.sh" "Ollama AI platform" "optional"
    run_setup_script "09-setup-virt-manager.sh" "Virtualization setup" "optional"
}

# Phase 6: Media Services
phase_6_media_services() {
    log_section "Phase 6: Media Services Setup"
    
    if [[ "$MINIMAL_INSTALL" == "false" ]]; then
        run_setup_script "10-setup-qbittorrent.sh" "qBittorrent torrent client" "optional"
        run_setup_script "11-setup-emby.sh" "Emby media server" "optional"
        run_setup_script "12-setup-storage.sh" "Storage drive mounting" "optional"
    else
        log_info "Skipping media services (minimal install)"
    fi
}

# Phase 7: User and System Configuration
phase_7_user_system() {
    log_section "Phase 7: User & System Configuration"
    
    run_setup_script "13-setup-user-groups.sh" "User groups configuration" "required"
    
    if [[ "$SKIP_SERVICES" == "false" ]]; then
        run_setup_script "14-setup-services.sh" "Service management" "required"
    fi
    
    run_setup_script "15-system-optimization.sh" "System optimization" "optional"
    run_setup_script "16-user-setup.sh" "Final user setup" "optional"
}

# Show installation summary
show_installation_summary() {
    log_section "Installation Summary"
    
    local total_time=$((SECONDS / 60))
    log_info "Total installation time: ${total_time} minutes"
    
    log_info ""
    log_info "Installation completed with the following phases:"
    log_info "  ✅ Phase 1: Prerequisites & System Setup"
    log_info "  ✅ Phase 2: Package Installation"
    log_info "  ✅ Phase 3: Dotfiles Deployment"
    
    if [[ "$MINIMAL_INSTALL" == "false" ]]; then
        log_info "  ✅ Phase 4: Storage & External Setup"
    else
        log_info "  ⚠️  Phase 4: Skipped (minimal install)"
    fi
    
    log_info "  ✅ Phase 5: AI & Virtualization Setup"
    
    if [[ "$MINIMAL_INSTALL" == "false" ]]; then
        log_info "  ✅ Phase 6: Media Services Setup"
    else
        log_info "  ⚠️  Phase 6: Skipped (minimal install)"
    fi
    
    if [[ "$SKIP_SERVICES" == "false" ]]; then
        log_info "  ✅ Phase 7: User & System Configuration"
    else
        log_info "  ⚠️  Phase 7: Services skipped"
    fi
    
    log_info ""
    log_info "Next steps:"
    log_info "  1. Log out and back in for group changes to take effect"
    log_info "  2. Start Hyprland desktop: Hyprland"
    log_info "  3. Set up wallpaper: wallpaper-manager"
    log_info "  4. Check services: services status"
    log_info "  5. Test AI platform: ollama list"
    
    if [[ "$MINIMAL_INSTALL" == "false" ]]; then
        log_info "  6. Access Emby: http://localhost:8096"
        log_info "  7. Access qBittorrent: http://localhost:9090"
    fi
    
    log_info ""
    log_info "Useful commands:"
    log_info "  dashboard               - Launch system dashboard"
    log_info "  services status         - Check all services"
    log_info "  storage usage           - Check storage usage"
    log_info "  groups_info check       - Verify user groups"
    log_info "  theme-space            - Apply space theme"
    
    log_success "🎉 Dotfiles installation completed successfully!"
    log_info "Enjoy your sophisticated Arch Linux + Hyprland setup!"
}

# Check if installation completed successfully
verify_installation() {
    log_section "Installation Verification"
    
    local errors=0
    
    # Check essential commands
    local essential_commands=(
        "hyprland"
        "waybar"
        "kitty"
        "fuzzel"
        "matugen"
    )
    
    for cmd in "${essential_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            log_success "$cmd is available"
        else
            log_error "$cmd is not available"
            ((errors++))
        fi
    done
    
    # Check configuration files
    local essential_configs=(
        "$HOME/.config/hypr/hyprland.conf"
        "$HOME/.config/waybar/config"
        "$HOME/.config/kitty/kitty.conf"
        "$HOME/.config/fish/config.fish"
    )
    
    for config in "${essential_configs[@]}"; do
        if [[ -f "$config" ]]; then
            log_success "Config exists: $(basename "$config")"
        else
            log_error "Config missing: $config"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_success "All essential components verified successfully"
        return 0
    else
        log_error "Installation verification failed with $errors errors"
        return 1
    fi
}

# Main execution
main() {
    log_section "Complete Dotfiles Installation"
    log_info "Starting complete installation for user: $(whoami)"
    log_info "Log file: $LOG_FILE"
    log_info "Installation mode: $([ "$MINIMAL_INSTALL" == "true" ] && echo "Minimal" || echo "Full")"
    
    check_root
    
    # Show what will be installed
    if [[ "$SKIP_CONFIRMATION" == "false" && "$DRY_RUN" == "false" ]]; then
        echo ""
        echo "This will install a complete Arch Linux + Hyprland desktop environment with:"
        echo "  • 397 packages across 6 categories"
        echo "  • Dynamic Material Design 3 theming system"
        echo "  • AI platform with local LLMs (Ollama)"
        echo "  • Media server (Emby) and torrent client (qBittorrent)"
        echo "  • Advanced GPU monitoring and web dashboard"
        echo "  • Complete development environment"
        echo ""
        echo "Installation will take approximately 30-60 minutes depending on internet speed."
        echo ""
        read -p "Do you want to proceed with the complete installation? [y/N]: " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled by user"
            exit 0
        fi
    fi
    
    # Record start time
    local start_time=$SECONDS
    
    # Execute installation phases
    phase_1_prerequisites
    phase_2_packages
    phase_3_dotfiles
    phase_4_storage_external
    phase_5_ai_virtualization
    phase_6_media_services
    phase_7_user_system
    
    # Verification and summary
    if [[ "$DRY_RUN" == "false" ]]; then
        verify_installation
    fi
    
    show_installation_summary
    
    log_info "Check the complete log file: $LOG_FILE"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "Dry run completed. Use without --dry-run to perform actual installation."
    fi
}

# Parse arguments and run main function
parse_args "$@"
main