# Complete Installation Scripts Guide

## Overview

This guide explains every installation script in your dotfiles system and how they work together to create a 100% automated Arch Linux + Hyprland setup.

## 🎯 Quick Start

**For the impatient:**
```bash
cd ~/dotfiles
./scripts/setup/00-complete-installation.sh --yes
```

**For safety-conscious users:**
```bash
cd ~/dotfiles
./scripts/setup/00-complete-installation.sh --dry-run  # Preview first
./scripts/setup/00-complete-installation.sh           # Interactive install
```

## 📁 Script Organization

All installation scripts are located in `scripts/setup/` and follow this naming convention:
- `XX-script-name.sh` where XX is the execution order (00-16)
- Lower numbers run first, higher numbers run last
- Each script is standalone but designed to work together

## 🔢 Script Execution Order

### **Phase 1: System Foundation (01-03)**
1. **Prerequisites Check** → **Package Repositories** → **Core Packages**

### **Phase 2: Configuration (04-05)**  
2. **Deploy Configs** → **Setup Theming**

### **Phase 3: Storage & External (06-07)**
3. **External Drives** → **Browser Backup**

### **Phase 4: AI & Virtualization (08-09)**
4. **AI Platform** → **Virtualization**

### **Phase 5: Media Services (10-12)**
5. **qBittorrent** → **Emby** → **Storage Mounting**

### **Phase 6: User & System (13-16)**
6. **User Groups** → **Services** → **Optimization** → **Final Setup**

---

## 📋 Detailed Script Breakdown

### **00-complete-installation.sh** 
**🎯 Purpose:** Master orchestration script that runs everything  
**🔧 What it does:**
- Orchestrates all installation phases in correct order
- Provides installation options (full, minimal, dry-run)
- Handles error recovery and logging
- Shows progress and final summary

**📝 Usage:**
```bash
# Full interactive installation
./00-complete-installation.sh

# Automated (no prompts)
./00-complete-installation.sh --yes

# Preview only
./00-complete-installation.sh --dry-run

# Minimal install (no media/gaming)
./00-complete-installation.sh --minimal
```

**⏱️ Time:** 30-60 minutes  
**👤 User Input:** Initial confirmation (unless `--yes`)

---

### **01-prerequisites.sh**
**🎯 Purpose:** Validates system is ready for installation  
**🔧 What it does:**
- Checks if running on Arch Linux
- Verifies internet connection
- Ensures user has sudo privileges
- Validates available disk space
- Updates system clock

**📝 How it works:**
1. Runs system compatibility checks
2. Tests network connectivity to package repositories
3. Verifies user permissions
4. Checks minimum requirements (disk space, RAM)
5. Syncs system time for package signatures

**⏱️ Time:** 1-2 minutes  
**👤 User Input:** None  
**❌ Fails if:** Not Arch Linux, no internet, no sudo, insufficient space

---

### **02-setup-chaotic-aur.sh**
**🎯 Purpose:** Adds Chaotic AUR repository for faster AUR packages  
**🔧 What it does:**
- Installs Chaotic AUR keyring and mirrorlist
- Adds repository to pacman configuration
- Enables parallel downloads for faster installation
- Configures package signing

**📝 How it works:**
1. Downloads and installs Chaotic AUR keyring
2. Adds repository configuration to `/etc/pacman.conf`
3. Enables ParallelDownloads=5 for speed
4. Refreshes package databases
5. Verifies repository is working

**⏱️ Time:** 2-3 minutes  
**👤 User Input:** None  
**✨ Benefit:** AUR packages install 5-10x faster

---

### **03-install-packages.sh**
**🎯 Purpose:** Installs all 397 packages across 6 categories  
**🔧 What it does:**
- **Essential** (122 packages): System core, drivers, basic tools
- **Development** (96 packages): Programming languages, IDEs, build tools  
- **Theming** (72 packages): Icons, cursors, fonts, appearance
- **Multimedia** (42 packages): Audio, video, graphics editing
- **Gaming** (28 packages): Steam, Wine, emulators
- **Optional** (15 packages): Extra utilities and tools

**📝 How it works:**
1. Reads package lists from categorized arrays
2. Installs packages in batches using `yay` (AUR helper)
3. Handles failed packages gracefully
4. Tracks installation progress and errors
5. Creates installation report

**⏱️ Time:** 15-30 minutes  
**👤 User Input:** None  
**💾 Downloads:** ~2-4 GB depending on categories

---

### **04-deploy-dotfiles.sh**
**🎯 Purpose:** Deploys all configuration files to correct locations  
**🔧 What it does:**
- Creates symbolic links from dotfiles to `~/.config/`
- Backs up existing configurations
- Handles conflicts intelligently
- Sets proper file permissions
- Validates deployment success

**📝 How it works:**
1. Creates backup directory with timestamp
2. Maps dotfiles directories to target locations:
   - `hypr/` → `~/.config/hypr/`
   - `waybar/` → `~/.config/waybar/`
   - `kitty/` → `~/.config/kitty/`
   - `fish/` → `~/.config/fish/`
   - (and 15+ more)
3. Creates symbolic links for live updates
4. Sets executable permissions where needed
5. Verifies all links are working

**⏱️ Time:** 2-3 minutes  
**👤 User Input:** Conflict resolution (if existing configs found)  
**📁 Creates:** ~20 configuration directories

---

### **05-setup-theming.sh**
**🎯 Purpose:** Configures dynamic Material Design 3 theming system  
**🔧 What it does:**
- Sets up Matugen color generation
- Configures 15 application templates
- Sets default space theme
- Creates theme switching aliases
- Tests color generation system

**📝 How it works:**
1. Validates Matugen installation
2. Creates template mapping configuration
3. Generates initial color schemes from default wallpaper
4. Applies colors to all themed applications:
   - Hyprland window manager
   - Waybar status bars (both top and bottom)
   - GTK3/4 applications
   - Kitty terminal
   - Dunst notifications
   - Fish shell prompt
   - And 8 more applications
5. Creates theme switching commands

**⏱️ Time:** 3-5 minutes  
**👤 User Input:** None  
**🎨 Result:** Complete color-coordinated desktop

---

### **06-setup-external-drives.sh**
**🎯 Purpose:** Configures mounting for additional storage drives  
**🔧 What it does:**
- Detects unmounted drives
- Creates mount points (`/mnt/Media`, `/mnt/Stuff`)
- Adds entries to `/etc/fstab` for automatic mounting
- Sets proper permissions for media access
- Tests mounting functionality

**📝 How it works:**
1. Scans for block devices not mounted on `/`
2. Identifies drives by label or UUID
3. Creates mount point directories
4. Generates fstab entries with proper options:
   - `nosuid,nodev` for security
   - `nofail` so boot doesn't fail if drive missing
   - `x-gvfs-show` for GUI file manager integration
5. Tests mounting and sets permissions

**⏱️ Time:** 2-3 minutes  
**👤 User Input:** Drive selection (if multiple found)  
**💾 Configures:** Your specific `/mnt/Media` and `/mnt/Stuff` drives

---

### **07-setup-brave-backup.sh**
**🎯 Purpose:** Configures Brave browser profile backup system  
**🔧 What it does:**
- Sets up automated backup of browser data
- Creates backup scripts and schedules
- Handles bookmarks, extensions, settings
- Provides restore functionality
- Configures sync between systems

**📝 How it works:**
1. Locates Brave profile directories
2. Identifies important data to backup:
   - Bookmarks and history
   - Extension data and settings
   - Stored passwords and autofill
   - Custom CSS and themes
3. Creates backup automation scripts
4. Sets up compression and rotation
5. Provides easy restore commands

**⏱️ Time:** 3-4 minutes  
**👤 User Input:** Backup frequency preference  
**💾 Creates:** Automated browser backup system

---

### **08-setup-ollama.sh**
**🎯 Purpose:** Installs and configures AI platform with GPU acceleration  
**🔧 What it does:**
- Installs Ollama AI platform
- Configures ROCm for AMD GPU acceleration
- Downloads essential AI models
- Sets up systemd service
- Creates AI management aliases

**📝 How it works:**
1. **GPU Detection:** Identifies AMD GPU and installs ROCm packages
2. **Service Setup:** Creates user systemd service with environment:
   ```bash
   ROCM_PATH=/opt/rocm
   HSA_OVERRIDE_GFX_VERSION=11.0.0
   LD_LIBRARY_PATH=/usr/lib/ollama/rocm:/opt/rocm/lib
   ```
3. **Model Installation:** Downloads AI models in priority order:
   - `qwen2.5-coder:latest` (coding assistant)
   - `llama3.2:3b` (general purpose)
   - `codegemma:7b` (coding focused)
   - `nomic-embed-text` (text embeddings)
4. **Service Management:** Enables and starts Ollama service
5. **Verification:** Tests GPU acceleration and model loading

**⏱️ Time:** 10-20 minutes (model downloads)  
**👤 User Input:** Model selection  
**💾 Downloads:** 5-15 GB of AI models  
**🔧 Result:** Local AI with GPU acceleration

---

### **09-setup-virt-manager.sh**
**🎯 Purpose:** Configures KVM/QEMU virtualization with virt-manager  
**🔧 What it does:**
- Installs virtualization packages
- Configures KVM and QEMU
- Sets up libvirt daemon
- Adds user to virtualization groups
- Creates VM management interface

**📝 How it works:**
1. **Package Installation:**
   - `qemu-full` - Full QEMU virtualization
   - `libvirt` - Virtualization API
   - `virt-manager` - GUI management
   - `virt-viewer` - VM console viewer
   - `dnsmasq` - Network DHCP/DNS
   - `bridge-utils` - Network bridging
2. **Service Configuration:**
   - Enables and starts `libvirtd.service`
   - Configures default network
   - Sets up storage pools
3. **User Setup:**
   - Adds user to `libvirt` and `kvm` groups
   - Configures polkit permissions
   - Sets up SSH key access for remote VMs
4. **Verification:** Tests VM creation and network connectivity

**⏱️ Time:** 5-7 minutes  
**👤 User Input:** None  
**🎯 Result:** Full virtualization environment ready

---

### **10-setup-qbittorrent.sh**
**🎯 Purpose:** Sets up qBittorrent torrent client with proper service configuration  
**🔧 What it does:**
- Creates qbittorrent system user and group
- Configures working directory with proper permissions
- Creates systemd service for headless operation
- Sets up web UI access
- Handles port conflicts

**📝 How it works:**
1. **User Creation:**
   ```bash
   sudo groupadd -r qbittorrent
   sudo useradd -r -g qbittorrent -d /var/lib/qbittorrent -s /usr/bin/nologin qbittorrent
   ```
2. **Directory Setup:**
   - Creates `/var/lib/qbittorrent` with proper ownership
   - Sets up config directory structure
   - Applies correct permissions (755 for directories)
3. **Configuration File:**
   - Creates initial config with port 9090 (avoids conflict with dashboard)
   - Sets up download directories
   - Configures security settings and default credentials
4. **Service Configuration:**
   ```ini
   [Unit]
   Description=qBittorrent-nox service
   After=network.target
   
   [Service]
   User=qbittorrent
   Group=qbittorrent
   ExecStart=/usr/bin/qbittorrent-nox
   WorkingDirectory=/var/lib/qbittorrent
   Restart=on-failure
   ```
5. **Access Setup:**
   - Configures web UI on port 9090 (dashboard uses 8080)
   - Sets default credentials (admin/adminadmin)
   - Creates user control wrapper service
6. **Verification:** Tests service startup and web UI access

**⏱️ Time:** 3-4 minutes  
**👤 User Input:** None  
**🌐 Access:** http://localhost:9090 (admin/adminadmin)

---

### **11-setup-emby.sh**
**🎯 Purpose:** Configures Emby media server with proper media access  
**🔧 What it does:**
- Creates media group and directories
- Configures Emby service for media access
- Sets up media library structure
- Handles permissions and security
- Provides media management tools

**📝 How it works:**
1. **Group and User Setup:**
   ```bash
   sudo groupadd media
   sudo usermod -a -G media $(whoami)
   sudo usermod -a -G media emby
   ```
2. **Directory Structure:**
   - `/mnt/Media/` - Main media directory
   - `/mnt/Media/Movies/` - Movie library
   - `/mnt/Media/TV Shows/` - TV series library
   - `/mnt/Media/Music/` - Music library
   - `/mnt/Media/Photos/` - Photo library
3. **Service Override:**
   ```ini
   [Service]
   SupplementaryGroups=media
   ReadWritePaths=/mnt/Media
   UMask=0002
   ```
4. **Permissions:**
   - Sets group ownership to `media`
   - Configures 775 permissions for shared access
   - Ensures Emby service has media access
5. **Web Interface:** Starts service and verifies web UI at port 8096

**⏱️ Time:** 4-5 minutes  
**👤 User Input:** None  
**🌐 Access:** http://localhost:8096  
**📁 Result:** Organized media library structure

---

### **12-setup-storage.sh**
**🎯 Purpose:** Configures automatic mounting for additional storage drives  
**🔧 What it does:**
- Detects available unmounted drives
- Creates standardized mount points
- Configures fstab for automatic mounting
- Sets up storage management tools
- Handles drive labeling and identification

**📝 How it works:**
1. **Drive Detection:**
   - Scans for unmounted block devices
   - Identifies drives by LABEL or UUID
   - Excludes system drives and swap
2. **Mount Point Creation:**
   ```bash
   /mnt/Media    # For media files (movies, music, photos)
   /mnt/Stuff    # For general storage
   /mnt/Storage  # For additional storage
   /mnt/Backup   # For backup drives
   ```
3. **Fstab Configuration:**
   ```bash
   LABEL=Media /mnt/Media auto nosuid,nodev,nofail,x-gvfs-show 0 0
   LABEL=Stuff /mnt/Stuff auto nosuid,nodev,nofail,x-gvfs-show 0 0
   ```
4. **Permission Setup:**
   - Adds user to storage-related groups
   - Sets appropriate mount permissions
   - Configures group access for shared storage
5. **Management Tools:** Creates `storage` command for drive management

**⏱️ Time:** 3-4 minutes  
**👤 User Input:** Drive selection confirmation  
**💾 Result:** Automatic drive mounting on boot

---

### **13-setup-user-groups.sh**
**🎯 Purpose:** Adds user to all necessary groups for full system access  
**🔧 What it does:**
- Adds user to essential system groups
- Configures hardware access groups
- Sets up service-specific groups
- Creates development groups
- Provides group management tools

**📝 How it works:**
1. **Essential Groups:**
   - `wheel` - Sudo access and administrative privileges
   - `audio` - Audio device access
   - `video` - Video device access
   - `input` - Input device access
   - `storage` - Storage device access
2. **Hardware Groups:**
   - `render` - GPU rendering and compute access
   - `kvm` - KVM virtualization access
   - `libvirt` - Libvirt virtualization management
   - `docker` - Docker container management
3. **Service Groups:**
   - `media` - Media server and file access
   - `rtkit` - Real-time kit for audio
   - `gamemode` - GameMode optimization
4. **Development Groups:**
   - `debugfs` - Debug filesystem access
   - `systemd-journal` - Journal log access
   - `git` - Git repository access
5. **Verification:** Creates `groups_info` command for checking membership

**⏱️ Time:** 2-3 minutes  
**👤 User Input:** None  
**⚠️ Important:** Requires logout/login for changes to take effect

---

### **14-setup-services.sh**
**🎯 Purpose:** Manages and configures all system and user services  
**🔧 What it does:**
- Enables and starts essential services
- Configures media and AI services
- Sets up service health monitoring
- Creates service management tools
- Provides interactive service control

**📝 How it works:**
1. **Essential Services:**
   - `NetworkManager` - Network connectivity
   - `pipewire-pulse` - Modern audio system
   - `wireplumber` - Audio session manager
2. **Media Services:**
   - `emby-server` - Media server
   - `qbittorrent-nox` - Torrent client
3. **AI Services:**
   - `ollama` - AI platform (user or system service)
4. **Development Services:**
   - `docker` - Container platform
   - `libvirtd` - Virtualization
5. **Service Management:**
   - Interactive enable/disable options
   - Health checking and monitoring
   - Failure detection and reporting
   - Creates `services` command for management

**⏱️ Time:** 3-5 minutes  
**👤 User Input:** Service selection (interactive mode)  
**🔧 Result:** All services properly configured and running

---

### **15-system-optimization.sh**
**🎯 Purpose:** Applies performance optimizations and system tuning  
**🔧 What it does:**
- Configures kernel parameters for performance
- Sets up CPU governor for optimal performance
- Configures GPU settings for gaming/rendering
- Optimizes memory management
- Sets up system monitoring

**📝 How it works:**
1. **CPU Optimization:**
   - Sets performance governor
   - Configures CPU frequency scaling
   - Sets process scheduler optimizations
2. **Memory Optimization:**
   - Configures swappiness for SSD
   - Sets up memory overcommit handling
   - Optimizes page allocation
3. **GPU Optimization:**
   - Configures AMD GPU power management
   - Sets up ROCm optimizations
   - Enables GPU compute acceleration
4. **I/O Optimization:**
   - Sets SSD-optimized I/O scheduler
   - Configures disk cache settings
   - Optimizes filesystem performance
5. **Gaming Optimization:**
   - Enables GameMode integration
   - Configures process priorities
   - Sets up performance monitoring

**⏱️ Time:** 2-3 minutes  
**👤 User Input:** Optimization level selection  
**🚀 Result:** Optimized system performance

---

### **16-user-setup.sh**
**🎯 Purpose:** Final user environment configuration and personalization  
**🔧 What it does:**
- Sets up user shell configuration
- Configures personal aliases and functions
- Sets up development environment
- Configures user systemd services
- Creates personal automation tools

**📝 How it works:**
1. **Shell Configuration:**
   - Configures Fish shell with custom functions
   - Sets up command aliases for efficiency
   - Configures prompt and colors
2. **Development Environment:**
   - Sets up Git configuration
   - Configures SSH keys
   - Sets up development aliases
3. **Personal Automation:**
   - Creates custom scripts for common tasks
   - Sets up backup automation
   - Configures sync tools
4. **User Services:**
   - Enables user-specific systemd services
   - Configures auto-start applications
   - Sets up session management
5. **Personalization:**
   - Applies user preferences
   - Sets up custom keybindings
   - Configures personal workflows

**⏱️ Time:** 3-4 minutes  
**👤 User Input:** Personal preferences  
**🎯 Result:** Fully personalized user environment

---

## 🚀 Installation Workflow

### **Quick Reference:**
```bash
# Full automated installation
cd ~/dotfiles && ./scripts/setup/00-complete-installation.sh --yes

# Interactive installation  
cd ~/dotfiles && ./scripts/setup/00-complete-installation.sh

# Preview installation
cd ~/dotfiles && ./scripts/setup/00-complete-installation.sh --dry-run
```

### **What Happens During Installation:**

1. **Phase 1 (5 min):** System validation → Repository setup → Package downloads
2. **Phase 2 (15-30 min):** Package installation → Configuration deployment  
3. **Phase 3 (5 min):** Theming → Storage → External drives
4. **Phase 4 (10-20 min):** AI models → Virtualization setup
5. **Phase 5 (5 min):** Media services → User groups → Service configuration
6. **Phase 6 (5 min):** System optimization → Final user setup

**Total Time:** 30-60 minutes depending on internet speed and selected options

### **After Installation:**

1. **Log out and back in** (for group changes)
2. **Start desktop:** `Hyprland`  
3. **Set wallpaper:** `wallpaper-manager`
4. **Check services:** `services status`
5. **Test AI:** `ollama list`
6. **Access web interfaces:**
   - Dashboard: http://localhost:8080 (or `dashboard` command)
   - Emby: http://localhost:8096
   - qBittorrent: http://localhost:9090

---

## 🔧 Individual Script Usage

### **Running Scripts Individually:**

```bash
cd ~/dotfiles/scripts/setup

# Run any script individually
./05-setup-external-drives.sh
./07-setup-ollama.sh --dry-run
./13-setup-services.sh --enable-all
```

### **Common Script Options:**
- `--dry-run` - Preview changes without applying
- `--yes` - Skip confirmation prompts  
- `--help` - Show script-specific help

### **When to Run Individual Scripts:**
- **New hardware:** Re-run storage or GPU scripts
- **Service issues:** Re-run specific service scripts
- **Adding features:** Run optional scripts you skipped
- **Troubleshooting:** Re-run problematic scripts individually

---

## 🛠️ Troubleshooting

### **Script Failed? Here's How to Fix It:**

1. **Check the log file:**
   ```bash
   ls -la ~/dotfiles/logs/
   # Find the latest log file and check for errors
   ```

2. **Run individual script with dry-run:**
   ```bash
   ./XX-script-name.sh --dry-run
   ```

3. **Check service status:**
   ```bash
   services status
   services failed
   ```

### **Common Issues:**

**❌ Package installation fails:**
- Check internet connection
- Update package databases: `sudo pacman -Sy`
- Clear package cache: `sudo pacman -Scc`

**❌ Service won't start:**
- Check logs: `journalctl -u service-name`
- Verify dependencies: `systemctl list-dependencies service-name`
- Re-run service script: `./13-setup-services.sh`

**❌ Permissions denied:**
- Check user groups: `groups_info check`
- Log out and back in for group changes
- Re-run user groups script: `./12-setup-user-groups.sh`

**❌ Storage not mounting:**
- Check fstab: `storage fstab`
- Test mount: `sudo mount -a`
- Re-run storage script: `./11-setup-storage.sh`

---

## ✅ Verification Commands

### **Check Installation Success:**

```bash
# Overall system health
neofetch
services status
groups_info check

# Desktop environment
which hyprland waybar kitty fuzzel matugen

# Media setup
storage health
curl -s http://localhost:8080 > /dev/null && echo "Dashboard OK"
curl -s http://localhost:8096 > /dev/null && echo "Emby OK"
curl -s http://localhost:9090 > /dev/null && echo "qBittorrent OK"

# AI platform
ollama list
systemctl --user status ollama

# Development tools
docker --version
virt-manager --version
```

### **Performance Check:**
```bash
# Boot time
systemd-analyze

# Failed services  
systemctl --failed

# Disk usage
df -h

# Memory usage
free -h
```

---

This guide provides everything you need to understand, run, and troubleshoot the complete installation system. Each script is designed to be both standalone and part of the larger automation pipeline, giving you maximum flexibility and reliability.

🎉 **Your installation scripts now provide 100% automation for a complete, sophisticated Arch Linux + Hyprland desktop environment!**