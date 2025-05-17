# Dotfiles

My personal dotfiles for Arch Linux with Hyprland.

## Directory Structure

```
.
├── assets/               # Static assets
│   └── wallpapers/      # Wallpaper images
├── config/              # All configuration files
│   ├── applications/    # Desktop entries
│   ├── dunst/          # Notification daemon
│   ├── fish/           # Fish shell
│   │   ├── conf.d/     # Fish configuration modules
│   │   ├── completions/# Custom completions
│   │   └── config.fish # Main fish config
│   ├── gtk-3.0/        # GTK3 theming
│   ├── gtk-4.0/        # GTK4 theming
│   ├── hypr/           # Hyprland compositor
│   │   ├── scripts/    # Hyprland helper scripts
│   │   ├── hyprland.conf    # Main config
│   │   ├── hyprpaper.conf   # Wallpaper config
│   │   ├── env.conf         # Environment variables
│   │   ├── monitors-physical.conf  # Physical machine monitor config
│   │   └── monitors-vm.conf       # VM monitor config
│   ├── kitty/          # Terminal emulator
│   ├── lf/             # Terminal file manager
│   │   ├── lfrc        # Main configuration
│   │   ├── preview.sh  # File preview script
│   │   └── cleaner.sh  # Cleanup script
│   ├── qt5ct/          # Qt5 configuration
│   ├── qt6ct/          # Qt6 configuration
│   ├── swappy/         # Screenshot editor
│   ├── waybar/         # Status bar
│   │   ├── config      # Waybar configuration
│   │   ├── style.css   # Waybar styling
│   │   └── scripts/    # Status bar scripts
│   └── fuzzel/         # Application launcher
├── scripts/            # Utility scripts
│   ├── amd-overdrive.sh    # AMD GPU management
│   ├── backup-ssh.sh       # SSH key backup
│   ├── restore-ssh.sh      # SSH key restore
│   ├── setup-virtualization.sh # VM setup
│   └── dotfiles.sh         # Dotfiles management
├── install.sh          # Installation script
└── README.md           # This file
```

## Features

- **Window Manager**: Hyprland
- **Status Bar**: Waybar with two layouts:
  - Default Layout:
    - Decorated workspaces with application-specific icons
    - Full system monitoring (CPU, memory, GPU)
    - Audio controls with device selection
    - Clock with calendar
    - Git status monitoring
    - Package updates tracking
    - Modern, cohesive design with Catppuccin theme
  - Alternate Layout:
    - Minimalist, centered design
    - Japanese-style workspace indicators
    - Grouped system resources
    - Clean, semi-transparent styling
  - Quick toggle between layouts (Super + B)
- **Terminal**: Kitty
- **Shell**: Fish
- **Theme**: Catppuccin Mocha
- **File Managers**: 
  - **GUI**: Thunar
  - **Terminal**: lf (with Swedish keyboard-friendly keybindings)
- **Notifications**: Dunst
- **Application Launcher**: Fuzzel
- **Clipboard Manager**: Cliphist
- **Brightness Control**: DDC/CI-based multi-monitor brightness control
- **Environment Detection**: Automatic VM/Physical setup

## Prerequisites

- Fresh Arch Linux installation
- Internet connection
- Base development tools (`base-devel`)
- AMD GPU (for hardware acceleration and GPU management features)

## Installation

1. Clone this repository:
   ```bash
   # Replace with your actual repository URL
   git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. Run the installation script:
   ```bash
   ./install.sh
   ```

3. Log out and log back in to start Hyprland.

## Dotfiles Management

The repository includes a smart dotfiles management script (`scripts/dotfiles.sh`) that provides:

- Automatic commit message generation based on changed files
- Easy status checking with colored output
- Quick diff viewing
- Automated syncing with remote repository

### Command Line Usage
```bash
./scripts/dotfiles.sh <command>

Commands:
  status, st    Show status of dotfiles
  sync, s       Sync dotfiles (add, commit, pull, push)
  diff, d       Show diff of changes
```

### Fish Shell Aliases
The following aliases are available for Fish shell users:

- `dot` - Show available commands and usage
- `dots` - Sync dotfiles (add, commit, pull, push)
- `dotst` - Show colored status of dotfiles
- `dotd` - Show diff of changes

These aliases are automatically configured in `~/.config/fish/config.fish` during installation.

## Monitor Configuration

The setup includes smart monitor detection and configuration:

### Physical Setup
- Supports multi-monitor setup with different resolutions and refresh rates
- Automatically configures workspace assignments
- Handles high refresh rate displays (up to 165Hz)
- DDC/CI monitor brightness control via quick settings menu

### VM Setup
- Automatically detects VM environment
- Configures appropriate display settings
- Enables necessary VM-specific variables

## Keybindings

### Basic Controls
- `SUPER + Return` - Open terminal
- `SUPER + W` - Open Firefox
- `SUPER + C` - Close window
- `SUPER + D` - Open application launcher
- `SUPER + [1-0]` - Switch to workspace
- `SUPER + Shift + [1-0]` - Move window to workspace
- `SUPER + B` - Toggle between Waybar layouts
- `SUPER + L` - Lock screen
- `SUPER + Shift + L` - Suspend system

### Window Management
- `SUPER + V` - Toggle floating
- `SUPER + F` - Toggle fullscreen
- `SUPER + P` - Toggle pseudo-tiling
- `SUPER + J` - Toggle split
- `SUPER + Arrow keys` - Move focus

### Media Controls
- Volume keys - Control audio volume
- Media keys - Control media playback
- Brightness keys - Control screen brightness (physical machines only)

### Screenshots
- `Print` - Screenshot area to clipboard
- `Shift + Print` - Screenshot full screen
- `SUPER + Print` - Screenshot active window

All screenshots are opened in Swappy for editing before saving.

### Clipboard
The system uses Cliphist for clipboard management:
- Automatically stores text and image clipboard history
- Accessible through Fuzzel interface

### Quick Settings
- Available through Waybar menu
- Brightness control via DDC/CI (controls actual monitor brightness)
- Night light mode (blue light filter)
- Quick access to system settings

More keybindings can be found in `~/.config/hypr/hyprland.conf`

## Waybar Configuration

The setup includes two different Waybar layouts that can be toggled with `SUPER + B`:

### Default Layout
- Full-featured status bar with system monitoring
- Decorated workspaces with application-specific icons
- Compact design with separators between modules
- Detailed system information with tooltips
  - CPU usage and frequency
  - Memory usage
  - GPU temperature, usage, and memory
  - Package updates counter
  - Git status monitoring

### Alternate Layout
- Minimalist, centered design
- Workspace indicators
- Semi-transparent background with modern styling
- Grouped system resources
  - CPU, memory, and GPU monitoring
  - Live resource usage updates
  - Detailed tooltips with comprehensive stats
- Live clock with seconds display
- High contrast, easily readable at a glance

## Included Packages

### Core Components
- hyprland (Wayland compositor)
- waybar (Status bar)
- fuzzel (Application launcher)
- dunst (Notification daemon)
- kitty (Terminal emulator)
- fish (Shell)
- thunar (File manager)
- lf (Terminal file manager)

### System Integration
- polkit-gnome (Authentication agent)
- xdg-desktop-portal-hyprland (XDG portal)
- network-manager-applet (Network management)
- blueman (Bluetooth management)
- pavucontrol (Audio control)
- cliphist (Clipboard manager)

### Theming and Appearance
- catppuccin-gtk-theme-mocha (GTK theme)
- papirus-icon-theme (Icon theme)
- ttf-jetbrains-mono-nerd (Main font)
- ttf-inter (UI font)
- noto-fonts (Base font)
- noto-fonts-emoji (Emoji support)
- noto-fonts-cjk (CJK support)

### AMD-Specific
- corectrl (GPU management)
- vulkan-radeon (Vulkan support)
- libva-mesa-driver (Video acceleration)
- mesa-vdpau (OpenGL support)
- radeontop (GPU usage monitoring)
- lm_sensors (Hardware sensors)

### Utilities
- brightnessctl (Brightness control for laptops)
- ddcutil (Monitor brightness control via DDC/CI)
- wlsunset (Night light / blue light filter)
- grim (Screenshot utility)
- slurp (Area selection)
- swappy (Screenshot editor)
- playerctl (Media control)
- pamixer (Audio control)

## Customization

The GTK theme is set to Catppuccin Mocha Blue by default. To change the accent color, modify:
- `~/.config/gtk-3.0/settings.ini`
- `~/.config/gtk-4.0/settings.ini`
- `~/.config/hypr/env.conf`

Available accent colors can be found in `/usr/share/themes/` (all Catppuccin-Mocha variants).

## Contributing

Feel free to submit issues and pull requests for improvements or bug fixes.

## Notes

- Existing configurations will be backed up with a .bak extension
- The install script can be run multiple times safely
- To update, just pull the latest changes and run the install script again

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Environment Detection

The install script automatically detects whether it's running in a VM or on physical hardware and configures the system accordingly:

### VM Environment
- Configures single Virtual-1 monitor
- Enables software cursor and renderer
- Disables hardware-specific features
- Simplified wallpaper configuration

### Physical Hardware
- Configures multi-monitor setup
- Uses hardware acceleration
- Enables all features including brightness control
- Full monitor-specific wallpaper setup

## AMD-Specific Features

### AMD GPU Management
The repository includes an AMD GPU management script (`scripts/amd-overdrive.sh`) that provides:
- GPU overclocking capabilities
- Power management control
- Fan curve configuration
- Temperature monitoring and control

Usage:
```bash
# View current GPU settings
amd-oc status

# Apply custom profile
sudo amd-oc apply profile1

# Reset to default settings
sudo amd-oc reset
```

### AMD Hardware Acceleration
The configuration automatically sets up hardware acceleration for AMD GPUs with:
- VAAPI support for video decoding
- Vulkan support with RADV driver
- OpenGL optimization with mesa-vdpau

## Virtualization Support

The `scripts/setup-virtualization.sh` script helps set up a complete virtualization environment:
- Configures KVM/QEMU
- Sets up network bridges
- Configures user permissions
- Enables required kernel modules

Usage:
```bash
./scripts/setup-virtualization.sh
```

## SSH Key Management

The repository includes scripts for safely managing SSH keys:

### Backup SSH Keys
```bash
./scripts/backup-ssh.sh [backup_path]
```
Features:
- Encrypts SSH keys before backup
- Creates timestamped backups
- Verifies backup integrity

### Restore SSH Keys
```bash
./scripts/restore-ssh.sh [backup_file]
```
Features:
- Verifies backup authenticity
- Restores keys with correct permissions
- Validates restored keys

Security Notes:
- Always encrypt backups with a strong passphrase
- Store backups in a secure location
- Never share or transfer unencrypted keys
- Verify key permissions after restore (600 for private keys)

## Fish Shell Aliases and Functions

The configuration includes several useful aliases and functions in Fish shell:

### File Management
- `ls`, `ll`, `la`, `lt`, `ltr`, `lg` - Enhanced directory listing with `eza`
- `fm` - Launch lf file manager
- `lfcd` - Launch lf and change to last directory on exit (bound to Alt+o)

### Git
- `g` - Git shorthand
- `ga`, `gc`, `gp` etc. - Git command shortcuts

### Navigation
- `..`, `...`, `.3`, `.4` - Quickly navigate up directories
- `md` - Create and navigate to a directory in one command

### Dotfiles
- `dot` - Show available commands and usage
- `dots` - Sync dotfiles (add, commit, pull, push)
- `dotst` - Show colored status of dotfiles
- `dotd` - Show diff of changes

## File Manager Setup

This repository contains configuration for the following file managers:

### lf (Current)

A terminal file manager written in Go with vim-like keybindings, configured to work well with Swedish keyboard layout.

Key features:
- Swedish keyboard-friendly keybindings
- File previews (text, images, archives)
- Integration with Fish shell

To use:
- Run `lf` or the alias `fm` in terminal
- Use Alt+o in Fish shell to launch lf with directory tracking (lfcd function)

### Key Bindings for lf

#### Navigation
- Arrow keys: Navigate up/down/left/right
- Enter: Open file/directory
- Left Arrow: Go up one directory
- Right Arrow: Open file/directory

#### File Operations
- d or Delete: Delete files (with confirmation)
- r: Rename file
- c: Copy file
- x: Cut file
- v: Paste file
- e: Edit file with nano

#### File Creation
- n: Create new file
- N: Create new directory

#### View Options
- .: Toggle hidden files
- s: Sort by size
- t: Sort by time

## Other Configurations

Contains configurations for:
- Fish shell
- lf file manager
- (Other configurations in this repository)

## Installation

```
git clone https://github.com/yourusername/dotfiles.git
cd dotfiles
# Create symbolic links as needed
```

## Key Bindings for lf

### Navigation
- Arrow keys: Navigate up/down/left/right
- Enter: Open file/directory
- Left Arrow: Go up one directory
- Right Arrow: Open file/directory

### File Operations
- d or Delete: Delete files (with confirmation)
- r: Rename file
- c: Copy file
- x: Cut file
- v: Paste file
- e: Edit file with nano

### File Creation
- n: Create new file
- N: Create new directory

### View Options
- .: Toggle hidden files
- s: Sort by size
- t: Sort by time 