#!/bin/bash
# Automated NixOS Installation Script
# Run this on a fresh booted NixOS minimal ISO

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Configuration
REPO_URL="https://gitlab.com/marerm/dotfiles.git"
TARGET_DISK=""
HOSTNAME="nixos-test"
USERNAME="martin"
KEYBOARD_LAYOUT="sv-latin1"

# Interactive prompts
prompt_disk() {
    echo "DEBUG: Inside prompt_disk function"
    log_info "Available disks:"
    lsblk -d -o NAME,SIZE,TYPE | grep disk
    echo
    
    while true; do
        echo "DEBUG: Prompting for disk input"
        read -p "Enter target disk (e.g., sda, nvme0n1): " disk_input
        echo "DEBUG: User entered: '$disk_input'"
        TARGET_DISK="/dev/$disk_input"
        echo "DEBUG: Set TARGET_DISK to: $TARGET_DISK"
        
        if [[ -b "$TARGET_DISK" ]]; then
            echo "DEBUG: Disk $TARGET_DISK exists"
            log_warning "This will COMPLETELY ERASE $TARGET_DISK!"
            log_warning "$(lsblk $TARGET_DISK)"
            read -p "Continue? (yes/no): " confirm
            echo "DEBUG: User confirmation: '$confirm'"
            
            if [[ "$confirm" == "yes" ]]; then
                echo "DEBUG: User confirmed, breaking from loop"
                break
            fi
        else
            echo "DEBUG: Disk $TARGET_DISK not found"
            log_error "Disk $TARGET_DISK not found!"
        fi
    done
    echo "DEBUG: Exiting prompt_disk with TARGET_DISK=$TARGET_DISK"
}

prompt_settings() {
    echo "DEBUG: Inside prompt_settings function"
    log_info "Current settings:"
    echo "  Disk: $TARGET_DISK"
    echo "  Hostname: $HOSTNAME"
    echo "  Username: $USERNAME"
    echo "  Keyboard: $KEYBOARD_LAYOUT"
    echo
    
    echo "DEBUG: About to prompt for hostname"
    read -p "Change hostname? (current: $HOSTNAME): " new_hostname
    echo "DEBUG: Hostname input: '$new_hostname'"
    [[ -n "$new_hostname" ]] && HOSTNAME="$new_hostname"
    echo "DEBUG: Hostname set to: $HOSTNAME"
    
    echo "DEBUG: About to prompt for username"
    read -p "Change username? (current: $USERNAME): " new_username
    echo "DEBUG: Username input: '$new_username'"
    [[ -n "$new_username" ]] && USERNAME="$new_username"
    echo "DEBUG: Username set to: $USERNAME"
    
    echo "DEBUG: About to prompt for keyboard layout"
    read -p "Change keyboard layout? (current: $KEYBOARD_LAYOUT): " new_keyboard
    echo "DEBUG: Keyboard input: '$new_keyboard'"
    [[ -n "$new_keyboard" ]] && KEYBOARD_LAYOUT="$new_keyboard"
    echo "DEBUG: Keyboard layout set to: $KEYBOARD_LAYOUT"
    echo "DEBUG: Exiting prompt_settings"
}

setup_environment() {
    log_info "Setting up installation environment..."
    
    # Set keyboard layout
    loadkeys "$KEYBOARD_LAYOUT"
    
    # Enable flakes
    mkdir -p /etc/nix
    echo "experimental-features = nix-command flakes" > /etc/nix/nix.conf
    
    # Test network
    if ! ping -c 3 8.8.8.8 >/dev/null 2>&1; then
        log_error "No internet connection! Please set up network first."
        log_info "For WiFi: systemctl start wpa_supplicant && wpa_cli"
        exit 1
    fi
    
    log_success "Environment ready"
}

partition_disk() {
    log_info "Partitioning disk $TARGET_DISK..."
    
    # Create GPT partition table
    parted "$TARGET_DISK" -- mklabel gpt
    
    # Create partitions
    parted "$TARGET_DISK" -- mkpart ESP fat32 1MiB 512MiB
    parted "$TARGET_DISK" -- set 1 esp on
    parted "$TARGET_DISK" -- mkpart primary 512MiB -8GiB
    parted "$TARGET_DISK" -- mkpart primary linux-swap -8GiB 100%
    
    # Wait for partitions to be recognized
    sleep 2
    partprobe "$TARGET_DISK"
    sleep 2
    
    # Determine partition names
    if [[ "$TARGET_DISK" =~ nvme ]]; then
        BOOT_PART="${TARGET_DISK}p1"
        ROOT_PART="${TARGET_DISK}p2"
        SWAP_PART="${TARGET_DISK}p3"
    else
        BOOT_PART="${TARGET_DISK}1"
        ROOT_PART="${TARGET_DISK}2"
        SWAP_PART="${TARGET_DISK}3"
    fi
    
    log_success "Partitions created"
}

format_filesystems() {
    log_info "Formatting filesystems..."
    
    # Format partitions
    mkfs.fat -F 32 -n boot "$BOOT_PART"
    mkfs.ext4 -L nixos "$ROOT_PART"
    mkswap -L swap "$SWAP_PART"
    
    # Mount filesystems
    mount /dev/disk/by-label/nixos /mnt
    mkdir -p /mnt/boot
    mount /dev/disk/by-label/boot /mnt/boot
    swapon /dev/disk/by-label/swap
    
    log_success "Filesystems ready"
}

clone_dotfiles() {
    log_info "Cloning dotfiles repository..."
    
    # Install git
    nix-shell -p git --run "
        cd /mnt && 
        git clone $REPO_URL dotfiles
    "
    
    if [[ ! -d /mnt/dotfiles/nixos-migration ]]; then
        log_error "Failed to clone dotfiles or nixos-migration directory not found!"
        exit 1
    fi
    
    log_success "Dotfiles cloned"
}

setup_configuration() {
    log_info "Setting up NixOS configuration..."
    
    # Generate hardware config
    nixos-generate-config --root /mnt
    
    # Backup generated hardware config
    cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/hardware-configuration.nix.generated
    
    # Copy our configuration
    cp -r /mnt/dotfiles/nixos-migration/system/* /mnt/etc/nixos/
    cp /mnt/dotfiles/nixos-migration/flake.nix /mnt/etc/nixos/
    
    # Restore hardware configuration
    cp /mnt/etc/nixos/hardware-configuration.nix.generated /mnt/etc/nixos/hardware-configuration.nix
    
    # Update configuration for this installation
    sed -i "s/nixos-hyprland/$HOSTNAME/" /mnt/etc/nixos/configuration.nix
    sed -i "s/martin/$USERNAME/" /mnt/etc/nixos/configuration.nix
    
    log_success "Configuration ready"
}

install_nixos() {
    log_info "Installing NixOS (this will take 20-30 minutes)..."
    
    # Install NixOS
    nixos-install --flake "/mnt/etc/nixos#$HOSTNAME"
    
    log_success "NixOS installed!"
}

set_passwords() {
    log_info "Setting up user passwords..."
    
    echo "Set root password:"
    nixos-enter --root /mnt -c "passwd"
    
    echo "Set user password for $USERNAME:"
    nixos-enter --root /mnt -c "passwd $USERNAME"
    
    log_success "Passwords set"
}

finalize_installation() {
    log_info "Finalizing installation..."
    
    # Copy dotfiles to user home
    mkdir -p "/mnt/home/$USERNAME"
    cp -r /mnt/dotfiles "/mnt/home/$USERNAME/"
    nixos-enter --root /mnt -c "chown -R $USERNAME:users /home/$USERNAME/dotfiles"
    
    log_success "Installation complete!"
    echo
    log_success "🎉 NixOS installation finished!"
    echo
    log_info "Next steps after reboot:"
    echo "1. Log in as '$USERNAME'"
    echo "2. Set up Home Manager:"
    echo "   mkdir -p ~/.config/home-manager"
    echo "   cp -r ~/dotfiles/nixos-migration/home/* ~/.config/home-manager/"
    echo "   home-manager switch --flake ~/.config/home-manager#$USERNAME"
    echo "3. Start Hyprland desktop environment"
    echo
    log_warning "Remove the installation USB and reboot!"
}

main() {
    echo "DEBUG: Starting main function"
    log_info "🚀 NixOS Automated Installation"
    echo
    log_warning "This script will:"
    echo "  1. Partition and format the target disk (DESTRUCTIVE!)"
    echo "  2. Install NixOS with your dotfiles configuration"
    echo "  3. Set up users and passwords"
    echo
    
    echo "DEBUG: Checking if running on NixOS installer"
    # Check if running on NixOS installer
    if [[ ! -f /etc/NIXOS ]]; then
        log_error "This script must be run on NixOS installer!"
        exit 1
    fi
    echo "DEBUG: NixOS installer check passed"
    
    # Interactive setup
    echo "DEBUG: About to call prompt_disk"
    prompt_disk
    echo "DEBUG: prompt_disk completed"
    
    echo "DEBUG: About to call prompt_settings"
    prompt_settings
    echo "DEBUG: prompt_settings completed"
    
    echo
    log_warning "Final confirmation:"
    echo "  Target disk: $TARGET_DISK (WILL BE ERASED!)"
    echo "  Hostname: $HOSTNAME"
    echo "  Username: $USERNAME"
    echo "  Keyboard: $KEYBOARD_LAYOUT"
    echo
    
    read -p "Proceed with installation? (yes/no): " final_confirm
    if [[ "$final_confirm" != "yes" ]]; then
        log_info "Installation cancelled."
        exit 0
    fi
    
    # Run installation
    setup_environment
    partition_disk
    format_filesystems
    clone_dotfiles
    setup_configuration
    install_nixos
    set_passwords
    finalize_installation
}

# Show help
show_help() {
    echo "NixOS Automated Installation Script"
    echo
    echo "Usage: $0 [options]"
    echo
    echo "This script automates the entire NixOS installation process"
    echo "using your dotfiles configuration."
    echo
    echo "Run this on a fresh booted NixOS minimal ISO."
    echo
    echo "Options:"
    echo "  -h, --help     Show this help"
    echo
    echo "The script will:"
    echo "  1. Set up keyboard layout and environment"
    echo "  2. Partition and format target disk"
    echo "  3. Clone dotfiles from GitLab"
    echo "  4. Install NixOS with your configuration"
    echo "  5. Set up users and passwords"
}

# Parse arguments
echo "DEBUG: Script started, parsing arguments"
echo "DEBUG: Arguments: $@"
case "${1:-}" in
    -h|--help)
        echo "DEBUG: Showing help"
        show_help
        exit 0
        ;;
    *)
        echo "DEBUG: About to call main function"
        main "$@"
        echo "DEBUG: Main function completed"
        ;;
esac