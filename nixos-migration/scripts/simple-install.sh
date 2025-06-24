#!/bin/bash
# Simple NixOS Installation Script
# Just installs NixOS with basic config, no flakes complications

set -euo pipefail

# Colors
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
TARGET_DISK=""
HOSTNAME="nixos-test"
USERNAME="martin"

# Simple disk selection
select_disk() {
    log_info "Available disks:"
    lsblk -d -o NAME,SIZE,TYPE | grep disk
    echo
    
    while true; do
        read -p "Enter target disk (e.g., vda, sda): " disk_input
        TARGET_DISK="/dev/$disk_input"
        
        if [[ -b "$TARGET_DISK" ]]; then
            log_warning "This will COMPLETELY ERASE $TARGET_DISK!"
            lsblk "$TARGET_DISK"
            read -p "Continue? (yes/no): " confirm
            
            if [[ "$confirm" == "yes" ]]; then
                break
            fi
        else
            log_error "Disk $TARGET_DISK not found!"
        fi
    done
}

# Simple settings
get_settings() {
    echo "DEBUG: Starting get_settings"
    
    echo "DEBUG: Prompting for hostname"
    read -p "Hostname (default: $HOSTNAME): " new_hostname
    echo "DEBUG: Hostname input: '$new_hostname'"
    [[ -n "$new_hostname" ]] && HOSTNAME="$new_hostname"
    echo "DEBUG: Hostname set to: $HOSTNAME"
    
    echo "DEBUG: Prompting for username"
    read -p "Username (default: $USERNAME): " new_username
    echo "DEBUG: Username input: '$new_username'"
    [[ -n "$new_username" ]] && USERNAME="$new_username"
    echo "DEBUG: Username set to: $USERNAME"
    
    echo "DEBUG: Exiting get_settings"
}

# Partition disk
partition_disk() {
    log_info "Partitioning $TARGET_DISK..."
    
    # Create partitions
    parted "$TARGET_DISK" -- mklabel gpt
    parted "$TARGET_DISK" -- mkpart ESP fat32 1MiB 512MiB
    parted "$TARGET_DISK" -- set 1 esp on
    parted "$TARGET_DISK" -- mkpart primary 512MiB -8GiB
    parted "$TARGET_DISK" -- mkpart primary linux-swap -8GiB 100%
    
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

# Format filesystems
format_disk() {
    log_info "Formatting filesystems..."
    
    echo "DEBUG: Formatting boot partition: $BOOT_PART"
    mkfs.fat -F 32 -n boot "$BOOT_PART"
    echo "DEBUG: Boot partition formatted"
    
    echo "DEBUG: Formatting root partition: $ROOT_PART"
    mkfs.ext4 -L nixos "$ROOT_PART"
    echo "DEBUG: Root partition formatted"
    
    echo "DEBUG: Setting up swap: $SWAP_PART"
    mkswap -L swap "$SWAP_PART"
    echo "DEBUG: Swap formatted"
    
    # Mount
    echo "DEBUG: Mounting root partition"
    mount /dev/disk/by-label/nixos /mnt
    echo "DEBUG: Root mounted"
    
    echo "DEBUG: Creating boot directory"
    mkdir -p /mnt/boot
    echo "DEBUG: Boot directory created"
    
    echo "DEBUG: Mounting boot partition"
    mount /dev/disk/by-label/boot /mnt/boot
    echo "DEBUG: Boot mounted"
    
    echo "DEBUG: Enabling swap"
    swapon /dev/disk/by-label/swap
    echo "DEBUG: Swap enabled"
    
    log_success "Filesystems ready"
}

# Generate basic configuration
setup_config() {
    log_info "Setting up basic NixOS configuration..."
    
    # Generate hardware config
    nixos-generate-config --root /mnt
    
    # Create simple configuration.nix
    cat > /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "$HOSTNAME";
  networking.networkmanager.enable = true;

  # Time zone
  time.timeZone = "Europe/Stockholm";

  # Internationalization
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "sv-latin1";
  };

  # Enable sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable Hyprland
  programs.hyprland.enable = true;

  # XDG portal
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

  # User account
  users.users.$USERNAME = {
    isNormalUser = true;
    description = "$USERNAME";
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    shell = pkgs.fish;
  };

  # Enable sudo
  security.sudo.wheelNeedsPassword = true;

  # System packages (minimal)
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    firefox
    kitty
    home-manager
    fish
  ];

  # Enable fish shell
  programs.fish.enable = true;

  # This value determines the NixOS release
  system.stateVersion = "24.05";
}
EOF

    log_success "Basic configuration created"
}

# Install NixOS
install_system() {
    log_info "Installing NixOS (this will take 20-30 minutes)..."
    
    nixos-install
    
    log_success "NixOS installed!"
}

# Set passwords
set_passwords() {
    log_info "Setting passwords..."
    
    echo "Set root password:"
    nixos-enter --root /mnt -c "passwd"
    
    echo "Set user password for $USERNAME:"
    nixos-enter --root /mnt -c "passwd $USERNAME"
    
    log_success "Passwords set"
}

# Main installation
main() {
    echo "DEBUG: Starting main function"
    log_info "🚀 Simple NixOS Installation"
    echo
    log_warning "This will install a basic NixOS system."
    log_info "Advanced configuration will be done after reboot."
    echo
    
    echo "DEBUG: Checking if root"
    # Check if root
    if [[ $EUID -ne 0 ]]; then
        log_error "Run as root: sudo bash simple-install.sh"
        exit 1
    fi
    echo "DEBUG: Root check passed"
    
    echo "DEBUG: Checking NixOS installer"
    # Check NixOS installer
    if [[ ! -f /etc/NIXOS ]]; then
        log_error "Must be run on NixOS installer!"
        exit 1
    fi
    echo "DEBUG: NixOS installer check passed"
    
    echo "DEBUG: Testing network"
    # Test network
    if ! ping -c 2 8.8.8.8 >/dev/null 2>&1; then
        log_error "No internet connection!"
        exit 1
    fi
    echo "DEBUG: Network check passed"
    
    # Interactive setup
    echo "DEBUG: About to call select_disk"
    select_disk
    echo "DEBUG: select_disk completed"
    
    echo "DEBUG: About to call get_settings"
    get_settings
    echo "DEBUG: get_settings completed"
    
    echo
    log_warning "Final confirmation:"
    echo "  Disk: $TARGET_DISK (WILL BE ERASED!)"
    echo "  Hostname: $HOSTNAME"
    echo "  Username: $USERNAME"
    read -p "Install NixOS? (yes/no): " final_confirm
    
    if [[ "$final_confirm" != "yes" ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
    
    # Do installation
    partition_disk
    format_disk
    setup_config
    install_system
    set_passwords
    
    log_success "🎉 Basic NixOS installation complete!"
    echo
    log_info "After reboot:"
    echo "1. Log in as $USERNAME"
    echo "2. Clone dotfiles: git clone https://gitlab.com/marerm/dotfiles.git"
    echo "3. Run post-install script: ~/dotfiles/nixos-migration/scripts/post-install.sh"
    echo
    log_warning "Remove USB and reboot now!"
}

main "$@"