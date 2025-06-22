# EWW Sidepanel for Hyprland

A beautiful, functional sidepanel widget system built with EWW (ElKowars wacky widgets) designed specifically for Hyprland window manager.

![EWW Sidepanel Demo](screenshot.png) <!-- Add screenshot when available -->

## ✨ Features

### System Monitoring
- **CPU Usage** - Real-time CPU utilization with progress bar
- **RAM Usage** - Memory consumption monitoring
- **Disk Usage** - Storage space tracking
- **Temperature** - System temperature monitoring
- **Battery Status** - Battery level with visual indicator

### Media Controls
- **Music Player** - Current playing track display
- **Playback Controls** - Play/pause, previous/next track buttons
- **Player Integration** - Works with any MPRIS-compatible media player

### Weather Information
- **Current Weather** - Temperature and conditions
- **Weather Icons** - Visual weather indicators
- **Auto-refresh** - Updates every 5 minutes
- **Customizable Location** - Set your city in configuration

### Quick Settings
- **Volume Control** - Smooth volume adjustment slider
- **Brightness Control** - Safe 4-level brightness buttons (25%, 50%, 75%, 100%)
- **Network Status** - Connection status and network name display

### Calendar & Time
- **Digital Clock** - Real-time clock display
- **Date Information** - Current date and month
- **Clean Layout** - Minimal, readable design

## 🔧 Requirements

### System Dependencies
- **Hyprland** - Window manager
- **EWW** - Widget system
- **Fish Shell** - Script execution
- **ddcutil** - Display brightness control
- **playerctl** - Media player control
- **pamixer** - Audio control
- **bc** - Calculator for system metrics
- **jq** - JSON processing
- **curl** - Weather data fetching

### Installation Commands

**Arch Linux:**
```bash
sudo pacman -S eww playerctl ddcutil pamixer bc jq curl
```

**Debian/Ubuntu:**
```bash
sudo apt update
sudo apt install eww playerctl ddcutil pamixer bc jq curl
```

## 🚀 Installation

### Automatic Installation
1. **Clone or download** this EWW sidepanel setup
2. **Navigate** to the setup directory:
   ```bash
   cd scripts/setup/eww-sidepanel/
   ```
3. **Run the setup script**:
   ```bash
   fish setup.fish
   ```
4. **Follow the prompts** - The script will handle everything automatically

### Manual Installation
1. **Create EWW directory**:
   ```bash
   mkdir -p ~/.config/eww/scripts
   ```
2. **Copy configuration files**:
   ```bash
   cp eww.yuck ~/.config/eww/
   cp eww.scss ~/.config/eww/
   cp scripts/*.fish ~/.config/eww/scripts/
   ```
3. **Make scripts executable**:
   ```bash
   chmod +x ~/.config/eww/scripts/*
   ```
4. **Add Hyprland keybind** to `~/.config/hypr/hyprland.conf`:
   ```
   bind = SUPER, F10, exec, ~/.config/eww/toggle_sidebar.fish
   ```

## 🎮 Usage

### Toggle Sidepanel
- **Keyboard**: Press `SUPER + F10`
- **Command**: Run `~/.config/eww/toggle_sidebar.fish`

### Starting EWW Daemon
If the sidepanel doesn't appear:
```bash
eww daemon
```

### Reload Configuration
After making changes:
```bash
eww reload
```

## ⚙️ Configuration

### Weather Location
Edit the weather city in `eww.yuck`:
```lisp
(defvar weather_city "Stockholm") ; Change to your city
```

### Brightness Control
The brightness control safely manages all displays with these features:
- **Multi-display support** - Controls up to 3 displays simultaneously
- **Safe operation** - Uses delays to prevent system overload
- **Error handling** - Gracefully handles missing displays
- **Four preset levels** - 25%, 50%, 75%, 100%

### Polling Intervals
Adjust system monitoring frequency in `eww.yuck`:
```lisp
(defpoll cpu_usage :interval "5s" ...)  ; CPU check every 5 seconds
(defpoll weather_temp :interval "300s" ...) ; Weather every 5 minutes
```

### Styling
Customize appearance in `eww.scss`:
- Colors and themes
- Widget sizing
- Spacing and layout
- Hover effects

## 🛠️ Troubleshooting

### Sidepanel Won't Open
1. **Check EWW daemon**:
   ```bash
   eww ping
   # If no response, start daemon:
   eww daemon
   ```

2. **Check configuration**:
   ```bash
   eww reload
   eww logs
   ```

### Brightness Control Not Working
1. **Check ddcutil access**:
   ```bash
   sudo ddcutil detect
   ```
2. **Add user to i2c group**:
   ```bash
   sudo usermod -a -G i2c $USER
   # Then logout and login again
   ```

### Scripts Not Executing
1. **Check permissions**:
   ```bash
   ls -la ~/.config/eww/scripts/
   # All files should have execute permission (+x)
   ```

2. **Make executable if needed**:
   ```bash
   chmod +x ~/.config/eww/scripts/*
   ```

### High CPU Usage
If system monitoring causes high CPU usage:
1. **Increase polling intervals** in `eww.yuck`
2. **Disable unused widgets**
3. **Check for failed commands** in `eww logs`

## 📁 File Structure

```
eww-sidepanel/
├── eww.yuck              # Main EWW configuration
├── eww.scss              # Stylesheet
├── setup.fish            # Automated setup script
├── toggle_sidebar.fish   # Toggle script
├── scripts/
│   ├── brightness.fish   # Safe brightness control
│   ├── system.fish       # System monitoring
│   ├── music.fish        # Media player integration
│   ├── weather.fish      # Weather data fetching
│   └── network.fish      # Network status
└── README.md            # This file
```

## 🔒 Safety Features

This EWW setup includes several safety measures:
- **Rate-limited polling** - Prevents system overload
- **Error handling** - Graceful failure handling
- **Safe brightness control** - No continuous hardware polling
- **Background execution** - Non-blocking operations
- **Input validation** - Prevents invalid commands

## 🤝 Contributing

Feel free to submit issues, feature requests, or pull requests to improve this EWW sidepanel setup.

## 📄 License

This project is open source. Feel free to modify and distribute according to your needs.

---

**Enjoy your new EWW sidepanel!** 🎉 