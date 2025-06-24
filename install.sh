#!/bin/bash

# ============================================================================
# 🌌 EVIL SPACE DOTFILES - COMPLETE INSTALLATION SYSTEM
# ============================================================================
# 
# Interactive post-installation setup for Arch Linux + Hyprland
# From fresh Arch installation to complete Evil Space desktop environment
# 
# Author: Evil Space Dotfiles Project
# Version: 2.0
# Compatibility: Bash (fresh installs) + Fish (testing)
# 
# Features:
# • Interactive guided installation with detailed explanations
# • Comprehensive dry-run testing capabilities
# • Phase-based installation with progress tracking
# • Intelligent error handling and recovery
# • Complete logging and status reporting
# • Safe to rerun multiple times (idempotent)
# 
# ============================================================================

set -euo pipefail

# ============================================================================
# CONFIGURATION & CONSTANTS
# ============================================================================

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="2.0"
readonly DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/installation_$(date +%Y%m%d_%H%M%S).log"
readonly STATE_FILE="${DOTFILES_DIR}/.installation_state"

# Colors and formatting
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

# Unicode symbols for better visual experience
readonly CHECKMARK="✅"
readonly CROSSMARK="❌"
readonly WARNING="⚠️"
readonly INFO="ℹ️"
readonly ROCKET="🚀"
readonly GEAR="⚙️"
readonly SPARKLES="✨"
readonly SKULL="💀"
readonly FIRE="🔥"

# Installation configuration
DRY_RUN=false
INTERACTIVE=true
SKIP_CONFIRMATION=false
SELECTED_PHASES=()
START_FROM_PHASE=""
PARALLEL_JOBS=1

# ============================================================================
# INSTALLATION PHASES DEFINITION
# ============================================================================

declare -A PHASES=(
    ["00-prerequisites"]="System validation and AUR helper setup"
    ["01-chaotic-aur"]="Advanced package repository configuration"
    ["02-packages"]="Complete package installation (397 packages)"
    ["03-dotfiles"]="Configuration deployment and symlink management"
    ["04-theming"]="Dynamic Material Design 3 theming system"
    ["05-external-drives"]="External storage management and auto-mounting"
    ["06-brave-backup"]="Browser backup and restore system"
    ["07-ollama"]="AI platform setup with model management"
    ["08-virtualization"]="Virtual machine environment (QEMU/KVM)"
    ["09-optimization"]="System performance tuning and optimizations"
    ["10-user-setup"]="User environment finalization"
    ["11-qbittorrent"]="Media management and torrent setup"
)

declare -A PHASE_SCRIPTS=(
    ["00-prerequisites"]="scripts/setup/00-prerequisites.sh"
    ["01-chaotic-aur"]="scripts/setup/01-setup-chaotic-aur.sh"
    ["02-packages"]="scripts/setup/02-install-packages.sh"
    ["03-dotfiles"]="scripts/setup/03-deploy-dotfiles.sh"
    ["04-theming"]="scripts/setup/04-setup-theming.sh"
    ["05-external-drives"]="scripts/setup/05-setup-external-drives.sh"
    ["06-brave-backup"]="scripts/setup/06-setup-brave-backup.sh"
    ["07-ollama"]="scripts/setup/07-setup-ollama.sh"
    ["08-virtualization"]="scripts/setup/08-setup-virt-manager.sh"
    ["09-optimization"]="scripts/setup/09-system-optimization.sh"
    ["10-user-setup"]="scripts/setup/10-user-setup.sh"
    ["11-qbittorrent"]="scripts/setup/11-setup-qbittorrent.sh"
)

declare -A PHASE_REQUIREMENTS=(
    ["00-prerequisites"]="Fresh Arch Linux installation with internet access"
    ["01-chaotic-aur"]="AUR helper (yay) installed"
    ["02-packages"]="Chaotic-AUR repository configured"
    ["03-dotfiles"]="Core packages installed"
    ["04-theming"]="Dotfiles deployed"
    ["05-external-drives"]="Basic system configured"
    ["06-brave-backup"]="User environment ready"
    ["07-ollama"]="System packages installed"
    ["08-virtualization"]="User permissions configured"
    ["09-optimization"]="Core system functional"
    ["10-user-setup"]="All major components installed"
    ["11-qbittorrent"]="Network and storage configured"
)

declare -A PHASE_ESTIMATED_TIME=(
    ["00-prerequisites"]="2-5 minutes"
    ["01-chaotic-aur"]="1-3 minutes"
    ["02-packages"]="15-45 minutes"
    ["03-dotfiles"]="2-5 minutes"
    ["04-theming"]="5-15 minutes"
    ["05-external-drives"]="1-5 minutes"
    ["06-brave-backup"]="1-3 minutes"
    ["07-ollama"]="10-30 minutes"
    ["08-virtualization"]="5-15 minutes"
    ["09-optimization"]="3-10 minutes"
    ["10-user-setup"]="2-5 minutes"
    ["11-qbittorrent"]="1-3 minutes"
)

# ============================================================================
# LOGGING & UTILITY FUNCTIONS
# ============================================================================

# Initialize logging system
init_logging() {
    mkdir -p "$LOG_DIR"
    {
        echo "=============================================="
        echo "Evil Space Dotfiles Installation Started"
        echo "Date: $(date)"
        echo "Script: $SCRIPT_NAME v$SCRIPT_VERSION"
        echo "Directory: $DOTFILES_DIR"
        echo "User: $USER"
        echo "=============================================="
    } >> "$LOG_FILE"
}

# Logging functions with both terminal and file output
log_info() {
    local msg="${1:-}"
    echo -e "${BLUE}${INFO} [INFO]${NC} $msg"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [INFO] $msg" >> "$LOG_FILE"
}

log_success() {
    local msg="${1:-}"
    echo -e "${GREEN}${CHECKMARK} [SUCCESS]${NC} $msg"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [SUCCESS] $msg" >> "$LOG_FILE"
}

log_error() {
    local msg="${1:-}"
    echo -e "${RED}${CROSSMARK} [ERROR]${NC} $msg" >&2
    echo "$(date +'%Y-%m-%d %H:%M:%S') [ERROR] $msg" >> "$LOG_FILE"
}

log_warning() {
    local msg="${1:-}"
    echo -e "${YELLOW}${WARNING} [WARNING]${NC} $msg"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [WARNING] $msg" >> "$LOG_FILE"
}

log_section() {
    local msg="${1:-}"
    echo
    echo -e "${CYAN}${BOLD}═══ $msg ═══${NC}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [SECTION] $msg" >> "$LOG_FILE"
}

log_phase() {
    local phase="${1:-}"
    local msg="${2:-}"
    echo
    echo -e "${PURPLE}${BOLD}${ROCKET} PHASE ${phase^^}: $msg${NC}"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [PHASE-$phase] $msg" >> "$LOG_FILE"
}

log_dry_run() {
    local msg="${1:-}"
    echo -e "${YELLOW}${BOLD}[DRY-RUN]${NC} $msg"
    echo "$(date +'%Y-%m-%d %H:%M:%S') [DRY-RUN] $msg" >> "$LOG_FILE"
}

# Progress display
show_progress() {
    local current="$1"
    local total="$2"
    local description="$3"
    local percent=$((current * 100 / total))
    local completed=$((current * 50 / total))
    local remaining=$((50 - completed))
    
    printf "\r${BLUE}[${NC}"
    printf "%*s" $completed '' | tr ' ' '█'
    printf "%*s" $remaining '' | tr ' ' '░'
    printf "${BLUE}] %3d%% ${NC}%s" $percent "$description"
}

# ============================================================================
# SYSTEM VALIDATION & PREREQUISITES
# ============================================================================

# Check if running on Arch Linux
validate_system() {
    log_section "System Validation"
    
    # Check for Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        log_error "This installer is designed for Arch Linux only!"
        echo -e "${RED}${BOLD}Detected system:${NC} $(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')"
        echo -e "${YELLOW}This installer is specifically designed for Arch Linux.${NC}"
        echo -e "${CYAN}If you're on a different distribution, you'll need to adapt the package installation commands.${NC}"
        exit 1
    fi
    log_success "Arch Linux detected"
    
    # Check internet connectivity
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        log_error "No internet connection detected!"
        echo -e "${YELLOW}Please ensure you have a working internet connection before proceeding.${NC}"
        exit 1
    fi
    log_success "Internet connectivity verified"
    
    # Check if running as regular user (not root)
    if [[ $EUID -eq 0 ]]; then
        log_error "Do not run this installer as root!"
        echo -e "${YELLOW}Please run as a regular user. The installer will prompt for sudo when needed.${NC}"
        exit 1
    fi
    log_success "Running as regular user: $USER"
    
    # Check sudo access
    if ! sudo -v >/dev/null 2>&1; then
        log_error "Sudo access required but not available!"
        echo -e "${YELLOW}Please ensure your user has sudo privileges.${NC}"
        echo -e "${CYAN}Add your user to wheel group: ${WHITE}usermod -aG wheel $USER${NC}"
        exit 1
    fi
    log_success "Sudo access verified"
    
    # Check available disk space (need at least 10GB)
    local available_space
    available_space=$(df /home | awk 'NR==2 {print $4}')
    local available_gb=$((available_space / 1024 / 1024))
    
    if [[ $available_gb -lt 10 ]]; then
        log_warning "Low disk space: ${available_gb}GB available"
        echo -e "${YELLOW}Recommended: At least 10GB free space for complete installation${NC}"
        if [[ "$INTERACTIVE" == "true" ]]; then
            echo -n -e "${CYAN}Continue anyway? [y/N]: ${NC}"
            read -r response
            if [[ ! "$response" =~ ^[Yy]$ ]]; then
                log_info "Installation cancelled by user due to disk space concerns"
                exit 0
            fi
        fi
    else
        log_success "Sufficient disk space: ${available_gb}GB available"
    fi
}

# ============================================================================
# STATE MANAGEMENT
# ============================================================================

# Save installation state
save_state() {
    local phase="$1"
    local status="$2"
    echo "${phase}:${status}:$(date +%s)" >> "$STATE_FILE"
    log_info "State saved: $phase = $status"
}

# Load installation state
load_state() {
    [[ ! -f "$STATE_FILE" ]] && return 0
    
    log_info "Loading previous installation state..."
    while IFS=: read -r phase status timestamp; do
        if [[ "$status" == "completed" ]]; then
            log_success "Previously completed: $phase"
        elif [[ "$status" == "failed" ]]; then
            log_warning "Previously failed: $phase"
        fi
    done < "$STATE_FILE"
}

# Check if phase was completed
is_phase_completed() {
    local phase="$1"
    [[ ! -f "$STATE_FILE" ]] && return 1
    grep -q "^${phase}:completed:" "$STATE_FILE"
}

# ============================================================================
# INTERACTIVE MENU SYSTEM
# ============================================================================

# Display main menu header
show_header() {
    clear
    echo -e "${PURPLE}${BOLD}"
    cat << 'EOF'
   ▄████████   ▄█    █▄   ▄█   ▄█               ▄████████    ▄███████▄    ▄████████  ▄████████    ▄████████ 
  ███    ███  ███    ███ ███  ███              ███    ███   ███    ███   ███    ███ ███    ███   ███    ███ 
  ███    █▀   ███    ███ ███▌ ███              ███    █▀    ███    ███   ███    ███ ███    █▀    ███    █▀  
 ▄███▄▄▄      ███    ███ ███▌ ███              ███          ███    ███   ███    ███ ███         ▄███▄▄▄     
▀▀███▀▀▀      ███    ███ ███▌ ███              ███        ▀█████████▀   ▀███████████ ███        ▀▀███▀▀▀     
  ███    █▄   ███    ███ ███  ███              ███    █▄    ███          ███    ███ ███    █▄    ███    █▄  
  ███    ███  ███    ███ ███  ███▌    ▄        ███    ███   ███          ███    ███ ███    ███   ███    ███ 
  ██████████   ▀██████▀  █▀   █████▄▄██        ████████▀   ▄████▀        ███    █▀  ████████▀    ██████████ 
                              ▀                                                                               
EOF
    echo -e "${NC}"
    echo -e "${CYAN}${BOLD}        🌌 EVIL SPACE DOTFILES - COMPLETE INSTALLATION SYSTEM 🌌${NC}"
    echo -e "${DIM}                     Arch Linux + Hyprland + Material Design 3${NC}"
    echo -e "${DIM}                          v$SCRIPT_VERSION - Interactive Installer${NC}"
    echo
}

# Show installation overview
show_overview() {
    # Check if this is a post-installation run
    local completed_phases=0
    local total_phases=${#PHASES[@]}
    
    for phase in "${!PHASES[@]}"; do
        if is_phase_completed "$phase"; then
            ((completed_phases++))
        fi
    done
    
    if [[ $completed_phases -gt 0 ]]; then
        echo -e "${YELLOW}${WARNING} ${BOLD}Post-Installation Mode Detected${NC}"
        echo -e "${GREEN}${CHECKMARK} Completed phases: $completed_phases/$total_phases${NC}"
        echo -e "${CYAN}This installer is safe to rerun for:${NC}"
        echo -e "   • Reinstalling dependencies and packages"
        echo -e "   • Adding external drives to /mnt and fstab"
        echo -e "   • Updating configurations safely"
        echo -e "   • Testing specific phases with dry-run"
        echo
        echo -e "${GREEN}${BOLD}All operations are idempotent and safe to repeat!${NC}"
        echo
    else
        echo -e "${WHITE}${BOLD}What This Installer Will Set Up:${NC}"
        echo
        echo -e "${GREEN}${CHECKMARK} Desktop Environment:${NC}"
        echo -e "   • Hyprland (Wayland compositor) with dynamic workspaces and animations"
        echo -e "   • Dual Waybar system (controls + AMD GPU monitoring)"
        echo -e "   • Material Design 3 dynamic theming from wallpapers"
        echo
        echo -e "${GREEN}${CHECKMARK} Core Applications:${NC}"
        echo -e "   • 397 packages across 6 categories (Essential, Development, Gaming, etc.)"
        echo -e "   • Kitty terminal with dynamic colors + Fish shell"
        echo -e "   • AI integration with Ollama (14+ models available)"
        echo
        echo -e "${GREEN}${CHECKMARK} Advanced Features:${NC}"
        echo -e "   • Real-time AMD GPU monitoring with visual indicators"
        echo -e "   • Automatic external drive management"
        echo -e "   • Browser backup/restore system"
        echo -e "   • Virtualization environment (QEMU/KVM)"
        echo
        echo -e "${CYAN}${BOLD}Total Installation Time:${NC} 45-90 minutes (depending on internet speed)"
        echo -e "${CYAN}${BOLD}Result:${NC} Complete production-ready desktop environment"
        echo
    fi
}

# Show phase selection menu
show_phase_menu() {
    echo -e "${WHITE}${BOLD}Installation Phases:${NC}"
    echo
    
    local counter=1
    for phase in $(printf '%s\n' "${!PHASES[@]}" | sort); do
        local status_symbol="${DIM}○${NC}"
        local status_text=""
        
        if is_phase_completed "$phase"; then
            status_symbol="${GREEN}${CHECKMARK}${NC}"
            status_text="${DIM} (completed)${NC}"
        fi
        
        printf "%2d. %s ${CYAN}%s${NC}\n" \
            "$counter" \
            "$status_symbol" \
            "${PHASES[$phase]}"
        
        printf "    ${DIM}Script: %s${NC}\n" "${PHASE_SCRIPTS[$phase]}"
        printf "    ${DIM}Time: %s | Requires: %s${NC}%s\n" \
            "${PHASE_ESTIMATED_TIME[$phase]}" \
            "${PHASE_REQUIREMENTS[$phase]}" \
            "$status_text"
        echo
        
        ((counter++))
    done
}

# Show main menu options
show_main_menu() {
    show_header
    show_overview
    show_phase_menu
    
    # Check if this is post-installation for different menu options
    local completed_phases=0
    for phase in "${!PHASES[@]}"; do
        if is_phase_completed "$phase"; then
            ((completed_phases++))
        fi
    done
    
    echo -e "${WHITE}${BOLD}Choose Installation Mode:${NC}"
    echo
    
    if [[ $completed_phases -gt 0 ]]; then
        echo -e "${GREEN} 1)${NC} 🔄 ${BOLD}Reinstall Dependencies${NC} - Safely reinstall all packages"
        echo -e "${BLUE} 2)${NC} 🗄️  ${BOLD}Setup External Drives${NC} - Add drives to /mnt and fstab"
        echo -e "${PURPLE} 3)${NC} 🎯 ${BOLD}Custom Phases${NC} - Select specific phases to rerun"
        echo -e "${YELLOW} 4)${NC} 🧪 ${BOLD}Dry-Run Test${NC} - Test any phase without making changes"
        echo -e "${CYAN} 5)${NC} 📊 ${BOLD}System Status${NC} - View current installation status"
        echo -e "${WHITE} 6)${NC} 🚀 ${BOLD}Force Complete${NC} - Rerun all phases (advanced)"
        echo -e "${RED} 7)${NC} ❌ ${BOLD}Exit${NC} - Exit installer"
    else
        echo -e "${GREEN} 1)${NC} 🚀 ${BOLD}Complete Installation${NC} - Run all phases automatically"
        echo -e "${BLUE} 2)${NC} 🎯 ${BOLD}Custom Installation${NC} - Select specific phases to run"
        echo -e "${YELLOW} 3)${NC} 🧪 ${BOLD}Dry-Run Test${NC} - Test installation without making changes"
        echo -e "${PURPLE} 4)${NC} 📊 ${BOLD}System Status${NC} - View current installation status"
        echo -e "${CYAN} 5)${NC} 🔧 ${BOLD}Resume Installation${NC} - Continue from where you left off"
        echo -e "${RED} 6)${NC} ❌ ${BOLD}Exit${NC} - Exit installer"
    fi
    echo
    echo -e "${DIM}Log file: $LOG_FILE${NC}"
    echo
}

# Get user choice
get_user_choice() {
    local choice
    local completed_phases=0
    
    # Check if post-installation mode
    for phase in "${!PHASES[@]}"; do
        if is_phase_completed "$phase"; then
            ((completed_phases++))
        fi
    done
    
    local max_choice=6
    if [[ $completed_phases -gt 0 ]]; then
        max_choice=7
    fi
    
    while true; do
        echo -n -e "${CYAN}${BOLD}Enter your choice [1-$max_choice]: ${NC}"
        read -r choice
        
        if [[ $completed_phases -gt 0 ]]; then
            case $choice in
                1) return 1 ;;  # Reinstall Dependencies
                2) return 2 ;;  # Setup External Drives
                3) return 3 ;;  # Custom Phases
                4) return 4 ;;  # Dry-run
                5) return 5 ;;  # Status
                6) return 6 ;;  # Force Complete
                7) return 7 ;;  # Exit
                *) 
                    echo -e "${RED}Invalid choice. Please enter 1-$max_choice.${NC}"
                    continue
                    ;;
            esac
        else
            case $choice in
                1) return 1 ;;  # Complete
                2) return 2 ;;  # Custom
                3) return 3 ;;  # Dry-run
                4) return 4 ;;  # Status
                5) return 5 ;;  # Resume
                6) return 6 ;;  # Exit
                *) 
                    echo -e "${RED}Invalid choice. Please enter 1-$max_choice.${NC}"
                    continue
                    ;;
            esac
        fi
    done
}

# Custom phase selection
select_custom_phases() {
    echo -e "${CYAN}${BOLD}Custom Installation - Select Phases${NC}"
    echo -e "${DIM}Enter phase numbers separated by spaces (e.g., 1 2 5) or 'all' for everything:${NC}"
    echo
    
    show_phase_menu
    
    local input
    echo -n -e "${CYAN}Enter your selection: ${NC}"
    read -r input
    
    if [[ "$input" == "all" ]]; then
        SELECTED_PHASES=($(printf '%s\n' "${!PHASES[@]}" | sort))
        log_info "Selected all phases for custom installation"
        return 0
    fi
    
    SELECTED_PHASES=()
    local phase_array=($(printf '%s\n' "${!PHASES[@]}" | sort))
    
    for num in $input; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#phase_array[@]} ]]; then
            local phase_index=$((num - 1))
            SELECTED_PHASES+=("${phase_array[$phase_index]}")
        else
            log_warning "Invalid phase number: $num"
        fi
    done
    
    if [[ ${#SELECTED_PHASES[@]} -eq 0 ]]; then
        log_error "No valid phases selected"
        return 1
    fi
    
    echo -e "${GREEN}Selected phases:${NC}"
    for phase in "${SELECTED_PHASES[@]}"; do
        echo -e "  • $phase: ${PHASES[$phase]}"
    done
    echo
    
    return 0
}

# Show system status
show_system_status() {
    clear
    show_header
    
    echo -e "${WHITE}${BOLD}Current System Status:${NC}"
    echo
    
    # System information
    echo -e "${CYAN}${BOLD}System Information:${NC}"
    echo -e "  OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')"
    echo -e "  Kernel: $(uname -r)"
    echo -e "  User: $USER"
    echo -e "  Shell: $SHELL"
    echo -e "  Directory: $DOTFILES_DIR"
    echo
    
    # Installation status
    echo -e "${CYAN}${BOLD}Installation Progress:${NC}"
    
    local completed_count=0
    local total_count=${#PHASES[@]}
    
    for phase in $(printf '%s\n' "${!PHASES[@]}" | sort); do
        if is_phase_completed "$phase"; then
            echo -e "  ${GREEN}${CHECKMARK} $phase: ${PHASES[$phase]}${NC}"
            ((completed_count++))
        else
            echo -e "  ${DIM}○ $phase: ${PHASES[$phase]}${NC}"
        fi
    done
    
    echo
    echo -e "${CYAN}Progress: $completed_count/$total_count phases completed${NC}"
    
    if [[ $completed_count -eq $total_count ]]; then
        echo -e "${GREEN}${BOLD}${SPARKLES} Installation Complete! ${SPARKLES}${NC}"
    elif [[ $completed_count -gt 0 ]]; then
        echo -e "${YELLOW}Installation in progress...${NC}"
    else
        echo -e "${BLUE}Installation not started${NC}"
    fi
    
    echo
    echo -e "${DIM}Press Enter to return to main menu...${NC}"
    read -r
}

# ============================================================================
# SCRIPT EXECUTION ENGINE
# ============================================================================

# Execute a single phase
execute_phase() {
    local phase="$1"
    local script_path="${DOTFILES_DIR}/${PHASE_SCRIPTS[$phase]}"
    
    log_phase "$phase" "${PHASES[$phase]}"
    
    # Check if script exists
    if [[ ! -f "$script_path" ]]; then
        log_error "Script not found: $script_path"
        return 1
    fi
    
    # Make script executable
    chmod +x "$script_path"
    
    # Skip if already completed (unless dry-run)
    if [[ "$DRY_RUN" == "false" ]] && is_phase_completed "$phase"; then
        log_success "Phase $phase already completed - skipping"
        return 0
    fi
    
    # Prepare execution command
    local exec_cmd="$script_path"
    
    # Add dry-run flag if supported
    if [[ "$DRY_RUN" == "true" ]]; then
        if grep -q "\-\-dry-run\|\-n" "$script_path"; then
            exec_cmd="$script_path --dry-run"
        else
            log_dry_run "Phase $phase: Would execute $script_path"
            return 0
        fi
    fi
    
    # Execute the script
    log_info "Executing: $exec_cmd"
    
    if [[ "$DRY_RUN" == "false" ]]; then
        # Record start time
        local start_time=$(date +%s)
        
        # Execute script and capture output
        if timeout 3600 bash -c "$exec_cmd" 2>&1 | tee -a "$LOG_FILE"; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            
            save_state "$phase" "completed"
            log_success "Phase $phase completed successfully in ${duration}s"
            return 0
        else
            local exit_code=$?
            save_state "$phase" "failed"
            log_error "Phase $phase failed with exit code $exit_code"
            return $exit_code
        fi
    else
        # Dry run
        if timeout 300 bash -c "$exec_cmd" 2>&1 | tee -a "$LOG_FILE"; then
            log_success "Dry-run for phase $phase completed successfully"
            return 0
        else
            log_error "Dry-run for phase $phase failed"
            return 1
        fi
    fi
}

# Execute multiple phases
execute_phases() {
    local phases=("$@")
    local total_phases=${#phases[@]}
    local current_phase=0
    local failed_phases=()
    
    log_section "Starting Installation Execution"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_dry_run "Executing $total_phases phases in dry-run mode"
    else
        log_info "Executing $total_phases phases"
    fi
    
    for phase in "${phases[@]}"; do
        ((current_phase++))
        
        echo
        show_progress "$current_phase" "$total_phases" "Phase $phase"
        echo
        
        if ! execute_phase "$phase"; then
            failed_phases+=("$phase")
            
            if [[ "$INTERACTIVE" == "true" ]] && [[ "$DRY_RUN" == "false" ]]; then
                echo
                echo -e "${RED}${BOLD}Phase $phase failed!${NC}"
                echo -e "${YELLOW}Options:${NC}"
                echo -e "  1) Continue with remaining phases"
                echo -e "  2) Retry this phase"
                echo -e "  3) Abort installation"
                echo
                echo -n -e "${CYAN}Your choice [1-3]: ${NC}"
                read -r choice
                
                case $choice in
                    1) 
                        log_warning "Continuing installation despite failure in phase $phase"
                        continue
                        ;;
                    2)
                        log_info "Retrying phase $phase"
                        ((current_phase--))
                        if execute_phase "$phase"; then
                            failed_phases=("${failed_phases[@]/$phase}")
                        fi
                        ;;
                    3)
                        log_error "Installation aborted by user after phase $phase failure"
                        break
                        ;;
                esac
            else
                log_error "Phase $phase failed - continuing with remaining phases"
            fi
        fi
    done
    
    echo
    show_progress "$total_phases" "$total_phases" "Installation complete"
    echo
    
    # Report final status
    if [[ ${#failed_phases[@]} -eq 0 ]]; then
        log_success "All phases completed successfully!"
        return 0
    else
        log_error "Installation completed with ${#failed_phases[@]} failed phases:"
        for phase in "${failed_phases[@]}"; do
            log_error "  • $phase: ${PHASES[$phase]}"
        done
        return 1
    fi
}

# ============================================================================
# MAIN INSTALLATION FLOWS
# ============================================================================

# Complete installation
run_complete_installation() {
    log_section "Complete Installation Mode"
    
    local all_phases=($(printf '%s\n' "${!PHASES[@]}" | sort))
    
    echo -e "${WHITE}${BOLD}Complete Installation${NC}"
    echo -e "${DIM}This will run all ${#all_phases[@]} installation phases automatically.${NC}"
    echo
    echo -e "${CYAN}Estimated total time: 45-90 minutes${NC}"
    echo -e "${CYAN}Packages to install: 397${NC}"
    echo -e "${CYAN}Disk space required: ~10GB${NC}"
    echo
    
    if [[ "$INTERACTIVE" == "true" ]]; then
        echo -n -e "${YELLOW}${BOLD}Are you ready to proceed? [y/N]: ${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Complete installation cancelled by user"
            return 0
        fi
    fi
    
    execute_phases "${all_phases[@]}"
}

# Custom installation
run_custom_installation() {
    log_section "Custom Installation Mode"
    
    if ! select_custom_phases; then
        return 1
    fi
    
    echo -e "${WHITE}${BOLD}Custom Installation${NC}"
    echo -e "${DIM}Selected ${#SELECTED_PHASES[@]} phases to execute.${NC}"
    echo
    
    if [[ "$INTERACTIVE" == "true" ]]; then
        echo -n -e "${YELLOW}${BOLD}Proceed with selected phases? [y/N]: ${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Custom installation cancelled by user"
            return 0
        fi
    fi
    
    execute_phases "${SELECTED_PHASES[@]}"
}

# Reinstall dependencies (maintenance mode)
run_reinstall_dependencies() {
    log_section "Dependency Reinstallation Mode"
    
    echo -e "${WHITE}${BOLD}Reinstall Dependencies${NC}"
    echo -e "${DIM}This will safely reinstall packages and dependencies.${NC}"
    echo -e "${GREEN}Safe to run multiple times - packages already installed will be skipped.${NC}"
    echo
    
    # Focus on package-related phases
    local package_phases=("00-prerequisites" "01-chaotic-aur" "02-packages")
    
    if [[ "$INTERACTIVE" == "true" ]]; then
        echo -n -e "${YELLOW}${BOLD}Proceed with dependency reinstallation? [y/N]: ${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Dependency reinstallation cancelled by user"
            return 0
        fi
    fi
    
    execute_phases "${package_phases[@]}"
}

# Setup external drives (maintenance mode)
run_setup_external_drives() {
    log_section "External Drives Setup Mode"
    
    echo -e "${WHITE}${BOLD}Setup External Drives${NC}"
    echo -e "${DIM}This will mount external drives to /mnt and add them to fstab.${NC}"
    echo -e "${GREEN}Safe to rerun - existing entries will be preserved.${NC}"
    echo
    
    if [[ "$INTERACTIVE" == "true" ]]; then
        echo -n -e "${YELLOW}${BOLD}Proceed with external drives setup? [y/N]: ${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "External drives setup cancelled by user"
            return 0
        fi
    fi
    
    execute_phases "05-external-drives"
}

# Force complete installation (maintenance mode)
run_force_complete() {
    log_section "Force Complete Installation Mode"
    
    echo -e "${YELLOW}${WARNING} ${BOLD}Advanced: Force Complete Installation${NC}"
    echo -e "${DIM}This will rerun ALL phases regardless of completion status.${NC}"
    echo -e "${YELLOW}Use this only if you need to force reinstall everything.${NC}"
    echo
    
    local all_phases=($(printf '%s\n' "${!PHASES[@]}" | sort))
    
    if [[ "$INTERACTIVE" == "true" ]]; then
        echo -e "${RED}${BOLD}WARNING: This will rerun all ${#all_phases[@]} phases!${NC}"
        echo -n -e "${YELLOW}${BOLD}Are you absolutely sure? [y/N]: ${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Force complete installation cancelled by user"
            return 0
        fi
    fi
    
    # Clear state file to force rerun
    rm -f "$STATE_FILE"
    execute_phases "${all_phases[@]}"
}

# Dry-run test
run_dry_run_test() {
    log_section "Dry-Run Test Mode"
    
    DRY_RUN=true
    
    echo -e "${YELLOW}${BOLD}${GEAR} Dry-Run Test Mode${NC}"
    echo -e "${DIM}This will test the installation process without making any changes.${NC}"
    echo -e "${DIM}Perfect for verifying everything works before actual installation.${NC}"
    echo
    
    echo -e "${CYAN}Select test scope:${NC}"
    echo -e "  1) Test all phases"
    echo -e "  2) Test specific phases"
    echo
    echo -n -e "${CYAN}Your choice [1-2]: ${NC}"
    read -r choice
    
    case $choice in
        1)
            local all_phases=($(printf '%s\n' "${!PHASES[@]}" | sort))
            log_info "Starting dry-run test of all phases"
            execute_phases "${all_phases[@]}"
            ;;
        2)
            if select_custom_phases; then
                log_info "Starting dry-run test of selected phases"
                execute_phases "${SELECTED_PHASES[@]}"
            fi
            ;;
        *)
            log_error "Invalid choice"
            return 1
            ;;
    esac
}

# Resume installation
run_resume_installation() {
    log_section "Resume Installation Mode"
    
    if [[ ! -f "$STATE_FILE" ]]; then
        echo -e "${YELLOW}No previous installation state found.${NC}"
        echo -e "${CYAN}Starting fresh installation instead...${NC}"
        sleep 2
        run_complete_installation
        return
    fi
    
    load_state
    
    local all_phases=($(printf '%s\n' "${!PHASES[@]}" | sort))
    local remaining_phases=()
    
    for phase in "${all_phases[@]}"; do
        if ! is_phase_completed "$phase"; then
            remaining_phases+=("$phase")
        fi
    done
    
    if [[ ${#remaining_phases[@]} -eq 0 ]]; then
        echo -e "${GREEN}${BOLD}${SPARKLES} Installation already complete! ${SPARKLES}${NC}"
        echo -e "${CYAN}All phases have been successfully completed.${NC}"
        return 0
    fi
    
    echo -e "${WHITE}${BOLD}Resume Installation${NC}"
    echo -e "${DIM}Found ${#remaining_phases[@]} incomplete phases:${NC}"
    echo
    
    for phase in "${remaining_phases[@]}"; do
        echo -e "  • $phase: ${PHASES[$phase]}"
    done
    
    echo
    if [[ "$INTERACTIVE" == "true" ]]; then
        echo -n -e "${YELLOW}${BOLD}Resume from where you left off? [y/N]: ${NC}"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Resume installation cancelled by user"
            return 0
        fi
    fi
    
    execute_phases "${remaining_phases[@]}"
}

# ============================================================================
# POST-INSTALLATION SUMMARY
# ============================================================================

show_installation_summary() {
    clear
    show_header
    
    echo -e "${GREEN}${BOLD}${SPARKLES} INSTALLATION COMPLETE! ${SPARKLES}${NC}"
    echo
    echo -e "${WHITE}${BOLD}Your Evil Space Desktop Environment is ready!${NC}"
    echo
    
    echo -e "${CYAN}${BOLD}What's Now Available:${NC}"
    echo -e "  ${GREEN}${CHECKMARK}${NC} Hyprland with dynamic workspaces and cosmic animations"
    echo -e "  ${GREEN}${CHECKMARK}${NC} Dual Waybar with real-time AMD GPU monitoring"
    echo -e "  ${GREEN}${CHECKMARK}${NC} Material Design 3 theming that adapts to wallpapers"
    echo -e "  ${GREEN}${CHECKMARK}${NC} AI integration with Ollama (local language models)"
    echo -e "  ${GREEN}${CHECKMARK}${NC} Complete development environment with 397 packages"
    echo -e "  ${GREEN}${CHECKMARK}${NC} Fish shell with intelligent completions and theming"
    echo
    
    echo -e "${YELLOW}${BOLD}Next Steps:${NC}"
    echo -e "  1. ${CYAN}Reboot your system${NC} to activate all services"
    echo -e "  2. ${CYAN}Log into Hyprland${NC} from your display manager"
    echo -e "  3. ${CYAN}Change wallpaper${NC} to see dynamic theming in action:"
    echo -e "     ${DIM}scripts/theming/wallpaper_manager.sh select${NC}"
    echo -e "  4. ${CYAN}Launch the dashboard${NC} for system monitoring:"
    echo -e "     ${DIM}dashboard${NC}"
    echo -e "  5. ${CYAN}Explore AI features${NC} with Ollama:"
    echo -e "     ${DIM}scripts/ai/ai-health.fish${NC}"
    echo
    
    echo -e "${PURPLE}${BOLD}Key Commands to Remember:${NC}"
    echo -e "  • ${WHITE}Super + Return${NC} - Open terminal"
    echo -e "  • ${WHITE}Super + D${NC} - Application launcher"
    echo -e "  • ${WHITE}Super + W${NC} - Wallpaper selector"
    echo -e "  • ${WHITE}dashboard${NC} - Launch web dashboard"
    echo -e "  • ${WHITE}scripts/git/dotfiles.fish sync${NC} - AI-powered git commits"
    echo
    
    echo -e "${DIM}Log file: $LOG_FILE${NC}"
    echo -e "${DIM}Configuration: $DOTFILES_DIR${NC}"
    echo
    echo -e "${GREEN}${BOLD}Welcome to the Evil Space! ${SKULL}${FIRE}${NC}"
}

# ============================================================================
# ARGUMENT PARSING
# ============================================================================

show_help() {
    cat << EOF
Evil Space Dotfiles Installer v$SCRIPT_VERSION

USAGE:
    $SCRIPT_NAME [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -d, --dry-run           Run in dry-run mode (test without changes)
    -y, --yes               Skip confirmation prompts
    -q, --quiet             Non-interactive mode
    --complete              Run complete installation
    --custom PHASES         Run custom phases (comma-separated)
    --resume                Resume installation from last checkpoint
    --status                Show installation status

EXAMPLES:
    $SCRIPT_NAME                           # Interactive menu
    $SCRIPT_NAME --complete --yes          # Unattended complete installation
    $SCRIPT_NAME --dry-run                 # Test installation
    $SCRIPT_NAME --custom 1,2,5           # Install specific phases
    $SCRIPT_NAME --resume                  # Continue from where you left off

PHASES:
EOF

    local counter=1
    for phase in $(printf '%s\n' "${!PHASES[@]}" | sort); do
        printf "    %2d. %s - %s\n" "$counter" "$phase" "${PHASES[$phase]}"
        ((counter++))
    done
    
    echo
    echo "For more information, visit: https://github.com/yourusername/dotfiles"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                log_info "Dry-run mode enabled"
                shift
                ;;
            -y|--yes)
                SKIP_CONFIRMATION=true
                INTERACTIVE=false
                log_info "Confirmation prompts disabled"
                shift
                ;;
            -q|--quiet)
                INTERACTIVE=false
                log_info "Non-interactive mode enabled"
                shift
                ;;
            --complete)
                SELECTED_PHASES=($(printf '%s\n' "${!PHASES[@]}" | sort))
                INTERACTIVE=false
                shift
                ;;
            --custom)
                if [[ -n "$2" ]]; then
                    IFS=',' read -ra PHASE_NUMBERS <<< "$2"
                    local phase_array=($(printf '%s\n' "${!PHASES[@]}" | sort))
                    SELECTED_PHASES=()
                    
                    for num in "${PHASE_NUMBERS[@]}"; do
                        if [[ "$num" =~ ^[0-9]+$ ]] && [[ $num -ge 1 ]] && [[ $num -le ${#phase_array[@]} ]]; then
                            local phase_index=$((num - 1))
                            SELECTED_PHASES+=("${phase_array[$phase_index]}")
                        fi
                    done
                    
                    INTERACTIVE=false
                    shift 2
                else
                    log_error "--custom requires phase numbers"
                    exit 1
                fi
                ;;
            --resume)
                START_FROM_PHASE="resume"
                INTERACTIVE=false
                shift
                ;;
            --status)
                show_system_status
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

# ============================================================================
# MAIN FUNCTION
# ============================================================================

main() {
    # Initialize
    init_logging
    parse_arguments "$@"
    
    # Non-interactive execution
    if [[ "$INTERACTIVE" == "false" ]]; then
        validate_system
        
        if [[ -n "$START_FROM_PHASE" ]]; then
            if [[ "$START_FROM_PHASE" == "resume" ]]; then
                run_resume_installation
            fi
        elif [[ ${#SELECTED_PHASES[@]} -gt 0 ]]; then
            execute_phases "${SELECTED_PHASES[@]}"
        else
            run_complete_installation
        fi
        
        if [[ "$DRY_RUN" == "false" ]]; then
            show_installation_summary
        fi
        return
    fi
    
    # Interactive menu loop
    while true; do
        show_main_menu
        get_user_choice
        local choice=$?
        
        # Check if this is post-installation mode
        local completed_phases=0
        for phase in "${!PHASES[@]}"; do
            if is_phase_completed "$phase"; then
                ((completed_phases++))
            fi
        done
        
        if [[ $completed_phases -gt 0 ]]; then
            # Post-installation menu
            case $choice in
                1) # Reinstall Dependencies
                    validate_system
                    run_reinstall_dependencies
                    ;;
                2) # Setup External Drives
                    validate_system
                    run_setup_external_drives
                    ;;
                3) # Custom Phases
                    validate_system
                    run_custom_installation
                    ;;
                4) # Dry-run test
                    run_dry_run_test
                    ;;
                5) # System status
                    show_system_status
                    ;;
                6) # Force Complete
                    validate_system
                    run_force_complete
                    ;;
                7) # Exit
                    log_info "Installer exited by user"
                    echo -e "${CYAN}Thanks for using Evil Space Dotfiles! ${SKULL}${NC}"
                    exit 0
                    ;;
            esac
        else
            # Fresh installation menu
            case $choice in
                1) # Complete installation
                    validate_system
                    run_complete_installation
                    if [[ "$DRY_RUN" == "false" ]]; then
                        show_installation_summary
                        break
                    fi
                    ;;
                2) # Custom installation
                    validate_system
                    run_custom_installation
                    ;;
                3) # Dry-run test
                    run_dry_run_test
                    ;;
                4) # System status
                    show_system_status
                    ;;
                5) # Resume installation
                    validate_system
                    run_resume_installation
                    ;;
                6) # Exit
                    log_info "Installer exited by user"
                    echo -e "${CYAN}Thanks for using Evil Space Dotfiles! ${SKULL}${NC}"
                    exit 0
                    ;;
            esac
        fi
        
        # Don't pause on status view (4 in fresh install, 5 in post-install)
        local status_choice=4
        if [[ $completed_phases -gt 0 ]]; then
            status_choice=5
        fi
        
        if [[ "$choice" -ne $status_choice ]]; then
            echo
            echo -e "${DIM}Press Enter to return to main menu...${NC}"
            read -r
        fi
    done
}

# ============================================================================
# EXECUTION
# ============================================================================

# Ensure we're in the dotfiles directory
cd "$DOTFILES_DIR"

# Run main function with all arguments
main "$@"