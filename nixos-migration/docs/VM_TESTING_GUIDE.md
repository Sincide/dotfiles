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

# Download NixOS graphical ISO (recommended for easier installation)
cd ~/VMs/nixos-test
curl -L -o nixos-graphical.iso \
    "https://channels.nixos.org/nixos-unstable/latest-nixos-gnome-x86_64-linux.iso"

# Alternative: Minimal ISO (if you prefer command-line installation)
# curl -L -o nixos-minimal.iso \
#     "https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso"
```

### 1.3 Create VM with virt-manager

1. **Launch virt-manager**:
   ```bash
   virt-manager
   ```

2. **Create New VM**:
   - Click "Create a new virtual machine"
   - Choose "Local install media (ISO image or CDROM)"
   - Browse to your downloaded `nixos-graphical.iso`
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

1. **Boot from ISO** and wait for GNOME desktop to load
2. **Connect to network** (click network icon, usually automatic with NAT)
3. **Verify internet connection** by opening a browser or terminal:
   ```bash
   ping -c 3 google.com
   ```

### 3.2 Graphical Installation

**Use the NixOS GUI installer for VM testing:**

1. **Open Terminal** (Activities → Terminal)
2. **Launch installer**: Click "Install NixOS" icon on desktop or run:
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

**Important Notes:**
- ✅ **GUI installer creates basic system** - you'll customize with dotfiles after
- ✅ **Much more reliable in VMs** than command-line installation
- ✅ **Network and keyboard setup handled automatically**

### 3.3 First Boot and Dotfiles Setup

**After GUI installation completes:**

1. **Remove ISO** and reboot into installed system
2. **Log in** as the user you created (martin)
3. **Get your dotfiles**:
   ```bash
   # Install git and clone dotfiles
   nix-shell -p git
   cd ~
   git clone https://github.com/yourusername/dotfiles.git
   ```

4. **Replace system configuration**:
   ```bash
   # Backup original config
   sudo cp /etc/nixos/configuration.nix /etc/nixos/configuration.nix.original
   sudo cp /etc/nixos/hardware-configuration.nix /etc/nixos/hardware-configuration.nix.generated

   # Copy your configuration
   sudo cp -r ~/dotfiles/nixos-migration/system/* /etc/nixos/
   sudo cp ~/dotfiles/nixos-migration/flake.nix /etc/nixos/

   # Restore hardware config (important!)
   sudo cp /etc/nixos/hardware-configuration.nix.generated /etc/nixos/hardware-configuration.nix

   # Update hostname for VM
   sudo sed -i 's/nixos-hyprland/nixos-vm-test/' /etc/nixos/configuration.nix
   ```

5. **Enable flakes and rebuild**:
   ```bash
   # Enable flakes
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

   # Rebuild with your configuration
   sudo nixos-rebuild switch --flake /etc/nixos#nixos-vm-test
   ```

6. **Reboot to apply changes**:
   ```bash
   sudo reboot
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