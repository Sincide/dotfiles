#!/bin/bash

# Comprehensive Package Installation Script
# Author: Martin's Dotfiles - Modular Version
# Description: Install all package categories using yay with full output visibility

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
readonly LOG_DIR="${DOTFILES_DIR}/logs"
readonly LOG_FILE="${LOG_DIR}/packages_$(date +%Y%m%d_%H%M%S).log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Flags
INSTALL_ESSENTIAL=true
INSTALL_DEVELOPMENT=true
INSTALL_THEMING=true
INSTALL_MULTIMEDIA=true
INSTALL_GAMING=true
INSTALL_OPTIONAL=true
DRY_RUN=false
SKIP_CONFIRMATION=false

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    echo "Starting package installation - $(date)" >> "$LOG_FILE"
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
    
    # Check if yay is installed
    if ! command -v yay &>/dev/null; then
        log_error "yay is not installed. Please run 00-prerequisites.sh first"
        exit 1
    fi
    log_success "yay is available"
    
    # Check if running on Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        log_error "Not running on Arch Linux"
        exit 1
    fi
    
    # Check sudo access
    if ! sudo -v &>/dev/null; then
        log_error "No sudo access"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Install packages from array with full output
install_packages() {
    local category="$1"
    shift
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warning "No packages to install for $category"
        return 0
    fi
    
    log_section "Installing $category Packages (${#packages[@]} packages)"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN - Would install:"
        for pkg in "${packages[@]}"; do
            echo "  • $pkg"
        done
        return 0
    fi
    
    local failed_packages=()
    local installed_count=0
    
    for package in "${packages[@]}"; do
        echo
        log_info "Installing: $package"
        
        # Check if already installed
        if yay -Q "$package" &>/dev/null; then
            log_success "$package is already installed"
            installed_count=$((installed_count + 1))
            continue
        fi
        
        # Install with full output visibility and conflict handling
        if yay -S --needed --noconfirm --overwrite '*' "$package"; then
            log_success "$package installed successfully"
            installed_count=$((installed_count + 1))
        else
            log_error "Failed to install: $package"
            failed_packages+=("$package")
        fi
    done
    
    echo
    log_success "$category: $installed_count/${#packages[@]} packages processed"
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_warning "Failed packages in $category:"
        for pkg in "${failed_packages[@]}"; do
            echo "  ✗ $pkg"
        done
    fi
}

# Package lists - EDIT THESE TO CUSTOMIZE YOUR INSTALLATION
# Comment out packages you don't want by adding # at the beginning of the line

# Essential System Packages
get_essential_packages() {
    local packages=(
        # Base system
        "base-devel"
        "git"
        "curl"
        "wget"
        "unzip"
        "tree"
        "htop"
        "btop"
        "fastfetch"
        "starship"
        "gum"
        "bc"
        "pacman-contrib"
        
        # Network and system utilities
        "networkmanager"
        "network-manager-applet"
        "bluez"
        "bluez-utils"
        "openssh"
        "rsync"
        
        # Audio
        "pipewire"
        "pipewire-alsa"
        "pipewire-pulse"
        "pipewire-jack"
        "wireplumber"
        "pavucontrol"
        
        # Display and wayland
        "wayland"
        "wayland-protocols"
        "xorg-xwayland"
        "xorg-xlsclients"
        "qt5-wayland"
        "qt6-wayland"
        
        # Hyprland and core WM components
        "hyprland"
        "waybar"
        "dunst"
        "fuzzel"
        "grim"
        "slurp"
        "swappy"
        "wl-clipboard"
        "polkit-gnome"
        
        # Fonts
        "ttf-jetbrains-mono-nerd"
        "noto-fonts"
        "noto-fonts-emoji"
        "ttf-liberation"
        "ttf-dejavu"
        
        # File management
        "ranger"
        "nemo"
        "nemo-fileroller"
        "cinnamon-desktop"
        "tumbler"
        "file-roller"
        
        # Text editors
        "nano"
        "vim"
        "micro"
        
        # System monitoring
        "lm_sensors"
        "acpi"
        "upower"
        
        # Archive support
        "p7zip"
        "unrar"
    )
    printf '%s\n' "${packages[@]}"
}

# Development Packages
get_development_packages() {
    local packages=(
        # Programming languages
        "python"
        #"python-pip"
        "nodejs"
        "npm"
        "rust"
        "go"
        "lua"
        
        # Build tools and compilers
        "gcc"
        "clang"
        "cmake"
        "make"
        "ninja"
        "meson"
        
        # Version control
        "git-lfs"
        "github-cli"
        "lazygit"
        
        # Text editors and IDEs
        "neovim"
        # "code"  # Uncomment if you want VS Code
        "cursor-bin"
        
        # Development tools
        "ripgrep"
        "fd"
        "fzf"
        "eza"
        "bat"
        "zoxide"
        
        # AI and Machine Learning
        "ollama"
        
        # Container tools
        "docker"
        "docker-compose"
        "podman"
        
        # Network tools
        "wireshark-qt"
        "nmap"
        "tcpdump"
        
        # Terminal tools
        "kitty"
        "fish"
        "tmux"
        "zellij"
        
        # Documentation
        "man-db"
        "man-pages"
        "tldr"
        
        # Performance profiling
        "perf"
    )
    printf '%s\n' "${packages[@]}"
}

# Theming Packages
get_theming_packages() {
    local packages=(
        # Color and theming tools
        "matugen"
        "imagemagick"
        "feh"
        
        # Icon themes
        "papirus-icon-theme"
        "breeze-icons"
        "adwaita-icon-theme"
        
        # GTK themes
        "arc-gtk-theme"
        "materia-gtk-theme"
        
        # Cursor themes
        "bibata-cursor-theme"
        "capitaine-cursors"
        
        # Wallpaper tools
        "swww"
        
        # Font management
        "fontconfig"
        "font-manager"
        
        # Additional fonts
        "ttf-fira-code"
        "ttf-font-awesome"
        "ttf-material-design-icons"
        "ttf-roboto"
        "ttf-ubuntu-font-family"
        "inter-font"
        "ttf-cascadia-code"
        
        # Terminal theming
        "lolcat"
        "figlet"
        "cowsay"
        
        # Screenshot and recording
        "peek"
        
        # Theme tools
        "qt5ct"
        "qt6ct"
        
        # Additional theming utilities
        "pokemon-colorscripts-git"
        "cava"
        "pipes.sh"
    )
    printf '%s\n' "${packages[@]}"
}

# Multimedia Packages
get_multimedia_packages() {
    local packages=(
        # Essential media tools
        "mpv"
        "feh"
        "ffmpeg"
        "gstreamer"
        "gst-plugins-base"
        "gst-plugins-good"
        "webp-pixbuf-loader"
        "yt-dlp"
        
        # Additional media players
        "vlc"
        "celluloid"
        #"spotify"
        
        # Creative tools
        #"simplescreenrecorder"
        
        # Uncomment packages you want:
        # "libreoffice-fresh"
        # "gimp"
        # "inkscape"
        # "krita"
        # "kdenlive"
        # "blender"
        # "audacity"
    )
    printf '%s\n' "${packages[@]}"
}

# Gaming Packages
get_gaming_packages() {
    local packages=(
        # Essential gaming
        "steam"
        "gamemode"
        "lib32-gamemode"
        "mangohud"
        "lib32-mangohud"
        "wine"
        "winetricks"
        
        # Gaming tools
        "dxvk-bin"
        "vkd3d"
        "goverlay"
        "corectrl"
        "discord"
        
        # Performance monitoring
        "radeontop"
        
        # Uncomment packages you want:
        # "lutris"
        # "heroic-games-launcher-bin"
        # "bottles"
        # "retroarch"
        # "nvtop"
    )
    printf '%s\n' "${packages[@]}"
}

# Optional Packages
get_optional_packages() {
    local packages=(
        # Communication
        "signal-desktop"
        "telegram-desktop"
        
        # Browsers
        "brave-bin"
        
        # Cloud storage
        "rclone"
        
        # Virtualization
        "qemu"
        "virt-manager"
        
        # Network utilities
        "putty"
        "filezilla"
        "remmina"
        
        # Password managers
        "bitwarden"
        
        # Social media
        "whatsapp-for-linux"
        
        # System information
        "cpu-x"
        
        # Backup tools
        "rsync"
        
        # Partition tools
        "gnome-disk-utility"
        
        # Torrents
        "qbittorrent"
        
        # Uncomment packages you want:
        # "firefox"
        # "chromium"
        # "virtualbox"
        # "obsidian"
        # "keepassxc"
        # "timeshift"
        # "gparted"
    )
    printf '%s\n' "${packages[@]}"
}

# Show usage
show_usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Comprehensive package installation script for all categories.

OPTIONS:
    -h, --help              Show this help message
    -n, --dry-run           Show what would be installed without installing
    -y, --yes               Skip confirmation prompts
    --no-essential          Skip essential packages
    --no-development        Skip development packages
    --no-theming            Skip theming packages
    --no-multimedia         Skip multimedia packages
    --no-gaming             Skip gaming packages
    --no-optional           Skip optional packages
    --log-dir DIR           Custom log directory (default: ~/dotfiles/logs)
    --dotfiles-dir DIR      Custom dotfiles directory (default: auto-detect)

DESCRIPTION:
    This script installs packages from all categories using yay with full
    output visibility. Edit the package arrays in the script to customize
    which packages are installed by commenting/uncommenting lines.

CATEGORIES:
    • Essential:    Core system packages (Hyprland, audio, fonts, etc.)
    • Development:  Programming tools, languages, IDEs
    • Theming:      GTK themes, icons, cursors, fonts
    • Multimedia:   Media players, codecs, creative tools
    • Gaming:       Steam, wine, gaming utilities
    • Optional:     Browsers, communication, utilities

EXAMPLES:
    $SCRIPT_NAME                           # Install all categories
    $SCRIPT_NAME --no-gaming --no-optional # Skip gaming and optional
    $SCRIPT_NAME -n                        # Dry run to see packages
    $SCRIPT_NAME -y                        # Install without confirmations

CUSTOMIZATION:
    Edit the get_*_packages() functions in this script to customize which
    packages are installed. Comment out lines with # to skip packages.

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
            --no-essential)
                INSTALL_ESSENTIAL=false
                shift
                ;;
            --no-development)
                INSTALL_DEVELOPMENT=false
                shift
                ;;
            --no-theming)
                INSTALL_THEMING=false
                shift
                ;;
            --no-multimedia)
                INSTALL_MULTIMEDIA=false
                shift
                ;;
            --no-gaming)
                INSTALL_GAMING=false
                shift
                ;;
            --no-optional)
                INSTALL_OPTIONAL=false
                shift
                ;;
            --log-dir)
                if [[ -n "${2:-}" ]]; then
                    LOG_DIR="$2"
                    LOG_FILE="${LOG_DIR}/packages_$(date +%Y%m%d_%H%M%S).log"
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

# Show installation summary
show_summary() {
    log_section "Installation Summary"
    
    local categories=()
    [[ "$INSTALL_ESSENTIAL" == "true" ]] && categories+=("Essential")
    [[ "$INSTALL_DEVELOPMENT" == "true" ]] && categories+=("Development")
    [[ "$INSTALL_THEMING" == "true" ]] && categories+=("Theming")
    [[ "$INSTALL_MULTIMEDIA" == "true" ]] && categories+=("Multimedia")
    [[ "$INSTALL_GAMING" == "true" ]] && categories+=("Gaming")
    [[ "$INSTALL_OPTIONAL" == "true" ]] && categories+=("Optional")
    
    if [[ ${#categories[@]} -eq 0 ]]; then
        log_warning "No categories selected for installation"
        return 0
    fi
    
    log_info "Selected categories: ${categories[*]}"
    
    # Count total packages
    local total_packages=0
    [[ "$INSTALL_ESSENTIAL" == "true" ]] && total_packages=$((total_packages + $(get_essential_packages | wc -l)))
    [[ "$INSTALL_DEVELOPMENT" == "true" ]] && total_packages=$((total_packages + $(get_development_packages | wc -l)))
    [[ "$INSTALL_THEMING" == "true" ]] && total_packages=$((total_packages + $(get_theming_packages | wc -l)))
    [[ "$INSTALL_MULTIMEDIA" == "true" ]] && total_packages=$((total_packages + $(get_multimedia_packages | wc -l)))
    [[ "$INSTALL_GAMING" == "true" ]] && total_packages=$((total_packages + $(get_gaming_packages | wc -l)))
    [[ "$INSTALL_OPTIONAL" == "true" ]] && total_packages=$((total_packages + $(get_optional_packages | wc -l)))
    
    log_info "Total packages to process: $total_packages"
    
    if [[ "$SKIP_CONFIRMATION" != "true" && "$DRY_RUN" != "true" ]]; then
        echo
        read -p "Continue with installation? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled by user"
            exit 0
        fi
    fi
}

# Main function
main() {
    parse_args "$@"
    init_logging
    
    echo "=== Comprehensive Package Installation ==="
    echo "Log file: $LOG_FILE"
    echo "Dotfiles directory: $DOTFILES_DIR"
    echo
    
    check_prerequisites
    show_summary
    
    echo
    log_info "Starting package installation with full yay output visibility..."
    
    # Install packages by category
    if [[ "$INSTALL_ESSENTIAL" == "true" ]]; then
        readarray -t essential_packages < <(get_essential_packages)
        install_packages "Essential" "${essential_packages[@]}"
    fi
    
    if [[ "$INSTALL_DEVELOPMENT" == "true" ]]; then
        readarray -t development_packages < <(get_development_packages)
        install_packages "Development" "${development_packages[@]}"
    fi
    
    if [[ "$INSTALL_THEMING" == "true" ]]; then
        readarray -t theming_packages < <(get_theming_packages)
        install_packages "Theming" "${theming_packages[@]}"
    fi
    
    if [[ "$INSTALL_MULTIMEDIA" == "true" ]]; then
        readarray -t multimedia_packages < <(get_multimedia_packages)
        install_packages "Multimedia" "${multimedia_packages[@]}"
    fi
    
    if [[ "$INSTALL_GAMING" == "true" ]]; then
        readarray -t gaming_packages < <(get_gaming_packages)
        install_packages "Gaming" "${gaming_packages[@]}"
    fi
    
    if [[ "$INSTALL_OPTIONAL" == "true" ]]; then
        readarray -t optional_packages < <(get_optional_packages)
        install_packages "Optional" "${optional_packages[@]}"
    fi
    
    echo
    if [[ "$DRY_RUN" == "true" ]]; then
        log_success "Dry run completed - no packages were installed"
    else
        log_success "Package installation completed!"
    fi
    echo "Log file: $LOG_FILE"
    echo
    log_info "To customize packages, edit the get_*_packages() functions in this script"
    log_info "Comment out packages you don't want with # at the beginning of the line"
}

# Run main function
main "$@" 