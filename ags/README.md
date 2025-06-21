# AGS Desktop Shell Configuration

Complete AGS/Astal implementation to replace waybar, dunst, and fuzzel with a beautiful, feature-rich desktop shell.

## Features

### 🎯 Core Components
- **Top Bar** - Workspaces, window title, clock, system tray
- **Sidebar** - Control center with system stats and controls
- **App Launcher** - Fuzzy search application launcher
- **Notification Center** - Complete notification management
- **Dynamic Theming** - Full matugen integration

### ✨ Key Features
- Multi-monitor support (3 monitors)
- Wayland-native with layer shell
- TypeScript/JSX development
- Material Design 3 theming
- Smooth animations and transitions
- Real-time system monitoring

## Installation

### Prerequisites
```bash
# Install AGS/Astal
yay -S aylurs-gtk-shell

# Install dependencies
sudo pacman -S typescript nodejs npm
```

### Setup Commands
```bash
# Navigate to AGS directory
cd ~/.config/ags

# Initialize the project (if not symlinked)
ags init --typescript --gtk3

# Install dependencies
npm install

# Generate types
ags types

# Run in development mode
ags run

# Build for production
ags build
```

## Configuration

### Symlinking (Recommended)
The AGS configuration should be symlinked from your dotfiles:
```bash
ln -sf ~/dotfiles/ags ~/.config/ags
```

### Hyprland Integration
Add the keybinds from `hyprland-ags-keybinds.conf` to your Hyprland configuration:
```bash
source = ~/.config/ags/hyprland-ags-keybinds.conf
```

### Matugen Integration
The styling automatically integrates with matugen. Update colors with:
```bash
matugen image /path/to/wallpaper.jpg
```

## Usage

### Keybinds
- `Super + D` / `Super + Space` - Toggle application launcher
- `Super + S` - Toggle sidebar
- `Super + N` - Toggle notification center
- `Super + R` - Restart AGS

### Components

#### Sidebar Features
- Volume control with visual feedback
- System statistics (CPU, Memory, Temperature)
- Quick settings toggles
- Network information
- Media player controls
- Calendar widget

#### Application Launcher
- Fuzzy search functionality
- Application icons and descriptions
- Keyboard navigation (arrows, enter, escape)
- Recent applications tracking

#### Notification Center
- Notification history
- Action buttons support
- Priority-based sorting
- Clear all functionality

## File Structure

```
ags/
├── app.ts                    # Main entry point
├── widget/
│   ├── Bar/                  # Bar components
│   │   ├── TopBar.tsx
│   │   ├── BottomBar.tsx
│   │   └── components/
│   ├── Sidebar/              # Sidebar components
│   │   ├── Sidebar.tsx
│   │   └── components/
│   ├── Launcher/             # App launcher
│   │   └── AppLauncher.tsx
│   └── Notifications/        # Notification system
│       └── NotificationCenter.tsx
├── style/                    # Styling
│   └── main.scss
├── config/                   # Configuration
│   └── monitors.ts
└── package.json
```

## Development

### Running in Development
```bash
ags run
```

### Debugging
```bash
# Check AGS logs
ags run --verbose

# Inspect windows
ags inspector
```

### Customization
1. Edit components in `widget/` directories
2. Modify styling in `style/main.scss`
3. Update configuration in `config/monitors.ts`
4. Restart AGS to see changes

## Troubleshooting

### Common Issues
1. **Imports not found**: Run `ags types` to generate type definitions
2. **Styling not applied**: Ensure SCSS compilation is working
3. **Keybinds not working**: Check Hyprland configuration includes the keybind file
4. **Notifications not showing**: Ensure `astal-notifd` service is running

### Logs
Check AGS logs for debugging:
```bash
journalctl -f | grep ags
```

## Integration Notes

This configuration is designed to work with:
- Hyprland compositor
- Matugen theming system
- Multi-monitor setups
- Arch Linux with fish shell

Replaces:
- waybar (top/bottom bars)
- dunst (notifications)
- fuzzel (application launcher) 