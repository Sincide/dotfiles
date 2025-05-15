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
│   ├── gtk-3.0/        # GTK3 theming
│   ├── gtk-4.0/        # GTK4 theming
│   ├── hypr/           # Hyprland compositor
│   │   ├── monitors-physical.conf  # Physical machine monitor config
│   │   ├── monitors-vm.conf       # VM monitor config
│   │   └── hyprland.conf         # Main config
│   ├── kitty/          # Terminal emulator
│   ├── qt5ct/          # Qt5 configuration
│   ├── qt6ct/          # Qt6 configuration
│   ├── swappy/         # Screenshot editor
│   ├── waybar/         # Status bar
│   ├── wofi/           # Application launcher
│   └── xfce4/          # XFCE4 components (Thunar)
├── install.sh          # Installation script
└── README.md           # This file
```

## Features

- **Window Manager**: Hyprland
- **Status Bar**: Waybar
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

## What's Included

- **Window Manager**: Hyprland
- **Status Bar**: Waybar
- **Terminal**: Kitty
- **Shell**: Fish with custom prompt
- **Theme**: Catppuccin Mocha
- **Icons**: Custom icon configuration
- **Fonts**: JetBrains Mono Nerd Font

## Post-Installation

After installation, you might want to:
1. Configure git with your credentials
2. Customize any personal preferences in the config files
3. Check Waybar modules are working correctly

## Keybindings

- `SUPER + Return` - Open terminal
- `SUPER + Q` - Close window
- `SUPER + Space` - Open application launcher
- `SUPER + [1-0]` - Switch to workspace
- `SUPER + Shift + [1-0]` - Move window to workspace
- More keybindings can be found in `~/.config/hypr/hyprland.conf`

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

The GTK theme is set to Catppuccin Mocha Blue by default. To change the accent color, modify the following files:
- `~/.config/gtk-3.0/settings.ini`
- `~/.config/gtk-4.0/settings.ini`
- `~/.config/hypr/env.conf`

Available accent colors can be found in `/usr/share/themes/` (all Catppuccin-Mocha variants).

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