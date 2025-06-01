# Dynamic Theming System

A complete wallpaper-based dynamic theming system for Hyprland that automatically adapts your entire desktop theme to match your wallpaper colors.

## ✨ Features

- **Simple Selection**: Use fuzzel to choose wallpapers from a clean menu
- **Automatic Theming**: Extracts colors from wallpapers and applies them across all applications
- **Smooth Transitions**: Beautiful wallpaper transitions with swww
- **Complete Integration**: Updates Hyprland, Waybar (dual bars), Kitty, Dunst, and Fuzzel
- **One Keybind**: Press `Super+B` for instant wallpaper + theme changes

## 🎯 How It Works

1. **Press Super+B** → Opens fuzzel with your wallpaper collection
2. **Select wallpaper** → Sets wallpaper with swww (smooth wipe transition)
3. **Automatic magic** → Extracts colors with matugen and updates all applications
4. **Live updates** → Waybar, terminal, notifications instantly reflect new colors

## 🔧 Technical Deep Dive

### Architecture Overview

```
User Input (Super+B)
       ↓
wallpaper-selector.sh
       ↓
[Fuzzel Menu] → User selects wallpaper
       ↓
swww img (sets wallpaper)
       ↓
wallpaper-theme-changer.sh
       ↓
matugen (extracts colors)
       ↓
Templates → Generated configs
       ↓
Application reloads
```

### Component Breakdown

#### 1. **wallpaper-selector.sh** (Main Interface)
**Purpose**: Front-end wallpaper picker triggered by Super+B

**What it does:**
```bash
# 1. Checks swww daemon status
if ! pgrep -x swww-daemon > /dev/null; then
    swww init
fi

# 2. Scans wallpaper directory
find "$WALLPAPERS_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" ... \)

# 3. Shows fuzzel menu
selected_name=$(echo "$wallpaper_list" | format_for_display | fuzzel --dmenu)

# 4. Sets wallpaper with transition
swww img "$selected_wallpaper" --transition-type wipe --transition-duration 2

# 5. Triggers theming
"$THEME_SCRIPT" "$selected_wallpaper"
```

**Key Features:**
- Auto-starts swww daemon if needed
- Handles all image formats (PNG, JPG, JPEG, WEBP)
- Provides user feedback via notifications
- Error handling for missing files

#### 2. **wallpaper-theme-changer.sh** (Theme Engine)
**Purpose**: Core theming logic that applies colors system-wide

**Workflow:**
```bash
# 1. Color Extraction
matugen image "$wallpaper" --mode dark

# 2. Template Processing (automatic via matugen config)
# Templates → Generated configs:
# - hyprland-colors.conf → ~/.config/hypr/conf/colors.conf
# - waybar-style.css → ~/.config/waybar/style-dynamic.css
# - kitty.conf → ~/.config/kitty/theme-dynamic.conf
# - dunst.conf → ~/.config/dunst/dunstrc-dynamic
# - fuzzel.ini → ~/.config/fuzzel/fuzzel-dynamic.ini

# 3. Application Reloads
reload_applications()
```

**Application-Specific Reload Logic:**

```bash
# Waybar: Signal-based reload + force restart fallback
pkill -SIGUSR2 waybar
if still_running; then
    pkill -TERM waybar
    waybar -s ~/.config/waybar/style-dynamic.css &
    waybar -c ~/.config/waybar/config-bottom -s ~/.config/waybar/style-bottom-dynamic.css &
fi

# Dunst: Simple restart
pkill dunst
dunst -config ~/.config/dunst/dunstrc-dynamic &

# Kitty: Live reload via signal
pkill -USR1 kitty

# Hyprland: Config reload
hyprctl reload

# Fuzzel: Direct config modification (no includes support)
python3 script to replace [colors] section
```

#### 3. **matugen** (Color Science Engine)
**Purpose**: Extracts scientifically harmonious colors using Material Design 3

**Input**: Image file  
**Output**: Color palette with semantic tokens

**Key Color Variables:**
```
{{colors.primary.dark.hex}}           # Main accent: #d8bafa
{{colors.surface.dark.rgba}}          # Background: rgba(21, 18, 24, 1.0)
{{colors.on_surface.dark.hex}}        # Text: #e8e0e8
{{colors.primary_container.dark.hex}} # Highlighted areas: #543b72
{{colors.error.dark.hex}}             # Error states: #ff5449
{{colors.outline.dark.hex}}           # Borders: #958e99
```

**Material Design 3 Benefits:**
- **Accessibility**: Proper contrast ratios
- **Harmony**: Colors that work well together
- **Semantic meaning**: Error, warning, success colors
- **Adaptive**: Works in light/dark modes

#### 4. **Template System**
**Purpose**: Convert color variables into application-specific configs

**Example - Waybar Template:**
```css
/* Template (waybar-style.css) */
#cpu {
    color: {{colors.primary.dark.hex}};
    background: {{colors.surface_variant.dark.rgba}};
}

/* Generated (style-dynamic.css) */
#cpu {
    color: #d8bafa;
    background: rgba(29, 26, 33, 1.0);
}
```

**Template Processing:**
1. **Handlebars syntax**: `{{variable}}` placeholders
2. **Real-time generation**: matugen processes on wallpaper change
3. **Output locations**: Defined in `config/matugen/config.toml`

### Application Integration Details

#### **Hyprland** (Window Manager)
```bash
# Integration method: Include generated file
# Main config includes: ~/.config/hypr/conf/colors.conf

# Template generates:
decoration {
    col.active_border = #d8bafa    # Primary color
    col.inactive_border = #958e99  # Outline color
}
```

#### **Waybar** (Status Bars)
```bash
# Integration method: Dynamic CSS files
# Startup: waybar -s ~/.config/waybar/style-dynamic.css

# Two bars supported:
# - Top bar: style-dynamic.css (workspaces, system info)
# - Bottom bar: style-bottom-dynamic.css (GPU info, system stats)

# Reload method: SIGUSR2 signal + fallback restart
```

#### **Kitty** (Terminal)
```bash
# Integration method: Include directive
# Main config: include theme-dynamic.conf

# Template generates 16 terminal colors:
foreground #e8e0e8
background #151218
color0 #1d1a21  # black
color1 #ff5449  # red
color2 #4db380  # green
# ... etc

# Reload method: SIGUSR1 signal (live reload)
```

#### **Dunst** (Notifications)
```bash
# Integration method: Dynamic config file
# Startup: dunst -config ~/.config/dunst/dunstrc-dynamic

# Template generates:
[urgency_normal]
background = "#151218"
foreground = "#e8e0e8"
frame_color = "#d8bafa"

# Reload method: Process restart
```

#### **Fuzzel** (Application Launcher)
```bash
# Integration method: Direct config modification
# Limitation: No include support

# Template generates fuzzel-dynamic.ini:
[colors]
background=151218ff
text=e8e0e8ff
match=d8bafaff
selection=543b72ff

# Script copies [colors] section to main fuzzel.ini
# Reload method: Next launch (fuzzel doesn't run continuously)
```

### File Flow Diagram

```
User selects wallpaper
        ↓
assets/wallpapers/image.png
        ↓
swww img (sets wallpaper)
        ↓
matugen image → extracts colors
        ↓
config/matugen/templates/*.template
        ↓ (processing)
~/.config/app/generated-configs
        ↓
Applications reload → apply new colors
```

### Configuration Chain

#### **matugen config.toml**
```toml
[templates.waybar]
input_path = "~/.config/matugen/templates/waybar-style.css"
output_path = "~/.config/waybar/style-dynamic.css"
```

#### **Hyprland startup.conf**
```bash
exec-once = waybar -s ~/.config/waybar/style-dynamic.css
```

#### **Application configs**
```bash
# kitty.conf
include theme-dynamic.conf

# Hyprland main config
source = ~/.config/hypr/conf/colors.conf
```

### Error Handling & Resilience

#### **Graceful Degradation**
- If matugen fails → Keep existing theme
- If application restart fails → Log warning, continue
- If wallpaper not found → Show error notification

#### **Logging System**
```bash
# Main logs
/tmp/wallpaper-selector.log    # Selection UI activity
/tmp/wallpaper-theme.log       # Theme application details
/tmp/matugen.log               # Color generation output

# Application-specific logs
/tmp/waybar-main.log           # Top bar restart issues
/tmp/waybar-bottom.log         # Bottom bar restart issues
```

#### **Validation Checks**
```bash
# File existence
if [ ! -f "$wallpaper" ]; then
    log_message "Error: Wallpaper not found"
    return 1
fi

# Command availability
if ! command -v matugen > /dev/null; then
    log_message "Error: Matugen not found"
    return 1
fi

# Process verification
if pgrep -x waybar > /dev/null; then
    log_message "Waybar restarted successfully"
fi
```

## 📦 Installation

### Required Packages

```bash
# Core packages (add to install.sh)
sudo pacman -S swww matugen fuzzel

# Additional dependencies
cargo install matugen  # If not in repos
```

### File Structure

```
dotfiles/
├── assets/wallpapers/          # Your wallpaper collection
├── config/matugen/
│   ├── config.toml            # Matugen configuration
│   └── templates/             # Color templates for each app
│       ├── hyprland-colors.conf
│       ├── waybar-style.css
│       ├── waybar-style-bottom.css
│       ├── kitty.conf
│       ├── dunst.conf
│       └── fuzzel.ini
├── scripts/
│   ├── wallpaper-selector.sh  # Main wallpaper picker (Super+B)
│   └── wallpaper-theme-changer.sh  # Theme application logic
└── config/
    ├── hypr/conf/
    │   ├── keybinds.conf      # Super+B keybinding
    │   └── startup.conf       # swww auto-start
    ├── waybar/
    │   ├── style-dynamic.css  # Generated top bar theme
    │   └── style-bottom-dynamic.css  # Generated bottom bar theme
    ├── kitty/
    │   └── theme-dynamic.conf # Generated terminal colors
    ├── dunst/
    │   └── dunstrc-dynamic    # Generated notification theme
    └── fuzzel/
        └── fuzzel-dynamic.ini # Generated launcher theme
```

## ⚙️ Configuration

### Matugen Setup (`config/matugen/config.toml`)

```toml
[config]
reload_apps = true
set_wallpaper = false  # swww handles wallpaper setting
prefix = ""

[templates.hyprland]
input_path = "~/.config/matugen/templates/hyprland-colors.conf"
output_path = "~/.config/hypr/conf/colors.conf"

[templates.waybar]
input_path = "~/.config/matugen/templates/waybar-style.css"  
output_path = "~/.config/waybar/style-dynamic.css"

[templates.waybar-bottom]
input_path = "~/.config/matugen/templates/waybar-style-bottom.css"  
output_path = "~/.config/waybar/style-bottom-dynamic.css"

[templates.kitty]
input_path = "~/.config/matugen/templates/kitty.conf"
output_path = "~/.config/kitty/theme-dynamic.conf"

[templates.dunst]
input_path = "~/.config/matugen/templates/dunst.conf"
output_path = "~/.config/dunst/dunstrc-dynamic"

[templates.fuzzel]
input_path = "~/.config/matugen/templates/fuzzel.ini"
output_path = "~/.config/fuzzel/fuzzel-dynamic.ini"
```

### Hyprland Integration

**Keybinding** (`config/hypr/conf/keybinds.conf`):
```bash
bind = $mainMod, B, exec, ~/dotfiles/scripts/wallpaper-selector.sh
```

**Startup** (`config/hypr/conf/startup.conf`):
```bash
exec-once = waybar -s ~/.config/waybar/style-dynamic.css
exec-once = waybar -c ~/.config/waybar/config-bottom -s ~/.config/waybar/style-bottom-dynamic.css
exec-once = swww init && swww img ~/dotfiles/assets/wallpapers/evilpuccin.png
exec-once = dunst
```

### Application Config Updates

**Kitty** (`config/kitty/kitty.conf`):
```bash
# Dynamic color scheme (generated by matugen)
include theme-dynamic.conf
```

**Fuzzel** (`config/fuzzel/fuzzel.ini`):
```ini
[colors]
background=151218ff
text=e8e0e8ff
match=d8bafaff
selection=543b72ff
selection-text=eedbffff
selection-match=cfc1daff
border=958e99ff

# Note: Colors are updated automatically by theme script
```

## 🚀 Usage

### Basic Usage
- **Super+B**: Open wallpaper selector
- **Select wallpaper**: Choose from fuzzel menu
- **Automatic**: Theme applies instantly

### Advanced Usage
```bash
# Manual wallpaper change with theming
./scripts/wallpaper-selector.sh

# Apply theme to current wallpaper
./scripts/wallpaper-theme-changer.sh

# Apply theme to specific wallpaper
./scripts/wallpaper-theme-changer.sh /path/to/wallpaper.png

# Set wallpaper only (no theming)
swww img ~/dotfiles/assets/wallpapers/image.png
```

## 🎨 Color Variables

Templates use Material Design 3 color tokens:

### Primary Colors
- `{{colors.primary.dark.hex}}` - Main accent color
- `{{colors.primary.dark.rgba}}` - With transparency
- `{{colors.on_primary.dark.hex}}` - Text on primary

### Surface Colors  
- `{{colors.surface.dark.rgba}}` - Background surfaces
- `{{colors.surface_variant.dark.rgba}}` - Secondary surfaces
- `{{colors.on_surface.dark.hex}}` - Text on surfaces

### Semantic Colors
- `{{colors.error.dark.hex}}` - Error states
- `{{colors.tertiary.dark.hex}}` - Tertiary accent
- `{{colors.outline.dark.hex}}` - Borders and dividers

## 📝 Template Examples

### Waybar Module Styling
```css
#cpu {
    color: {{colors.primary.dark.hex}};
    background: {{colors.surface_variant.dark.rgba}};
    border-radius: 10px;
    min-width: 70px;
}

#cpu:hover {
    background: {{colors.primary_container.dark.rgba}};
    box-shadow: inset 0 0 0 1px {{colors.primary.dark.hex}};
}
```

### Hyprland Window Borders
```bash
decoration {
    col.active_border = {{colors.primary.dark.hex}}
    col.inactive_border = {{colors.outline.dark.hex}}
}
```

## 🔧 Scripts Overview

### `wallpaper-selector.sh`
- Main interface triggered by Super+B
- Shows fuzzel menu with wallpaper names
- Sets wallpaper with swww transitions
- Calls theme script automatically
- Provides user notifications

### `wallpaper-theme-changer.sh`
- Generates colors with matugen
- Restarts applications with new themes
- Handles both manual and automatic calls
- Comprehensive error handling and logging

## 📊 Supported Applications

| Application | Dynamic Component | Template | Integration Method |
|-------------|------------------|----------|-------------------|
| **Hyprland** | Window borders, workspace colors | `hyprland-colors.conf` | Include directive |
| **Waybar Top** | Status bar, modules, backgrounds | `waybar-style.css` | Dynamic CSS file |
| **Waybar Bottom** | GPU info bar, system stats | `waybar-style-bottom.css` | Dynamic CSS file |
| **Kitty** | Terminal colors, backgrounds | `kitty.conf` | Include directive |
| **Dunst** | Notification styling | `dunst.conf` | Dynamic config file |
| **Fuzzel** | Application launcher | `fuzzel.ini` | Direct config modification |

## 📁 Wallpaper Management

### Supported Formats
- PNG, JPG, JPEG, WEBP
- Any resolution (swww handles scaling)
- Stored in `~/dotfiles/assets/wallpapers/`

### Adding Wallpapers
```bash
# Copy new wallpapers
cp new-wallpaper.png ~/dotfiles/assets/wallpapers/

# They'll appear automatically in fuzzel menu
```

## 🐛 Troubleshooting

### Common Issues

**Fuzzel doesn't show wallpapers:**
```bash
ls ~/dotfiles/assets/wallpapers/  # Check wallpapers exist
echo $XDG_CURRENT_DESKTOP         # Should be "Hyprland"
```

**swww daemon not running:**
```bash
pkill swww-daemon
swww init
```

**Theme not applying:**
```bash
# Check logs
tail -f /tmp/wallpaper-selector.log
tail -f /tmp/wallpaper-theme.log

# Test matugen manually
matugen image ~/dotfiles/assets/wallpapers/test.png --mode dark
```

**Waybar not restarting:**
```bash
# Check if waybar is running
pgrep waybar

# Restart manually
pkill waybar
waybar -s ~/.config/waybar/style-dynamic.css &
waybar -c ~/.config/waybar/config-bottom -s ~/.config/waybar/style-bottom-dynamic.css &
```

**Fuzzel colors not updating:**
```bash
# Check if dynamic config exists
ls -la ~/.config/fuzzel/fuzzel-dynamic.ini

# Check if main config has [colors] section
grep -A 10 "\[colors\]" ~/.config/fuzzel/fuzzel.ini

# Manual fuzzel color update
./scripts/wallpaper-theme-changer.sh
```

**Kitty colors not updating:**
```bash
# Check if include directive exists
grep "include theme-dynamic.conf" ~/.config/kitty/kitty.conf

# Check if dynamic config exists
ls -la ~/.config/kitty/theme-dynamic.conf

# Send reload signal manually
pkill -USR1 kitty
```

### Log Files
- `/tmp/wallpaper-selector.log` - Main selector activity
- `/tmp/wallpaper-theme.log` - Theme application details
- `/tmp/matugen.log` - Color generation output

### Debug Commands
```bash
# Test wallpaper selection
./scripts/wallpaper-selector.sh

# Test theme application
./scripts/wallpaper-theme-changer.sh ~/dotfiles/assets/wallpapers/test.png

# Check current wallpaper
swww query

# Verify dynamic CSS generation
ls -la ~/.config/waybar/style-dynamic.css
head -20 ~/.config/waybar/style-dynamic.css

# Test matugen directly
matugen image ~/dotfiles/assets/wallpapers/test.png --mode dark --verbose
```

## 🎯 Performance

- **Color extraction**: ~1-2 seconds per wallpaper
- **Application restart**: ~2-3 seconds total
- **Memory usage**: Minimal overhead
- **Transitions**: Smooth 2-second wipe effect

## 🔮 Future Enhancements Roadmap

### Phase 1: User Experience Improvements (High Priority)

#### 1.1 Preview Mode 🎨
**Goal**: Show color preview before applying theme
**Complexity**: Medium
**Estimated Time**: 2-3 days

**Features**:
- Live color palette preview in fuzzel/rofi
- Mini-screenshots of themed applications
- "Apply" vs "Cancel" options
- Color hex codes display

**Implementation Plan**:
```bash
# New script: wallpaper-preview.sh
1. Generate colors with matugen (no file output)
2. Create preview interface:
   - Show extracted color palette
   - Display color names and hex codes
   - Show before/after mockups
3. Use rofi with custom theme for richer preview
4. Add preview mode flag to wallpaper-selector.sh
```

**Technical Requirements**:
- Rofi with custom CSS (richer than fuzzel)
- ImageMagick for color palette visualization
- Temporary preview generation without overwriting configs

**Dependencies**: None

---

#### 1.2 Wallpaper Categories 📂
**Goal**: Organize wallpapers by mood, time, season, color scheme
**Complexity**: Medium
**Estimated Time**: 2-3 days

**Features**:
- Folder-based organization in fuzzel menu
- Tag-based filtering system
- Quick category switching
- Auto-categorization by dominant colors

**Implementation Plan**:
```bash
# Directory structure:
assets/wallpapers/
├── nature/
├── abstract/
├── minimal/
├── dark/
├── light/
├── seasonal/
│   ├── spring/
│   ├── summer/
│   ├── autumn/
│   └── winter/
└── time/
    ├── morning/
    ├── day/
    ├── evening/
    └── night/

# Enhanced wallpaper-selector.sh:
1. Show category menu first
2. Then show wallpapers from selected category
3. Add "All Wallpapers" option
4. Remember last category used
```

**Technical Requirements**:
- Multi-level fuzzel navigation
- Category configuration file
- Auto-detection based on folder structure

**Dependencies**: None

---

#### 1.3 Enhanced Transition Effects ✨
**Goal**: More swww transition options and customization
**Complexity**: Low
**Estimated Time**: 1 day

**Features**:
- Multiple transition types (fade, slide, zoom, pixelate, etc.)
- Transition duration customization
- Direction options for directional transitions
- Random transition mode

**Implementation Plan**:
```bash
# Add to wallpaper-selector.sh:
1. Configuration file for transition preferences
2. Random transition picker
3. Transition preview in selection menu
4. User-configurable transition settings

# Config: ~/.config/dynamic-theming/transitions.conf
transition_type=random  # or specific: wipe, fade, slide, etc.
transition_duration=2
transition_direction=random  # left, right, up, down
```

**Technical Requirements**:
- swww transition options research
- Configuration management
- Transition effect showcase

**Dependencies**: None

---

### Phase 2: Automation & Intelligence (Medium Priority)

#### 2.1 Auto-Theming System 🤖
**Goal**: Time-based and automatic wallpaper rotation
**Complexity**: High
**Estimated Time**: 4-5 days

**Features**:
- Time-based wallpaper changes (morning/afternoon/evening/night)
- Seasonal rotation (different sets per season)
- Weather-based theming (sunny/cloudy/rainy wallpapers)
- Activity-based theming (work/gaming/relaxation themes)

**Implementation Plan**:
```bash
# New service: auto-theming-daemon.sh
1. Systemd service for background operation
2. Configuration with time slots and wallpaper sets:

# Config: ~/.config/dynamic-theming/auto-theme.conf
[time_based]
enabled=true
morning_start=06:00
afternoon_start=12:00
evening_start=18:00
night_start=22:00

[seasonal]
enabled=true
check_interval=daily

[weather]
enabled=false
api_key=""
location=""

[activity]
enabled=false
work_hours=09:00-17:00
```

**Technical Requirements**:
- Systemd service configuration
- Weather API integration (optional)
- Activity detection (active window monitoring)
- Cron-like scheduling system

**Dependencies**: None

---

#### 2.2 Theme Presets System 💾
**Goal**: Save, restore, and manage favorite theme combinations
**Complexity**: Medium-High
**Estimated Time**: 3-4 days

**Features**:
- Save current theme as named preset
- Quick preset switching
- Preset sharing (export/import)
- Preset thumbnails and previews
- Preset management interface

**Implementation Plan**:
```bash
# New structure:
~/.config/dynamic-theming/presets/
├── preset-name/
│   ├── wallpaper.png
│   ├── colors.json
│   ├── generated-configs/
│   └── thumbnail.png

# New scripts:
1. save-theme-preset.sh - Save current theme
2. load-theme-preset.sh - Load saved theme
3. manage-presets.sh - List, delete, export presets
4. Enhanced wallpaper-selector.sh with preset mode

# Preset selection interface:
- Show preset thumbnails in fuzzel/rofi
- Quick apply without regeneration
- Backup current theme before applying preset
```

**Technical Requirements**:
- JSON for preset metadata
- Thumbnail generation
- Config backup/restore system
- Preset validation

**Dependencies**: None

---

### Phase 3: System-Wide Integration (Lower Priority)

#### 3.1 Dynamic GTK Theming 🎭
**Goal**: Generate GTK3/GTK4 themes from wallpaper colors
**Complexity**: Very High
**Estimated Time**: 1-2 weeks

**Features**:
- Custom GTK3/GTK4 theme generation
- Application-specific overrides
- Theme inheritance system
- Integration with existing GTK themes

**Implementation Plan**:
```bash
# New components:
1. GTK theme template system
2. Theme compilation and installation
3. Application restart handling

# Template structure:
config/matugen/templates/gtk/
├── gtk-3.0/
│   ├── gtk.css.template
│   └── gtk-dark.css.template
├── gtk-4.0/
│   ├── gtk.css.template
│   └── gtk-dark.css.template
└── index.theme.template

# Generated themes location:
~/.themes/DynamicTheme-{timestamp}/
├── gtk-3.0/
├── gtk-4.0/
└── index.theme
```

**Technical Requirements**:
- Deep GTK theming knowledge
- CSS template system for GTK
- Theme switching mechanism
- Application restart coordination

**Dependencies**: GTK development libraries, theme research

---

#### 3.2 Dynamic Qt Theming 🖼️
**Goal**: Generate Qt5ct/Qt6ct color schemes
**Complexity**: High
**Estimated Time**: 1 week

**Features**:
- Qt5ct color scheme generation
- Qt6ct color scheme generation
- Icon theme coordination
- Qt application integration

**Implementation Plan**:
```bash
# Template locations:
config/matugen/templates/qt/
├── qt5ct-colors.conf.template
└── qt6ct-colors.conf.template

# Generated configs:
~/.config/qt5ct/colors/DynamicTheme.conf
~/.config/qt6ct/colors/DynamicTheme.conf

# Auto-apply mechanism:
1. Generate color schemes
2. Update qt5ct/qt6ct main config to use new scheme
3. Apply changes via environment variables
```

**Technical Requirements**:
- Qt theming system understanding
- Color scheme format research
- Qt application restart handling

**Dependencies**: qt5ct, qt6ct packages

---

#### 3.3 Browser Integration 🌐
**Goal**: Theme web browsers to match system colors
**Complexity**: Very High
**Estimated Time**: 2-3 weeks

**Features**:
- Firefox CSS theme generation
- Chrome/Chromium extension integration
- Custom CSS injection
- Website-specific color overrides

**Implementation Plan**:
```bash
# Firefox userChrome.css generation
~/.mozilla/firefox/profile/chrome/userChrome.css

# Chrome extension for theme application
scripts/browser-extension/
├── manifest.json
├── background.js
├── content.js
└── theme-injector.css

# Dynamic CSS generation for browser chrome
config/matugen/templates/browsers/
├── firefox-userchrome.css.template
└── chrome-theme.css.template
```

**Technical Requirements**:
- Browser extension development
- CSS injection techniques
- Browser profile management
- Security considerations

**Dependencies**: Browser development tools

---

### Phase 4: Advanced Features (Future Consideration)

#### 4.1 AI-Powered Color Harmony 🧠
**Goal**: Use AI to optimize color combinations
**Complexity**: Very High
**Estimated Time**: 3-4 weeks

**Features**:
- Machine learning color optimization
- Accessibility score optimization
- Mood-based color adjustment
- Learning from user preferences

**Implementation Plan**:
- Research color harmony algorithms
- Implement accessibility scoring
- Add user feedback system
- Create preference learning model

---

#### 4.2 Cross-Desktop Support 🖥️
**Goal**: Support for GNOME, KDE, XFCE
**Complexity**: Very High
**Estimated Time**: 4-6 weeks

**Features**:
- Desktop environment detection
- DE-specific theming backends
- Universal color application
- Cross-desktop testing suite

**Implementation Plan**:
- Research each DE's theming system
- Create abstraction layer
- Implement DE-specific handlers
- Extensive testing infrastructure

---

#### 4.3 Mobile Integration 📱
**Goal**: Sync themes with mobile devices
**Complexity**: Extreme
**Estimated Time**: 2-3 months

**Features**:
- Android theme sync
- iOS wallpaper coordination
- Cloud theme storage
- Multi-device consistency

**Implementation Plan**:
- Mobile app development
- Cloud sync infrastructure
- Cross-platform color standards
- Security and privacy implementation

---

## 🗓️ Development Timeline

### Immediate Next Steps (This Week)
1. **Preview Mode** - Start with basic color palette display
2. **Wallpaper Categories** - Implement folder structure navigation

### Short Term (Next Month)
1. Complete Phase 1 features
2. Begin Auto-Theming system
3. Start Theme Presets implementation

### Medium Term (Next 3 Months)
1. Complete Phase 2 automation features
2. Begin GTK theming research and implementation
3. Start Qt theming development

### Long Term (6+ Months)
1. Advanced system-wide integration
2. AI and cross-desktop features
3. Mobile integration research

---

## 🎯 Priority Matrix

**High Impact, Low Effort**:
- Enhanced Transition Effects
- Wallpaper Categories

**High Impact, High Effort**:
- Preview Mode
- Auto-Theming System
- GTK/Qt Integration

**Medium Impact, Low Effort**:
- Theme Presets (basic version)

**Medium Impact, High Effort**:
- Browser Integration
- Cross-Desktop Support

**Future Research**:
- AI-Powered Features
- Mobile Integration

---

**Ready to build the future of dynamic theming! 🚀** 