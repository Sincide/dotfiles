# NixOS Migration Troubleshooting Guide

## Common Issues and Solutions

This document covers common problems you might encounter during the migration from Arch + Hyprland to NixOS and their solutions.

## Installation Issues

### 1. Hardware Configuration Problems

**Issue**: Graphics not working properly after NixOS installation
```bash
# Symptoms
- Black screen after boot
- No hardware acceleration
- AMD GPU not detected
```

**Solution**: Update hardware configuration for AMD GPU
```nix
# In /etc/nixos/configuration.nix or hardware-configuration.nix
hardware.opengl = {
  enable = true;
  driSupport = true;
  driSupport32Bit = true;
  extraPackages = with pkgs; [
    mesa.drivers
    amdvlk
    rocm-opencl-icd
    rocm-opencl-runtime
  ];
};

# Add kernel parameters
boot.kernelParams = [
  "amdgpu.ppfeaturemask=0xffffffff"
  "amd_pstate=active"
];
```

### 2. Boot Issues

**Issue**: System doesn't boot after installation
```bash
# Symptoms
- Grub error
- Kernel panic
- Boot loop
```

**Solution**: Check boot configuration
```nix
# Ensure proper boot loader configuration
boot.loader = {
  systemd-boot.enable = true;
  efi.canTouchEfiVariables = true;
};

# If using GRUB instead
boot.loader.grub = {
  enable = true;
  device = "nodev";
  efiSupport = true;
  useOSProber = true; # For dual boot
};
```

## Home Manager Issues

### 3. Home Manager Installation Fails

**Issue**: Home Manager won't install or activate
```bash
# Error messages
error: collision between files
error: infinite recursion encountered
```

**Solution**: Clean installation approach
```bash
# Remove existing Home Manager
rm -rf ~/.config/home-manager
rm -rf ~/.local/state/home-manager

# Clean Nix channels
nix-channel --remove home-manager
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update

# Reinstall
nix-shell '<home-manager>' -A install
```

### 4. File Conflicts

**Issue**: Home Manager can't write configuration files
```bash
# Error: collision between files
# Existing files prevent Home Manager from managing them
```

**Solution**: Backup and remove conflicting files
```bash
# Backup existing configs
mkdir -p ~/backup-configs
mv ~/.config/hypr ~/backup-configs/
mv ~/.config/waybar ~/backup-configs/
mv ~/.config/kitty ~/backup-configs/

# Then run Home Manager
home-manager switch
```

## Package Issues

### 5. Custom Package Build Failures

**Issue**: Matugen custom derivation fails to build
```bash
# Error messages
error: hash mismatch
error: build failed
cargo build errors
```

**Solution**: Fix derivation hashes and dependencies
```nix
# Update hash in matugen.nix
# Get correct hash by running build and copying the expected hash from error
src = super.fetchFromGitHub {
  owner = "InioX";
  repo = "matugen";
  rev = "v${version}";
  hash = "sha256-UPDATED_HASH_HERE";
};

# Add missing build dependencies
nativeBuildInputs = with super; [
  pkg-config
  rustc
  cargo
];

buildInputs = with super; [
  openssl
  openssl.dev
];
```

### 6. Unfree Package Issues

**Issue**: Packages like Discord or Spotify won't install
```bash
# Error: unfree package refused
```

**Solution**: Enable unfree packages
```nix
# In home.nix
nixpkgs.config.allowUnfree = true;

# Or system-wide in configuration.nix
nixpkgs.config.allowUnfree = true;

# For specific packages only
nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  "discord"
  "spotify"
  "cursor"
];
```

## Service Issues

### 7. Ollama Service Won't Start

**Issue**: AI service fails to start or can't detect GPU
```bash
# Check status
systemctl status ollama
journalctl -u ollama -f
```

**Solution**: Fix service configuration and GPU access
```nix
# In system configuration
services.ollama = {
  enable = true;
  acceleration = "rocm";
  environmentVariables = {
    OLLAMA_ORIGINS = "http://localhost:*";
    HSA_OVERRIDE_GFX_VERSION = "10.3.0"; # For some AMD GPUs
  };
};

# Ensure user is in video group
users.users.martin.extraGroups = [ "video" ];
```

### 8. User Services Not Starting

**Issue**: qBittorrent or other user services won't start
```bash
# Check user services
systemctl --user status qbittorrent-nox
```

**Solution**: Fix user service configuration
```nix
# In Home Manager services module
systemd.user.services.qbittorrent-nox = {
  Unit = {
    Description = "qBittorrent-nox";
    After = [ "graphical-session.target" ];
    Wants = [ "graphical-session.target" ];
  };
  Service = {
    Type = "exec"; # Changed from "forking"
    ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --webui-port=9090";
    Restart = "on-failure";
  };
  Install.WantedBy = [ "default.target" ];
};
```

## Theming Issues

### 9. Dynamic Theming Not Working

**Issue**: Colors not applying or matugen not generating themes
```bash
# Matugen not found
# Colors not updating
# Applications not restarting
```

**Solution**: Ensure theming pipeline works
```bash
# Test matugen installation
nix-shell -p matugen --run "matugen --version"

# Test color generation
matugen image ~/Pictures/wallpapers/test.jpg

# Check if files are generated
ls ~/.config/waybar/colors.css
ls ~/.config/hypr/colors.conf
```

### 10. Font Issues

**Issue**: Fonts not loading or appearing incorrectly
```bash
# Missing icons in Waybar
# Font fallback issues
```

**Solution**: Fix font configuration
```nix
# In Home Manager
fonts.fontconfig.enable = true;

# System-wide fonts
fonts.packages = with pkgs; [
  jetbrains-mono
  (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  noto-fonts
  noto-fonts-emoji
  font-awesome
];

# Rebuild font cache
fc-cache -f
```

## Performance Issues

### 11. Slow Rebuilds

**Issue**: Home Manager or system rebuilds take too long
```bash
# Very slow `home-manager switch`
# System rebuild timeout
```

**Solution**: Optimize Nix configuration
```nix
# Enable parallel building
nix.settings = {
  max-jobs = "auto";
  cores = 0; # Use all cores
  builders-use-substitutes = true;
};

# Use binary cache
nix.settings.substituters = [
  "https://cache.nixos.org/"
  "https://nix-community.cachix.org"
];
```

### 12. GPU Monitoring Not Working

**Issue**: Waybar GPU monitoring shows no data
```bash
# Temperature shows 0
# GPU usage shows N/A
```

**Solution**: Fix GPU sensor access
```bash
# Check if sensors are available
ls /sys/class/drm/card*/device/hwmon/

# Add user to necessary groups
users.users.martin.extraGroups = [ "video" "render" ];

# Test sensor access
cat /sys/class/drm/card1/device/hwmon/hwmon*/temp1_input
```

## Network Issues

### 13. Network Not Working

**Issue**: No internet connection after NixOS installation
```bash
# No network connectivity
# NetworkManager not working
```

**Solution**: Configure networking properly
```nix
# Enable NetworkManager
networking.networkmanager.enable = true;
networking.wireless.enable = false; # Disable if using NetworkManager

# Add user to networkmanager group
users.users.martin.extraGroups = [ "networkmanager" ];

# Start NetworkManager
systemctl enable NetworkManager
systemctl start NetworkManager
```

## Rollback Procedures

### 14. Emergency Rollback

**Issue**: System broken after configuration change
```bash
# System won't boot
# Desktop environment not working
```

**Solution**: Use NixOS rollback features
```bash
# System rollback (as root)
nixos-rebuild --rollback

# Home Manager rollback
home-manager generations
home-manager switch --switch-generation 123

# Boot previous generation (from GRUB menu)
# Select previous generation in GRUB boot menu
```

### 15. Partial Rollback

**Issue**: Only some changes need to be reverted
```bash
# Only Home Manager broken
# Only specific service broken
```

**Solution**: Selective rollback
```bash
# Home Manager only
home-manager switch --switch-generation $(home-manager generations | head -2 | tail -1 | cut -d' ' -f7)

# System only (keep Home Manager)
sudo nixos-rebuild switch --rollback

# Individual service
systemctl --user restart problematic-service
```

## Data Recovery

### 16. Configuration Corruption

**Issue**: Configuration files corrupted or lost
```bash
# Config files missing
# Syntax errors in Nix files
```

**Solution**: Use backups and Git history
```bash
# Restore from backup
cp -r ~/config-backups/home-manager-latest/* ~/.config/home-manager/

# If using Git (recommended)
cd ~/.config/home-manager
git reset --hard HEAD~1

# System config restore
sudo cp -r /etc/nixos-backup/* /etc/nixos/
```

## Common Error Messages

### 17. "Infinite Recursion" Error

**Cause**: Circular dependency in Nix expressions
**Solution**: Check for circular imports in module system

### 18. "Hash Mismatch" Error

**Cause**: Source code changed but hash not updated
**Solution**: Update hashes in custom derivations

### 19. "Package Not Found" Error

**Cause**: Package name incorrect or not available
**Solution**: Check package availability with `nix search`

### 20. "Permission Denied" Error

**Cause**: Service or file permissions issue
**Solution**: Check user groups and file permissions

## Getting Help

### Resources
- **NixOS Manual**: https://nixos.org/manual/nixos/stable/
- **Home Manager Manual**: https://nix-community.github.io/home-manager/
- **Nix Pills**: https://nixos.org/guides/nix-pills/
- **NixOS Discourse**: https://discourse.nixos.org/
- **NixOS Reddit**: https://reddit.com/r/NixOS

### Debugging Commands
```bash
# Check system status
sudo systemctl status
journalctl -xeu service-name

# Check Nix configuration
nix-instantiate --parse file.nix
nix-build '<nixpkgs>' -A package-name

# Home Manager debugging
home-manager build
home-manager switch --show-trace
```

This troubleshooting guide covers most common issues you're likely to encounter during migration. Keep it handy during your migration process!