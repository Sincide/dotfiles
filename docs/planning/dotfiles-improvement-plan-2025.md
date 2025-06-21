# 🌌 Evil Space Dotfiles - Plan D: Quick Wins Mix

*Fast improvements that make immediate impact - 3-5 days timeline*

---

## 🎯 **Current Status: Already Excellent!**

Your dotfiles are highly sophisticated with:
- ✅ **Complete dynamic theming system** (13 matugen templates)
- ✅ **Advanced dual-bar monitoring** (CPU, GPU, memory, network, thermal)  
- ✅ **Automated setup scripts** (10 comprehensive setup scripts)
- ✅ **Production-ready desktop** (Hyprland + Waybar + theming)
- ✅ **Local LLM infrastructure** (Ollama + multiple models ready)

## 🚀 **Plan D: 5 Quick Wins** 

### **1. 🖼️ Wallpaper Previews in Fuzzel** 
**Priority: HIGH** | **Estimated: 1 day**

**Problem:** Currently fuzzel shows only wallpaper names, no visual preview
**Solution:** Generate thumbnails and create image-preview wallpaper selector

**Implementation:**
- Create thumbnail generation script for wallpaper directories
- Build custom image-preview selector using fuzzel or rofi
- Integrate with existing wallpaper manager script
- Add keybind for quick wallpaper selection with previews

**Files to modify:**
- `scripts/theming/wallpaper_manager.sh` - add thumbnail generation
- `hypr/conf/keybinds.conf` - add preview selector keybind

---

### **2. 🤖 Simple AI Terminal Helper**
**Priority: HIGH** | **Estimated: 1 day**

**Problem:** Local LLMs are available but not integrated into daily workflow
**Solution:** Add `ai` command for quick terminal assistance

**Implementation:**
- Create `ai` fish function that sends queries to local Ollama
- Support common use cases: `ai "find large files"`, `ai "fix permission error"`
- Add to fish functions with proper error handling
- Simple, fast, no complex integrations

**Files to create:**
- `fish/functions/ai.fish` - main AI helper function
- Test with existing Ollama setup

---

### **3. 🎵 Now-Playing in Waybar**
**Priority: MEDIUM** | **Estimated: 0.5 days**

**Problem:** No media information visible in the desktop
**Solution:** Add current music/media display to Waybar

**Implementation:**
- Add playerctl-based media module to Waybar
- Show artist, title, play/pause controls
- Integrate with existing Waybar styling
- Support Spotify, YouTube, local media

**Files to modify:**
- `waybar/config` or `waybar/config-bottom` - add media module
- `waybar/colors.css` - style media controls

---

### **4. ⚡ Better Keybinds**
**Priority: MEDIUM** | **Estimated: 0.5 days**

**Problem:** Basic keybinds could be more productive
**Solution:** Add context-aware and workflow-optimized shortcuts

**Implementation:**
- Add screenshot region selector
- Quick theme switching shortcuts
- Window management improvements (quarters, halves)
- Quick app launchers for common tools
- Media control improvements

**Files to modify:**
- `hypr/conf/keybinds.conf` - enhanced keybind set

---

### **5. 📱 Notification Improvements**
**Priority: LOW** | **Estimated: 1 day**

**Problem:** Notifications could be more interactive and better styled
**Solution:** Enhanced Dunst configuration with actions and styling

**Implementation:**
- Add notification actions (reply, archive, etc.)
- Improve notification styling to match theme better
- Add notification history/log
- Better urgency-based styling

**Files to modify:**
- `dunst/dunstrc` - enhanced notification config
- `matugen/templates/dunst.template` - better theming integration

---

## 📅 **Implementation Order**

### **Day 1: Wallpaper Previews** 🖼️
- Generate thumbnail system
- Build preview selector
- Test with existing wallpaper collection

### **Day 2: AI Terminal Helper** 🤖  
- Create ai fish function
- Test with common queries
- Document usage patterns

### **Day 3: Media + Keybinds** 🎵⚡
- Add now-playing to Waybar
- Enhance keybind configuration
- Test all new shortcuts

### **Day 4: Notifications** 📱
- Improve Dunst styling
- Add notification actions
- Test urgency levels

### **Day 5: Polish & Testing** ✨
- Fix any issues
- Update documentation
- Test full workflow

---

## 🎯 **Success Criteria**

**Week 1 Complete When:**
- ✅ Wallpaper selector shows thumbnails + names
- ✅ `ai "command help"` works in terminal
- ✅ Now-playing shows in Waybar with controls
- ✅ Enhanced keybinds improve daily workflow
- ✅ Notifications are more interactive and better styled

**Result:** Same excellent dotfiles + 5 immediate quality-of-life improvements that you'll use daily.

---

## 🚫 **Explicitly NOT Included**

**These are interesting but not part of this quick wins plan:**
- ❌ Complex AI integrations (save for later)
- ❌ Major UI overhauls (current system works great)
- ❌ New desktop environments (QuickShell/AGS are experimental)
- ❌ Advanced automation (current theming system is already excellent)

**Focus:** Fast, practical improvements to an already great system.