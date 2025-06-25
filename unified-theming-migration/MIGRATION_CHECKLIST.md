# Sincide Dotfiles → Unified Dynamic Theming Migration Checklist
## Progress Tracking and Validation Document

---

## Pre-Migration Setup

### Security and Backup
- [ ] **CRITICAL:** Create Git branch `linkfrg-migration` 
- [ ] **CRITICAL:** Backup current dotfiles state
- [ ] **CRITICAL:** Test rollback procedure
- [ ] Document current working configuration
- [ ] Create emergency restoration script

### Research Phase
- [ ] Clone linkfrg/dotfiles repository locally
- [ ] Analyze linkfrg's Material theme structure
- [ ] Document linkfrg's MaterialService implementation  
- [ ] Study their GTK refresh mechanisms
- [ ] Map current Sincide theme integration points

---

## Phase 1: Critical Security Fixes (Week 1)

### 1.1 Screen Lock Security Fix
**Priority: CRITICAL - Security Vulnerability**

- [ ] Install swaylock: `sudo pacman -S swaylock`
- [ ] Configure swaylock: `~/.config/swaylock/config`
- [ ] Update Hyprland keybind in `hypr/conf/keybinds.conf`:
  ```bash
  # Change from: bind = $mainMod, L, exec, hyprctl dispatch dpms off  
  # To: bind = $mainMod, L, exec, swaylock && hyprctl dispatch dpms off
  ```
- [ ] Test lock screen functionality
- [ ] Verify DPMS still works after unlock
- [ ] Document security enhancement
- [ ] **VALIDATION:** Confirm screen actually locks and requires password

### 1.2 GPU Monitoring Script Hardening
- [ ] Create dynamic GPU detection function in `scripts/theming/gpu_detection.sh`
- [ ] Update all GPU scripts to use dynamic detection:
  - [ ] `scripts/theming/gpu_temp.sh`
  - [ ] `scripts/theming/gpu_usage.sh` 
  - [ ] `scripts/theming/gpu_fan.sh`
  - [ ] `scripts/theming/gpu_vram.sh`
- [ ] Add AMD vendor ID verification (0x1002)
- [ ] Implement fallback from card1 to card0
- [ ] Add error handling for missing GPU paths
- [ ] **VALIDATION:** Test on systems with different GPU configurations

### 1.3 Fish Shell Conflict Resolution
- [ ] Audit all Git aliases and abbreviations in `fish/config.fish`
- [ ] Remove duplicate definitions (keep abbreviations, remove aliases)
- [ ] Fix fish color variable: change `set -u` to `set -U` for `fish_color_option`
- [ ] Remove duplicate `fish_greeting=""` line
- [ ] Test all Git workflow shortcuts work correctly
- [ ] **VALIDATION:** Confirm no alias/abbreviation conflicts remain

---

## Phase 2: Foundation and Theme Development (Weeks 2-4)

### 2.1 Unified Theme Creation
- [ ] Decide on base theme (EvilSpace-Dynamic vs linkfrg Material)
- [ ] Create `themes/EvilSpace-Dynamic-Unified/` directory structure:
  - [ ] `gtk-3.0/gtk.css`
  - [ ] `gtk-4.0/gtk.css` 
  - [ ] `index.theme`
- [ ] Ensure all widget styles use dynamic color variables
- [ ] Implement complete Material You color variable set
- [ ] Test theme with various GTK3 applications
- [ ] Test theme with various GTK4 applications
- [ ] **VALIDATION:** Theme renders correctly across app types

### 2.2 Enhanced Matugen Template System
- [ ] Update `matugen/templates/gtk-unified.template` with all color variables
- [ ] Update `matugen/templates/waybar.template` for unified colors
- [ ] Update `matugen/templates/kitty.template`
- [ ] Update `matugen/templates/dunst.template`
- [ ] Update `matugen/templates/starship.template`
- [ ] Add light/dark mode support in templates
- [ ] Create fallback color definitions
- [ ] **VALIDATION:** All templates generate valid configuration files

### 2.3 Category System Preservation
- [ ] Create enhanced `scripts/theming/dynamic-themes.conf` with:
  - [ ] Per-category light/dark variants
  - [ ] Icon theme mappings preserved
  - [ ] Cursor theme mappings preserved  
  - [ ] Palette bias options (vibrant, muted, natural)
- [ ] Update category detection logic in theme controller
- [ ] Implement dynamic icon cache updates
- [ ] **VALIDATION:** All existing category behaviors preserved

---

## Phase 3: Central Theme Controller (Weeks 3-4)

### 3.1 Core Theme Controller Script
- [ ] Create `scripts/theming/theme_controller.sh` with:
  - [ ] Wallpaper detection and categorization
  - [ ] Enhanced palette generation (Matugen + category logic)
  - [ ] Template rendering coordination
  - [ ] Icon and cursor theme management
  - [ ] Application refresh coordination
  - [ ] Comprehensive error handling
  - [ ] Detailed logging to `~/.cache/dotfiles-theme.log`
- [ ] Implement dry-run mode for testing
- [ ] Add user override configuration support
- [ ] **VALIDATION:** Controller handles all theme switching scenarios

### 3.2 Enhanced GTK Refresh Mechanism
- [ ] Implement linkfrg-inspired multi-toggle sequence:
  - [ ] Theme toggle: Adwaita → Unified → Unified
  - [ ] Color-scheme cycling: default → prefer-dark → original
- [ ] Add proper timing delays between toggles
- [ ] Implement application-specific refresh logic
- [ ] Add race condition prevention
- [ ] **VALIDATION:** GTK apps consistently pick up theme changes

---

## Phase 4: Application Integration (Weeks 5-6)

### 4.1 GTK4/Libadwaita Compatibility
- [ ] Research and implement accent color injection methods
- [ ] Test custom CSS injection for libadwaita apps
- [ ] Implement proper light/dark switching per category
- [ ] Add Gradience integration investigation
- [ ] Test portal integration for sandboxed apps
- [ ] Document libadwaita limitations and workarounds
- [ ] **VALIDATION:** GTK4 apps respect theming as much as possible

### 4.2 Comprehensive Application Coverage
- [ ] **Waybar:** Implement dynamic reload with new colors
  - [ ] Test top bar theme application
  - [ ] Test bottom bar theme application  
  - [ ] Verify smooth restart without glitches
- [ ] **Kitty:** Implement signal-based theme refresh
  - [ ] Test USR1 signal reload
  - [ ] Verify terminal colors update correctly
- [ ] **Dunst:** Implement configuration reload
  - [ ] Test notification color updates
  - [ ] Verify restart doesn't lose notifications
- [ ] **Fuzzel:** Test color injection and restart
- [ ] **Starship:** Test prompt color updates
- [ ] **Fish:** Test shell color refresh
- [ ] **Hyprland:** Test border color updates and cursor changes
- [ ] **VALIDATION:** All applications reflect new theme correctly

---

## Phase 5: Enhanced Features (Weeks 7-8)

### 5.1 User Experience Enhancements
- [ ] Implement rich desktop notifications with theme details
- [ ] Add color palette preview in notifications
- [ ] Create error/warning notification system
- [ ] Add progress indicators for slow operations
- [ ] Implement theme preview mode
- [ ] **VALIDATION:** User feedback is clear and helpful

### 5.2 Performance and Reliability
- [ ] Implement theme change debouncing
- [ ] Add caching for repeated operations
- [ ] Monitor resource usage during theme switches
- [ ] Add automatic recovery mechanisms
- [ ] Implement comprehensive error detection
- [ ] **VALIDATION:** Theme switching is fast and reliable

### 5.3 Configuration Tools
- [ ] Create theme override configuration utility
- [ ] Implement category mapping editor
- [ ] Add color palette adjustment tools
- [ ] Create theme testing and validation utilities
- [ ] **VALIDATION:** Configuration tools work correctly

---

## Phase 6: Testing and Validation (Weeks 9-10)

### 6.1 Comprehensive Testing
- [ ] **Category Testing:** Test all wallpaper categories:
  - [ ] Space wallpapers → correct theme, icons, cursors
  - [ ] Nature wallpapers → correct theme, icons, cursors
  - [ ] Gaming wallpapers → correct theme, icons, cursors
  - [ ] Minimal wallpapers → light theme, correct icons, cursors
  - [ ] Dark wallpapers → correct theme, icons, cursors
  - [ ] Abstract wallpapers → correct theme, icons, cursors

- [ ] **Application Testing:** Test theme application across:
  - [ ] GTK3 applications (Thunar, Nemo, etc.)
  - [ ] GTK4 applications (GNOME apps)
  - [ ] Waybar (top and bottom bars)
  - [ ] Kitty terminal
  - [ ] Dunst notifications
  - [ ] Fuzzel launcher  
  - [ ] Firefox/browser cursor themes
  - [ ] Qt applications (if any)

- [ ] **Performance Testing:**
  - [ ] Theme switching speed
  - [ ] Resource usage during switch
  - [ ] Memory usage of theme system
  - [ ] No race conditions or glitches

- [ ] **Error Condition Testing:**
  - [ ] Missing wallpaper files
  - [ ] Corrupted palette generation
  - [ ] Missing theme files
  - [ ] Application restart failures
  - [ ] Fallback mechanism testing

### 6.2 Security and Stability Validation
- [ ] **Security Audit:**
  - [ ] Screen lock works properly
  - [ ] No privilege escalation issues
  - [ ] File permissions are correct
  - [ ] No sensitive data exposure

- [ ] **Stability Testing:**
  - [ ] Rapid wallpaper changes don't break system
  - [ ] System survives logout/login cycles
  - [ ] Theme persists across reboots
  - [ ] No memory leaks in theme system

---

## Phase 7: Documentation and Deployment (Weeks 11-12)

### 7.1 Documentation Updates
- [ ] Update main README with new theming system
- [ ] Create comprehensive migration guide
- [ ] Document configuration customization options
- [ ] Create troubleshooting guide
- [ ] Document known limitations and workarounds
- [ ] Update DYNAMIC_THEMES.md with new architecture
- [ ] **VALIDATION:** Documentation is complete and accurate

### 7.2 Deployment Preparation
- [ ] Create safe deployment script with backup/rollback
- [ ] Implement comprehensive validation checks
- [ ] Test deployment on clean system
- [ ] Create emergency rollback procedures
- [ ] Prepare monitoring and logging systems
- [ ] **VALIDATION:** Deployment process is safe and reliable

---

## Phase 8: Final Deployment and Cleanup (Week 12)

### 8.1 Production Deployment
- [ ] Run final comprehensive backup
- [ ] Execute deployment script
- [ ] Monitor system for issues
- [ ] Validate all functionality works
- [ ] Test rollback procedure
- [ ] **VALIDATION:** System works perfectly in production

### 8.2 Legacy Cleanup  
- [ ] Remove old theme files (after confirmation)
- [ ] Remove unused scripts
- [ ] Clean up old templates
- [ ] Update symlinks
- [ ] Remove temporary files
- [ ] **VALIDATION:** No legacy components remain

### 8.3 Post-Deployment Monitoring
- [ ] Monitor performance for first week
- [ ] Collect user feedback
- [ ] Address any deployment issues
- [ ] Document lessons learned
- [ ] **VALIDATION:** System is stable and performant

---

## Success Validation Criteria

### Technical Success
- [ ] All existing functionality preserved
- [ ] No regressions in theme application  
- [ ] Improved GTK4 compatibility (where possible)
- [ ] Enhanced performance and reliability
- [ ] Comprehensive error handling and logging

### User Experience Success
- [ ] Seamless theme switching experience
- [ ] Clear feedback and error handling
- [ ] Comprehensive customization options
- [ ] Robust documentation and support
- [ ] Easy rollback if needed

### Security Success
- [ ] All security vulnerabilities addressed
- [ ] Screen lock works properly
- [ ] No new security issues introduced
- [ ] Proper file permissions maintained

---

## Emergency Rollback Procedure

If critical issues arise during migration:

1. **Immediate Actions:**
   - [ ] Stop theme controller service
   - [ ] Switch to Adwaita theme manually
   - [ ] Restore backup configurations

2. **System Restoration:**
   - [ ] Run rollback script
   - [ ] Verify all applications work
   - [ ] Restart affected services
   - [ ] Document issues encountered

3. **Issue Analysis:**
   - [ ] Analyze logs for failure cause
   - [ ] Test fixes in isolated environment
   - [ ] Plan remediation strategy
   - [ ] Schedule retry with fixes

---

## Notes and Issues

**Migration Start Date:** _______________

**Issues Encountered:**
- Issue 1: ________________________________
- Issue 2: ________________________________  
- Issue 3: ________________________________

**Additional Testing Needed:**
- Test 1: _________________________________
- Test 2: _________________________________
- Test 3: _________________________________

**Performance Notes:**
- Theme switch time: _______ seconds
- Memory usage: _______ MB
- CPU usage during switch: _______ %

---

## Completion Status

- [ ] **Phase 1 Complete:** Critical security fixes applied
- [ ] **Phase 2 Complete:** Foundation and theme development done
- [ ] **Phase 3 Complete:** Central theme controller implemented
- [ ] **Phase 4 Complete:** Application integration finished
- [ ] **Phase 5 Complete:** Enhanced features added
- [ ] **Phase 6 Complete:** Testing and validation passed
- [ ] **Phase 7 Complete:** Documentation and deployment ready
- [ ] **Phase 8 Complete:** Production deployment successful

**Migration Completed:** _________________ (Date)
**Final Validation:** ✅ **PASSED** / ❌ **FAILED**

---

*This checklist serves as a living document throughout the migration process. Update regularly with progress, issues, and notes.* 