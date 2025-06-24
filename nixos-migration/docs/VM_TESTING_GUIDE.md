# VM Testing Guide for NixOS Migration

## Overview

This guide helps you test your NixOS configuration in a virtual machine before doing a fresh installation. Testing in a VM allows you to:

- Validate configuration files work correctly
- Test the theming system and custom packages
- Verify hardware compatibility (with limitations)
- Practice the installation and setup process
- Debug issues safely without affecting your Arch system

## VM Setup Requirements

### Host System Requirements
- **RAM**: 8GB+ (allocate 4GB+ to VM)
- **Storage**: 20GB+ free space for VM
- **CPU**: Virtualization support (Intel VT-x or AMD-V)
- **Arch Linux** with dotfiles already configured

### Recommended VM Software
- **QEMU + virt-manager** (recommended - better performance)
- **VirtualBox** (easier setup)
- **VMware** (if you have it)

## Method 1: QEMU + virt-manager (Recommended)

### 1.1 Install Virtualization on Arch

```bash
# Install required packages
sudo pacman -S qemu-full virt-manager libvirt edk2-ovmf dnsmasq

# Enable and start libvirtd
sudo systemctl enable --now libvirtd

# Add your user to libvirt group
sudo usermod -a -G libvirt $USER

# Log out and back in for group changes to take effect
```

### 1.2 Download NixOS ISO

```bash
# Create VM directory
mkdir -p ~/VMs/nixos-test

# Download NixOS unstable ISO (for latest packages)
cd ~/VMs/nixos-test
curl -L -o nixos-unstable.iso \
    "https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso"
```

### 1.3 Create VM with virt-manager

1. **Launch virt-manager**:
   ```bash
   virt-manager
   ```

2. **Create New VM**:
   - Click "Create a new virtual machine"
   - Choose "Local install media (ISO image or CDROM)"
   - Browse to your downloaded `nixos-unstable.iso`
   - OS type: Linux, Version: Generic Linux 2020
   - Memory: 4096 MB (4GB)
   - Storage: 30 GB (dynamically allocated)
   - Network: Default NAT

3. **VM Settings** (before starting):
   - **CPU**: 2-4 cores
   - **Display**: VNC or Spice (for graphics)
   - **Video**: QXL or VirtIO-GPU
   - **Sound**: ich9 or AC97

### 1.4 Configure VM for Testing

Start the VM and proceed to **NixOS Installation** section below.

## Method 2: VirtualBox (Alternative)

### 2.1 Install VirtualBox

```bash
# Install VirtualBox
sudo pacman -S virtualbox virtualbox-host-modules-arch

# Load kernel modules
sudo modprobe vboxdrv

# Add user to vboxusers group
sudo usermod -a -G vboxusers $USER
```

### 2.2 Create VirtualBox VM

1. **Create New VM**:
   - Name: "NixOS-Test"
   - Type: Linux
   - Version: Other Linux (64-bit)
   - Memory: 4096 MB
   - Storage: 30 GB VDI (dynamically allocated)

2. **VM Settings**:
   - **System > Processor**: 2-4 CPUs
   - **Display > Video Memory**: 128 MB
   - **Display > Graphics Controller**: VMSVGA
   - **Storage**: Attach NixOS ISO to optical drive

## NixOS Installation in VM

### 3.1 Boot NixOS ISO

1. **Boot from ISO** and wait for the NixOS prompt
2. **Set up network** (usually automatic with NAT)
3. **Verify internet connection**:
   ```bash
   ping -c 3 google.com
   ```

### 3.2 Prepare Installation

```bash
# Switch to root
sudo su

# Enable flakes early (for our configuration)
mkdir -p /etc/nix
echo "experimental-features = nix-command flakes" > /etc/nix/nix.conf

# Partition the disk (simple layout for testing)
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart primary 512MiB -8GiB
parted /dev/sda -- mkpart primary linux-swap -8GiB 100%
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 3 esp on

# Format partitions
mkfs.ext4 -L nixos /dev/sda1
mkswap -L swap /dev/sda2
mkfs.fat -F 32 -n boot /dev/sda3

# Mount filesystems
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
swapon /dev/sda2
```

### 3.3 Install Git and Clone Dotfiles

```bash
# Install git in the installer environment
nix-shell -p git

# Clone your dotfiles (replace with your repo URL)
cd /mnt
git clone https://github.com/yourusername/dotfiles.git
# or copy from your Arch system:
# scp -r martin@your-arch-ip:~/dotfiles /mnt/
```

### 3.4 Use Your Configuration

```bash
# Generate hardware configuration
nixos-generate-config --root /mnt

# Copy your configuration over the generated one
cp -r /mnt/dotfiles/nixos-migration/system/* /mnt/etc/nixos/
cp /mnt/dotfiles/nixos-migration/flake.nix /mnt/etc/nixos/

# Keep the generated hardware configuration
mv /mnt/etc/nixos/hardware-configuration.nix.backup /mnt/etc/nixos/hardware-configuration.nix 2>/dev/null || true

# Update hostname in configuration.nix
sed -i 's/nixos-hyprland/nixos-vm-test/' /mnt/etc/nixos/configuration.nix
```

### 3.5 Install NixOS

```bash
# Install with your flake configuration
nixos-install --flake /mnt/etc/nixos#nixos-vm-test

# Set root password when prompted
# Set user password for 'martin'
passwd --root /mnt martin

# Reboot
reboot
```

## Post-Installation VM Testing

### 4.1 First Boot Setup

1. **Boot into NixOS** and log in as `martin`
2. **Enable flakes** for your user:
   ```bash
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
   ```

3. **Set up Home Manager**:
   ```bash
   # Copy Home Manager config
   mkdir -p ~/.config/home-manager
   cp -r ~/dotfiles/nixos-migration/home/* ~/.config/home-manager/

   # Apply Home Manager configuration
   home-manager switch --flake ~/.config/home-manager#martin
   ```

### 4.2 Testing Checklist

#### Basic System Testing
- [ ] **Desktop Environment**: Does Hyprland start?
  ```bash
  # Start Hyprland
  Hyprland
  ```

- [ ] **Window Manager**: Do keybindings work?
  - `Super+Return` - Terminal
  - `Super+D` - Launcher
  - `Super+Q` - Close window

- [ ] **Terminal**: Does Kitty work with theme?
- [ ] **File Manager**: Does Thunar open?

#### Package Testing
- [ ] **Matugen**: Critical theming package
  ```bash
  matugen --version
  ```

- [ ] **Waybar**: Status bars display correctly
- [ ] **Development Tools**: VS Code, Git, etc.
- [ ] **Media**: Can play videos/audio?

#### Theming System Testing
- [ ] **Current Theme**: Is space theme applied?
- [ ] **Wallpaper**: Can set wallpaper with `wallpaper-manager`?
- [ ] **Colors**: Do applications match theme colors?
- [ ] **Theme Switching**: Does `theme-nature` work?

#### Services Testing
- [ ] **Ollama**: AI service running?
  ```bash
  systemctl status ollama
  ollama list
  ```

- [ ] **GPU Monitoring**: Do temperature/usage scripts work?
  ```bash
  gpu-temp-monitor
  gpu-usage-monitor
  ```

#### Custom Packages Testing
- [ ] **Cursor IDE**: Does it launch? (if installed)
- [ ] **Pokemon Scripts**: Terminal aesthetics working?
- [ ] **Custom Derivations**: All packages available?

### 4.3 Performance Testing

```bash
# Test boot time
systemd-analyze

# Test memory usage
free -h

# Test CPU usage
htop

# Test graphics (if VM supports it)
glxinfo | grep "direct rendering"
```

### 4.4 Troubleshooting VM Issues

#### Graphics Issues
```bash
# If Hyprland won't start, try software rendering
WLR_RENDERER=pixman Hyprland

# Or use X11 session temporarily
startx
```

#### Network Issues
```bash
# Check network status
ip a
systemctl status NetworkManager

# Restart network if needed
sudo systemctl restart NetworkManager
```

#### Package Issues
```bash
# Rebuild if packages missing
sudo nixos-rebuild switch --flake /etc/nixos#nixos-vm-test

# Home Manager rebuild
home-manager switch --flake ~/.config/home-manager#martin
```

## VM Testing Limitations

### What Works Well
- ✅ Package installation and management
- ✅ Configuration file deployment
- ✅ Service management
- ✅ Basic theming system
- ✅ Terminal applications
- ✅ Network applications

### What Has Limitations
- ⚠️ **GPU acceleration** - Limited/virtualized
- ⚠️ **Hardware-specific features** - CPU/GPU monitoring
- ⚠️ **Performance** - Slower than bare metal
- ⚠️ **Audio/Video** - May have issues
- ⚠️ **Bluetooth** - Usually not available

### VM-Specific Adjustments

If you encounter issues, you can temporarily modify configs:

1. **Disable GPU-specific features**:
   ```nix
   # In system/modules/system.nix, comment out AMD-specific items
   # hardware.opengl.extraPackages = []; # Disable GPU packages
   ```

2. **Use software rendering**:
   ```bash
   export WLR_RENDERER=pixman
   ```

3. **Simplify Waybar config**:
   ```nix
   # Remove GPU monitoring modules for VM testing
   ```

## After VM Testing

### If Everything Works
- ✅ Configuration is ready for bare metal installation
- ✅ Proceed with fresh NixOS installation guide
- ✅ Keep VM for future testing

### If Issues Found
1. **Fix configuration files** in `nixos-migration/`
2. **Update documentation** with solutions
3. **Test fixes in VM** before bare metal
4. **Document VM-specific workarounds**

## VM Snapshot Management

### Create Snapshots
```bash
# For QEMU/virt-manager
virsh snapshot-create-as nixos-test "clean-install" "Fresh installation with dotfiles"

# For VirtualBox
VBoxManage snapshot "NixOS-Test" take "clean-install"
```

### Restore Snapshots
```bash
# For QEMU/virt-manager
virsh snapshot-revert nixos-test "clean-install"

# For VirtualBox
VBoxManage snapshot "NixOS-Test" restore "clean-install"
```

## Useful VM Testing Commands

```bash
# Quick system status
neofetch

# Check all services
systemctl --failed

# Check Home Manager status
home-manager generations

# Test theme system
ls ~/.config/*/colors.*

# Verify flake configuration
nix flake check /etc/nixos

# Test package availability
nix search nixpkgs matugen
```

VM testing is an excellent way to validate your configuration before committing to a fresh installation. Take your time to test all aspects of your setup!