# Fresh NixOS Installation Guide

## Overview

This guide provides step-by-step instructions for installing NixOS from scratch using your dotfiles configuration. This is for a **completely fresh installation** on dedicated hardware, not migrating from your existing Arch Linux system.

**Important**: This will completely wipe the target drive. Your Arch Linux system will remain untouched on its current drive.

## Pre-Installation Requirements

### Hardware Requirements
- **CPU**: x86_64 with virtualization support
- **RAM**: 8GB+ (16GB+ recommended)
- **Storage**: 100GB+ SSD (separate from your Arch drive)
- **GPU**: AMD GPU (for optimal GPU monitoring)
- **Network**: Ethernet or Wi-Fi capability

### Prerequisites
1. **Backup Important Data** from any drives you plan to use
2. **Test in VM First** using the VM Testing Guide
3. **Prepare Installation Media** (USB drive 4GB+)
4. **Access to Your Dotfiles** (GitHub repo or USB copy)

### Installation Media Preparation

#### Method 1: From Arch Linux (Current System)
```bash
# Download NixOS ISO - use GRAPHICAL for easier installation
cd ~/Downloads
curl -L -o nixos-graphical.iso \
    "https://channels.nixos.org/nixos-unstable/latest-nixos-gnome-x86_64-linux.iso"

# Flash to USB drive (replace /dev/sdX with your USB device)
sudo dd if=nixos-graphical.iso of=/dev/sdX bs=4M status=progress oflag=sync

# Or use a GUI tool
sudo pacman -S balena-etcher-bin
# Use Etcher to flash the ISO
```

#### Method 2: Download and Prepare Elsewhere
- Download from: https://nixos.org/download.html
- **Recommended**: Choose **NixOS Graphical ISO** (GNOME or Plasma)
- Use Rufus (Windows) or Balena Etcher (any OS)
- Choose NixOS Unstable for latest packages

**Why Graphical ISO?**
- ✅ **Reliable GUI installer** - no script failures
- ✅ **Better hardware detection** - especially for VMs
- ✅ **Network setup included** - GUI WiFi/Ethernet tools
- ✅ **Still installs minimal system** - you choose what desktop to install

## BIOS/UEFI Configuration

### Before Booting NixOS
1. **Boot Order**: Set USB as first boot device
2. **Secure Boot**: Disable (NixOS doesn't support it by default)
3. **Fast Boot**: Disable for better compatibility
4. **UEFI Mode**: Enable (recommended over Legacy BIOS)
5. **Virtualization**: Enable (for better performance)

### Boot from USB
1. Insert USB drive and restart computer
2. Select USB device from boot menu (usually F12/F8/ESC)
3. Choose "NixOS Installer" from the boot menu

## Installation Process

### Step 1: Graphical Installation

**Using the NixOS Graphical Installer:**

1. **Boot from USB** and wait for GNOME desktop to load
2. **Connect to Network**:
   - WiFi: Click network icon in top-right, select your network
   - Ethernet: Should connect automatically
3. **Open Terminal** (Activities → Terminal)
4. **Launch Installer**: Click "Install NixOS" icon on desktop or run:
   ```bash
   sudo nixos-install-gui
   ```

**Installation Steps in GUI:**
1. **Welcome** → Click "Try or Install NixOS"
2. **Location** → Select your timezone
3. **Keyboard** → Choose Swedish (sv) layout
4. **Partitions** → Choose "Erase disk" (will show your VM disk)
5. **Users** → Create user account (username: martin)
6. **Summary** → Review settings
7. **Install** → Wait for installation to complete

**Important Partition Settings:**
- ✅ **Use entire disk** for VM testing
- ✅ **Enable encryption** if desired (optional for VM)
- ✅ **EFI/UEFI boot** (automatic)
- ✅ **Swap partition** (automatic)

**Important Notes:**
- ✅ **No desktop environment** - GUI installer doesn't install GNOME permanently
- ✅ **System will boot to login prompt** - ready for your custom configuration
- ✅ **Much more reliable** than command-line installation

### Step 2: First Boot into Installed System

After installation completes:
1. **Remove USB drive** and reboot
2. **Boot into NixOS** - you'll see a login prompt
3. **Log in** as the user you created (martin)
4. **You now have a minimal NixOS system** ready for your dotfiles configuration

### Step 3: Get Your Dotfiles

**Now that you have a basic NixOS system, you need to get your dotfiles configuration:**

#### Method 1: Clone from GitHub
```bash
# Install git (if not available)
nix-shell -p git

# Clone your dotfiles to home directory
cd ~
git clone https://github.com/yourusername/dotfiles.git

# If repo is private, you may need to use a token
# git clone https://TOKEN@github.com/yourusername/dotfiles.git
```

#### Method 2: Copy from USB/Network
```bash
# From USB drive
cp -r /path/to/usb/dotfiles ~/dotfiles

# From network (scp from your Arch system)
scp -r martin@arch-ip:~/dotfiles ~/
```

### Step 4: Replace System Configuration

```bash
# Backup the generated configuration
sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.original
sudo cp /etc/nixos/hardware-configuration.nix /etc/nixos/hardware-configuration.nix.generated

# Copy your NixOS configuration
sudo cp -r ~/dotfiles/nixos-migration/system/* /etc/nixos/
sudo cp ~/dotfiles/nixos-migration/flake.nix /etc/nixos/

# Restore the generated hardware configuration (important!)
sudo cp /etc/nixos/hardware-configuration.nix.generated /etc/nixos/hardware-configuration.nix

# Make sure the nix user can access the configuration
sudo chown -R root:root /etc/nixos
```

### Step 5: Customize Configuration

```bash
# Edit main configuration for your system
sudo nano /etc/nixos/configuration.nix

# Important changes to make:
# 1. Line ~8: Update hostname
networking.hostName = "your-hostname";  # Change from "nixos-hyprland"

# 2. Line ~42: Set your timezone  
time.timeZone = "Europe/Stockholm";  # Update to your timezone

# 3. Line ~106: Update user information
users.users.martin = {
  description = "Your Name";  # Update description
  # Keep other settings the same
};

# Save and exit (Ctrl+X, Y, Enter in nano)
```

### Step 6: Enable Flakes and Rebuild System

```bash
# Enable flakes for your user
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

# Rebuild the system with your configuration
sudo nixos-rebuild switch --flake /etc/nixos#your-hostname

# This will take 20-30 minutes for first rebuild
# Downloads and compiles all your packages
```

### Step 7: First Reboot with Your Configuration

```bash
# Reboot to apply all changes
sudo reboot

# System will boot with your custom Hyprland configuration
# Log in as 'martin' - you should see a basic desktop environment
```

## Post-Installation Setup

### Step 1: Verify System is Working

```bash
# Check that your system booted correctly
neofetch
systemctl --failed  # Should show no failed services

# Verify Hyprland is available
which Hyprland

# Check that flakes are enabled
nix flake --version
```

### Step 2: Home Manager Setup

```bash
# Set up Home Manager configuration  
mkdir -p ~/.config/home-manager
cp -r ~/dotfiles/nixos-migration/home/* ~/.config/home-manager/

# Update personal information in Home Manager config
nano ~/.config/home-manager/home.nix

# Important updates:
# Line ~17: Verify home.username = "martin"
# Line ~18: Verify home.homeDirectory = "/home/martin"  
# Line ~104: Update git user name
# Line ~105: Update git email

# Apply Home Manager configuration
home-manager switch --flake ~/.config/home-manager#martin

# This will take some time as it downloads and configures all your user applications
```

### Step 3: Desktop Environment Setup

```bash
# Start Hyprland desktop environment
# Option 1: From TTY
Hyprland

# Option 2: If you have a display manager, select Hyprland from login screen
```

### Step 4: Verify Critical Components

#### Test Core Functionality
```bash
# Test terminal (should open with Kitty)
# Super + Return

# Test launcher
# Super + D (should open Fuzzel)

# Test file manager
thunar

# Verify Matugen (critical for theming)
matugen --version
```

#### Test Services
```bash
# Check Ollama AI service
systemctl status ollama
ollama list

# Check user services
systemctl --user status qbittorrent-nox

# Check audio
pactl info
```

#### Test Theming System
```bash
# Check current theme
cat ~/.config/current-theme

# Test wallpaper manager
wallpaper-manager

# Test theme switching
theme-nature
theme-space
```

### Step 5: Install Ollama Models

```bash
# Download essential AI models (this will take time and bandwidth)
ollama pull llama3.2:3b
ollama pull codegemma:7b
ollama pull qwen2.5-coder:latest
ollama pull nomic-embed-text:latest

# Test AI functionality
ollama run llama3.2:3b "Hello, test message"
```

### Step 6: Set Up Personal Data

```bash
# Create essential directories
mkdir -p ~/Documents/{projects,notes}
mkdir -p ~/Pictures/wallpapers/{space,nature,gaming,minimal,dark,abstract}

# Copy wallpapers from your Arch system if desired
# scp -r martin@arch-ip:~/Pictures/wallpapers/* ~/Pictures/wallpapers/

# Set up your preferred wallpaper
wallpaper-manager ~/Pictures/wallpapers/space/your-wallpaper.jpg
```

## Advanced Configuration

### Dual Boot Setup (Optional)

If you want to dual boot with your existing Arch system:

```bash
# Update GRUB to detect other OS
sudo nixos-rebuild switch

# Manual GRUB entry for Arch (if not auto-detected)
sudo nano /etc/nixos/configuration.nix

# Add to boot.loader.grub section:
boot.loader.grub = {
  enable = true;
  efiSupport = true;
  useOSProber = true;  # This should detect Arch
};

# Rebuild
sudo nixos-rebuild switch
```

### Performance Optimizations

```bash
# Check boot time
systemd-analyze

# Optimize nix store
nix-store --optimise

# Clean up old generations (after you're sure everything works)
nix-collect-garbage -d
sudo nix-collect-garbage -d
```

### Backup Configuration

```bash
# Version control your configuration
cd /etc/nixos
sudo git init
sudo git add .
sudo git commit -m "Initial NixOS configuration"

# Also backup Home Manager config
cd ~/.config/home-manager
git init
git add .
git commit -m "Initial Home Manager configuration"
```

## Troubleshooting Fresh Installation

### Boot Issues

**System won't boot after installation:**
```bash
# Boot from USB again and check
mount /dev/disk/by-label/nixos /mnt
mount /dev/disk/by-label/boot /mnt/boot

# Check if bootloader installed correctly
ls /mnt/boot

# Reinstall bootloader if needed
nixos-enter --root /mnt
nixos-rebuild switch --flake /etc/nixos#your-hostname
```

### Network Issues

**No internet after fresh boot:**
```bash
# Check network status
ip a
systemctl status NetworkManager

# Restart NetworkManager
sudo systemctl restart NetworkManager

# For WiFi, use nmcli
nmcli device wifi list
nmcli device wifi connect "YourWiFi" password "YourPassword"
```

### Graphics Issues

**Hyprland won't start:**
```bash
# Try software rendering
WLR_RENDERER=pixman Hyprland

# Check graphics drivers
lspci | grep VGA
dmesg | grep amdgpu

# Rebuild system with latest config
sudo nixos-rebuild switch --flake /etc/nixos#your-hostname
```

### Package Issues

**Missing packages or build failures:**
```bash
# Update flake inputs
sudo nix flake update /etc/nixos

# Rebuild system
sudo nixos-rebuild switch --flake /etc/nixos#your-hostname

# Rebuild Home Manager
home-manager switch --flake ~/.config/home-manager#martin
```

## Post-Installation Checklist

### Essential Verification
- [ ] System boots correctly
- [ ] Network connectivity works
- [ ] Hyprland desktop environment loads
- [ ] Terminal (Kitty) opens and works
- [ ] File manager (Thunar) opens
- [ ] Audio works
- [ ] Matugen is installed and functional

### Advanced Features
- [ ] Ollama AI service running
- [ ] GPU monitoring working (if AMD GPU)
- [ ] Theming system functional
- [ ] Waybar displays correctly
- [ ] Custom packages installed
- [ ] Git automation scripts work

### Personal Setup
- [ ] Personal data migrated/accessible
- [ ] Development environment configured
- [ ] SSH keys and credentials set up
- [ ] Browser and applications configured
- [ ] Wallpapers and themes personalized

## Maintenance Commands

```bash
# System updates
sudo nixos-rebuild switch --flake /etc/nixos#your-hostname

# Home Manager updates
home-manager switch --flake ~/.config/home-manager#martin

# Clean up old generations
nix-collect-garbage -d
sudo nix-collect-garbage -d

# Optimize nix store
nix-store --optimise

# Check system status
systemctl --failed
home-manager generations
```

## Success! 🎉

If you've completed this guide successfully, you now have:

- **Fresh NixOS installation** with your sophisticated dotfiles
- **Reproducible configuration** that can be replicated exactly
- **Advanced theming system** with Material Design 3
- **AI integration** with local Ollama models
- **GPU monitoring** and performance optimization
- **Complete development environment** ready for use

Your NixOS system should preserve all the functionality of your Arch setup while gaining the benefits of reproducible, declarative configuration management.

**Next Steps**:
1. Use the system daily and report any issues
2. Customize further based on your preferences  
3. Keep configuration version controlled
4. Consider sharing your configuration with the community

Welcome to NixOS! 🚀