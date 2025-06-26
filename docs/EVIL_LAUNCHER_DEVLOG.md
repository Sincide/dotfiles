# 👹 Evil Launcher Development Log

## Project Overview
Minimalist, self-contained TUI application launcher and wallpaper selector for Hyprland, written in Go. Features application launching with Tab-switchable PATH executables and wallpaper selection with chafa previews.

## ✅ Current Implementation

### Core Infrastructure
- [x] **Pure Go implementation** - No external TUI frameworks (Bubble Tea removed)
- [x] **Minimalist design** - Direct terminal manipulation with ANSI escape codes
- [x] **Self-contained binary** - Single executable with minimal dependencies
- [x] **Fast startup** - Raw terminal performance without framework overhead

### Application Launcher (`./launcher launch`)
- [x] **Desktop file discovery** - Scans `/usr/share/applications` and `~/.local/share/applications`
- [x] **Real-time filtering** - Type to filter applications instantly
- [x] **Tab switching** - Switch between desktop apps and PATH executables with Tab key
- [x] **Process isolation** - Apps launched with proper process group separation
- [x] **Clean execution** - Proper terminal cleanup on exit

### Wallpaper Selector (`./launcher wall`)
- [x] **Chafa integration** - Live image previews using chafa when available and terminal width > 60
- [x] **Category detection** - Automatic theme category detection (space, nature, gaming, etc.)
- [x] **Random wallpaper** - Built-in random selection option
- [x] **Split-view interface** - List + preview when terminal is wide enough
- [x] **swww integration** - Direct wallpaper setting with swww
- [x] **Dynamic theming** - Calls dynamic_theme_switcher.sh with category detection
- [x] **Matugen integration** - Automatic Material You color generation
- [x] **Application restart** - Intelligent waybar/dunst restart with process detachment

## 🎯 Technical Achievements

### Performance
- **Fast startup**: ~100ms launch time
- **Minimal footprint**: Efficient memory usage
- **Non-blocking operations**: Wallpaper/theme setting runs in background

### Integration
- **Matugen Compatible**: Seamlessly triggers theme generation
- **Fish Shell Native**: Build scripts and integration use Fish
- **Hyprland Ready**: Window rules and keybind examples provided

### User Experience
- **Intuitive Controls**: Standard TUI navigation
- **Visual Feedback**: Styled with current color scheme
- [x] Multiple Modes: Apps, wallpapers, themes in one binary

## 🔧 Technical Stack

```
├── Go 1.16+ (pure standard library)
├── ANSI escape codes for terminal control
├── Raw terminal input/output handling
├── External dependencies:
│   ├── swww (wallpaper setting)
│   ├── chafa (image previews)
│   ├── stty (terminal mode control)
│   ├── matugen (color generation)
│   └── dynamic_theme_switcher.sh (theme management)
```

## 📋 Usage Examples

```bash
# Application launcher with Tab-switchable PATH executables
./launcher launch

# Wallpaper selector with chafa previews
./launcher wall

# Build the launcher
go build -o launcher .
```

### Keybind Integration
```conf
# Hyprland keybinds
bind = $mainMod, D, exec, kitty --class=evil-launcher -e sh -c "cd ~/dotfiles/app-dev/evil-launcher && EVIL_LAUNCHER_KEYBIND_MODE=true ./launcher launch"
bind = $mainMod, W, exec, kitty --class=evil-launcher -e sh -c "cd ~/dotfiles/app-dev/evil-launcher && EVIL_LAUNCHER_KEYBIND_MODE=true ./launcher wall"
```

## 🎨 Integration with Existing Setup

### Hyprland Configuration
```conf
# Window rules for floating launcher
windowrule = float, initialClass:^(evil-launcher)$
windowrulev2 = center, initialClass:^(evil-launcher)$
windowrulev2 = size 50% 40%, initialClass:^(evil-launcher)$

# Working keybinds
bind = $mainMod, D, exec, kitty --class=evil-launcher -e sh -c "cd ~/dotfiles/app-dev/evil-launcher && EVIL_LAUNCHER_KEYBIND_MODE=true ./launcher launch"
bind = $mainMod, W, exec, kitty --class=evil-launcher -e sh -c "cd ~/dotfiles/app-dev/evil-launcher && EVIL_LAUNCHER_KEYBIND_MODE=true ./launcher wall"
```

### Theme Integration Pipeline
1. **Wallpaper Selection** → swww sets wallpaper
2. **Category Detection** → Automatic detection (space, nature, gaming, etc.)
3. **Dynamic Theme Switching** → Calls `dynamic_theme_switcher.sh apply <wallpaper>`
4. **Color Generation** → Matugen generates Material You colors
5. **Application Restart** → Detached waybar/dunst restart with debug logging

## 🎯 Project Goals Achieved

✅ **Fast Alternative to Rofi/Wofi**: Raw terminal performance beats framework-based launchers  
✅ **Wallpaper Preview**: Live chafa image previews in terminal  
✅ **Matugen Integration**: Complete wallpaper → color → theme pipeline  
✅ **Dual-Mode Operation**: Application launcher + wallpaper selector  
✅ **Hyprland Integration**: Floating windows, keybinds, process isolation  
✅ **Tab Switching**: Desktop apps ↔ PATH executables in launch mode  
✅ **Process Management**: Proper detachment prevents waybar crashes  
✅ **Debug Logging**: Comprehensive troubleshooting system

## 💡 Key Learnings

1. **Raw Terminal > Frameworks**: Direct ANSI escape codes offer better performance than TUI frameworks
2. **Process Isolation Critical**: `nohup`, `disown`, and `Setpgid` essential for preventing crashes
3. **Environment Differences**: Keybind vs terminal execution requires different handling
4. **Chafa Integration**: Live image previews make wallpaper selection much more intuitive
5. **Debug Logging Essential**: Troubleshooting complex integrations requires detailed logging
6. **Go Standard Library**: Powerful enough for sophisticated TUI applications without external deps

## 🎉 Phase 1 Complete - Hyprland Integration Success

### Recent Achievements (December 2024)
- [x] **Hyprland Window Rules**: Fixed floating window configuration
- [x] **Keybind Integration**: Working Super+D (launch) and Super+W (wallpaper) keybinds
- [x] **Waybar Restart Fix**: Solved process dependency crash issue with detached processes
- [x] **Debug Logging**: Comprehensive debugging system for troubleshooting
- [x] **Environment Compatibility**: Works properly from both terminal and keybinds
- [x] **Theme Integration**: Full wallpaper → matugen → theme restart pipeline working

### Technical Solutions Implemented
- **Process Detachment**: Using `nohup`, `disown`, and `Setpgid` to prevent waybar crashes
- **Window Classification**: `--class=evil-launcher` for proper Hyprland window rules
- **Environment Variables**: `EVIL_LAUNCHER_KEYBIND_MODE` for behavior differentiation
- **Debug Logging**: Real-time logging to `~/dotfiles/logs/waybar-debug.log`

## 🎯 Next Development Phase - UX Improvements

### Immediate Priorities
- [ ] **Unified Interface**: Remove tab switching - combine launch and run modes into single view
- [ ] **Window Sizing**: Reduce default window size for better desktop integration
- [ ] **Smart Sorting**: Recently launched applications appear at top for quick access
- [ ] **Usage Analytics**: Track launch frequency and last-used timestamps

### Planned UX Enhancements
- [ ] **Recent Apps Priority**: Most frequently used apps float to top
- [ ] **Launch History**: Persistent storage of application usage patterns
- [ ] **Compact Mode**: Smaller, more focused launcher interface
- [ ] **Quick Access**: Single-key launching for top applications

## 📊 Current Status

**Status**: ✅ **PRODUCTION READY**  
**Build**: ✅ **SUCCESSFUL**  
**Hyprland Integration**: ✅ **COMPLETE**  
**Waybar Compatibility**: ✅ **FIXED**  
**Documentation**: ✅ **COMPLETE**

---

**Current Focus**: UX improvements for daily usage efficiency

**Project Location**: `app-dev/evil-launcher/`  
**Build Command**: `go build -o launcher .`  
**Last Updated**: December 26, 2024 