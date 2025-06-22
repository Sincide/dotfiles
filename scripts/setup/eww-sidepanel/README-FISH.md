# EWW Dark Glass Sidepanel for Hyprland (Fish Shell)

A beautiful, feature-rich sidepanel built with EWW (Elkowar's Wacky Widgets) featuring a dark glassmorphism design. **Specifically optimized for Fish Shell users.**

## ✨ Features

- **🎛️ System Monitoring**: CPU, RAM, disk usage, temperature, and battery
- **🎵 Music Player**: Full playerctl integration with playback controls
- **🌤️ Weather Widget**: Real-time weather information with icons
- **📅 Calendar**: Current time and date display
- **⚙️ Quick Settings**: Volume, brightness controls, and network info
- **🪟 Glassmorphism Design**: Beautiful dark glass aesthetic with blur effects
- **🎯 Hyprland Optimized**: Slide-in animation with overlay stacking
- **⌨️ Keybind Support**: Toggle with Super + grave (`) key
- **🐟 Fish Shell Native**: All scripts written in Fish shell syntax

## 📋 Prerequisites

### Required Dependencies
```fish
# Core dependencies
eww playerctl brightnessctl bc jq curl

# For system monitoring (optional)
lm-sensors  # For temperature readings
```

### Installation by Distribution

**Arch Linux:**
```fish
sudo pacman -S eww playerctl brightnessctl bc jq curl
```

**Ubuntu/Debian:**
```fish
sudo apt install eww playerctl brightnessctl bc jq curl
```

**Fedora:**
```fish
sudo dnf install eww playerctl brightnessctl bc jq curl
```

## 🚀 Quick Setup for Fish Shell

### Automatic Installation

1. **Download all files** to a directory:
   ```fish
   mkdir ~/Downloads/eww-sidepanel-fish
   cd ~/Downloads/eww-sidepanel-fish
   # Download all files here
   ```

2. **Create the directory structure:**
   ```fish
   mkdir scripts
   ```

3. **Move files to correct locations:**
   ```fish
   # Move script files to scripts directory
   mv system.fish scripts/
   mv music.fish scripts/
   mv weather.fish scripts/
   mv network.fish scripts/
   ```

4. **Run the Fish setup script:**
   ```fish
   chmod +x setup.fish
   ./setup.fish
   ```

### Manual Installation (Fish Shell)

If you prefer manual setup:

1. **Create directories:**
   ```fish
   mkdir -p ~/.config/eww/scripts
   ```

2. **Copy files:**
   ```fish
   # Copy main config files
   cp eww.yuck ~/.config/eww/
   cp eww.scss ~/.config/eww/
   
   # Copy Fish scripts
   cp scripts/*.fish ~/.config/eww/scripts/
   chmod +x ~/.config/eww/scripts/*.fish
   
   # Copy toggle script
   cp toggle_sidebar.fish ~/.config/eww/
   chmod +x ~/.config/eww/toggle_sidebar.fish
   ```

3. **Add Hyprland keybind** to `~/.config/hypr/hyprland.conf`:
   ```
   bind = SUPER, grave, exec, ~/.config/eww/toggle_sidebar.fish
   ```

## 🎮 Usage

### Opening the Sidebar
- **Keybind**: Press `Super + grave (`)` 
- **Manual**: Run `~/.config/eww/toggle_sidebar.fish`
- **Direct**: `eww open sidebar_window`

### Starting EWW Daemon
```fish
eww daemon &
```

### Reloading Configuration
```fish
eww reload
```

## 🎨 Customization

### Changing Weather City
Edit `~/.config/eww/scripts/weather.fish`:
```fish
set CITY "YourCity"  # Change this to your city
```

### Testing Individual Scripts
```fish
# Test system monitoring
fish ~/.config/eww/scripts/system.fish cpu
fish ~/.config/eww/scripts/system.fish ram

# Test music player
fish ~/.config/eww/scripts/music.fish title
fish ~/.config/eww/scripts/music.fish status

# Test weather
fish ~/.config/eww/scripts/weather.fish temp
fish ~/.config/eww/scripts/weather.fish icon

# Test network
fish ~/.config/eww/scripts/network.fish status
fish ~/.config/eww/scripts/network.fish name
```

### Widget Configuration
Edit `~/.config/eww/eww.yuck` to:
- Add/remove widgets
- Change update intervals
- Modify widget layouts

### Styling
Edit `~/.config/eww/eww.scss` to:
- Change colors and themes
- Modify animations
- Adjust sizing

## 📊 Available Fish Scripts

All scripts are located in `~/.config/eww/scripts/`:

### system.fish
```fish
fish system.fish cpu     # CPU usage percentage
fish system.fish ram     # RAM usage percentage  
fish system.fish disk    # Disk usage percentage
fish system.fish temp    # CPU temperature
fish system.fish battery # Battery percentage
```

### music.fish
```fish
fish music.fish title    # Current song title
fish music.fish artist   # Current artist
fish music.fish status   # Play/pause status
fish music.fish album    # Current album
fish music.fish position # Current position
fish music.fish length   # Track length
```

### weather.fish
```fish
fish weather.fish temp      # Current temperature
fish weather.fish desc      # Weather description
fish weather.fish icon      # Weather emoji
fish weather.fish humidity  # Humidity percentage
fish weather.fish feels_like # Feels like temperature
fish weather.fish wind      # Wind information
```

### network.fish
```fish
fish network.fish status  # Connection status
fish network.fish name    # Network name/SSID
fish network.fish type    # Connection type
fish network.fish ip      # Local IP address
fish network.fish speed   # Connection speed
fish network.fish signal  # WiFi signal strength
fish network.fish usage   # Network usage stats
```

## 🐛 Troubleshooting

### EWW Won't Start
```fish
# Check if EWW is installed
eww --version

# Start daemon manually
eww daemon &

# Check for errors
eww logs
```

### Scripts Not Working
```fish
# Make scripts executable
chmod +x ~/.config/eww/scripts/*.fish
chmod +x ~/.config/eww/toggle_sidebar.fish

# Test scripts individually
fish ~/.config/eww/scripts/system.fish cpu
```

### Fish Shell Issues
```fish
# Check Fish version
fish --version

# Test Fish syntax in scripts
fish -n ~/.config/eww/scripts/system.fish
```

### Weather Not Loading
```fish
# Test weather script
fish ~/.config/eww/scripts/weather.fish temp

# Check internet and jq
curl -s "wttr.in/Stockholm?format=j1"
jq --version
```

### Music Player Issues
```fish
# Check playerctl
playerctl status
playerctl -l

# Test with specific player
playerctl -p spotify status
```

## 🔧 Fish Shell Specific Features

### Function-based Architecture
All scripts use Fish's native function syntax for better performance and readability.

### String Matching
Uses Fish's `string match` instead of bash pattern matching for more reliable comparisons.

### Math Operations
Uses Fish's built-in `math` function instead of external calculators where possible.

### Error Handling
Leverages Fish's `test` command and logical operators for robust error handling.

## 📝 File Structure
```
~/.config/eww/
├── eww.yuck              # Main configuration (Fish-compatible)
├── eww.scss              # Styling
├── toggle_sidebar.fish   # Toggle script (Fish)
└── scripts/
    ├── system.fish       # System monitoring (Fish)
    ├── music.fish        # Music controls (Fish)
    ├── weather.fish      # Weather data (Fish)
    └── network.fish      # Network info (Fish)
```

## 🤝 Fish Shell Advantages

- **Cleaner Syntax**: More readable and maintainable scripts
- **Better Error Handling**: Fish's built-in error checking
- **Modern Features**: Advanced string manipulation and math
- **Auto-completion**: Fish provides excellent tab completion
- **No Bashisms**: Pure Fish shell compatibility

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

**Enjoy your Fish-powered EWW sidepanel! 🐟🎉**

For Fish shell specific support, make sure you're running Fish 3.0+ and all scripts are marked executable.