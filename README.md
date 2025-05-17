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
│   ├── qt5ct/          # Qt5 configuration
│   ├── qt6ct/          # Qt6 configuration
│   ├── swappy/         # Screenshot editor
│   ├── waybar/         # Status bar
│   │   ├── config      # Waybar configuration
│   │   ├── style.css   # Waybar styling
│   │   └── scripts/    # Status bar scripts
│   ├── wofi/           # Application launcher
│   └── xfce4/          # XFCE4 components (Thunar)
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
- **Status Bar**: Waybar with:
  - Animated launcher
  - Workspace indicators with underline effects
  - System monitoring (CPU, memory, network)
  - Audio controls
  - Clock with calendar
  - Notification toggle
  - Modern, cohesive design with Catppuccin theme
  - Quick toggle between default and alternate layouts (Super + B)
- **Terminal**: Kitty
- **Shell**: Fish
- **Theme**: Catppuccin Mocha
- **File Manager**: Thunar
- **Notifications**: Dunst
- **Application Launcher**: Wofi
- **Environment Detection**: Automatic VM/Physical setup

## Prerequisites

- Fresh Arch Linux installation
- Internet connection
- Base development tools (`base-devel`)

## Installation

1. Clone this repository:
   ```bash
   git clone https://gitlab.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
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

### VM Setup
- Automatically detects VM environment
- Configures appropriate display settings
- Enables necessary VM-specific variables

## Keybindings

- `SUPER + Return` - Open terminal
- `SUPER + Q` - Close window
- `SUPER + Space` - Open application launcher
- `SUPER + [1-0]` - Switch to workspace
- `SUPER + Shift + [1-0]` - Move window to workspace
- `SUPER + B` - Toggle between default and alternate Waybar layouts
- More keybindings can be found in `~/.config/hypr/hyprland.conf`

## Waybar Configuration

The setup includes two different Waybar configurations that can be toggled with `SUPER + B`:

### Default Layout
- Full-featured status bar with system monitoring
- Decorated workspaces with application-specific icons
- Compact design with separators between modules
- Detailed system information with tooltips

### Alternate Layout
- Minimalist, centered design with Japanese-inspired workspace indicators
- Semi-transparent background with modern styling
- Weather widget showing conditions for your location
- Grouped system resources
- Live clock with seconds display
- High contrast, easily readable at a glance

The toggle functionality is provided by the `~/.config/hypr/scripts/waybar-toggle.sh` script, which switches between configuration files (`config.default`/`style.default.css` and `config.alt`/`style.alt.css`) while preserving your modifications to the active configuration.

## Included Packages

### Core Components
- hyprland (Wayland compositor)
- waybar (Status bar)
- wofi (Application launcher)
- dunst (Notification daemon)
- kitty (Terminal emulator)
- fish (Shell)
- thunar (File manager)

### System Integration
- polkit-kde-agent (Authentication agent)
- xdg-desktop-portal-hyprland (XDG portal)
- network-manager-applet (Network management)
- blueman (Bluetooth management)
- pavucontrol (Audio control)

### Theming and Appearance
- catppuccin-gtk-theme-mocha (GTK theme)
- papirus-icon-theme (Icon theme)
- nwg-look (GTK theme manager)
- gtk3, gtk4 (GTK libraries)
- qt5ct, qt6ct (Qt theme configuration)
- ttf-jetbrains-mono-nerd (Main font)
- noto-fonts (Base font)
- noto-fonts-emoji (Emoji support)
- noto-fonts-cjk (CJK support)

### Utilities
- brightnessctl (Brightness control)
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