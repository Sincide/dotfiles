# Evil Launcher - Dynamic Theming Integration Plan

## 🎯 Project Overview

**Goal**: Integrate the dotfiles' dynamic theming system into evil-launcher to provide automatic theme switching based on wallpaper categories, replacing the current fuzzel-based workflow while maintaining full compatibility.

**Current State**: Evil Launcher has basic wallpaper selection with `swww` integration. The dotfiles have a sophisticated dynamic theming system using `dynamic_theme_switcher.sh` + `matugen` + category-based theme mappings.

**Target State**: Evil Launcher becomes the unified interface for both application launching and wallpaper selection with automatic theme application.

## 📋 Implementation Phases

### Phase 1: Basic Theme Integration ✅
**Status**: Ready to implement  
**Timeline**: 1-2 development sessions  
**Risk**: Low

#### Changes Required
1. **Add Category Detection Function**
   ```go
   func detectCategory(wallpaperPath string) string {
       if strings.Contains(wallpaperPath, "/space/") {
           return "space"
       } else if strings.Contains(wallpaperPath, "/nature/") {
           return "nature"
       } else if strings.Contains(wallpaperPath, "/gaming/") {
           return "gaming"
       } else if strings.Contains(wallpaperPath, "/minimal/") {
           return "minimal"
       } else if strings.Contains(wallpaperPath, "/dark/") {
           return "dark"
       } else if strings.Contains(wallpaperPath, "/abstract/") {
           return "abstract"
       }
       return "minimal" // Safe fallback
   }
   ```

2. **Integrate Theme Switcher Call**
   ```go
   // After successful swww command in main()
   if mode == "wall" && selectedItem != nil {
       category := detectCategory(selectedItem.Exec)
       applyDynamicTheme(selectedItem.Exec, category)
   }
   ```

3. **Add Theme Application Function**
   ```go
   func applyDynamicTheme(wallpaperPath, category string) {
       homeDir := getHomeDir()
       themeSwitcher := filepath.Join(homeDir, "dotfiles/scripts/theming/dynamic_theme_switcher.sh")
       
       if _, err := os.Stat(themeSwitcher); os.IsNotExist(err) {
           fmt.Printf("⚠️  Theme switcher not found, using matugen fallback...\n")
           fallbackMatugen(wallpaperPath)
           return
       }
       
       fmt.Printf("🎨 Applying %s theme...\n", category)
       cmd := exec.Command("bash", themeSwitcher, "apply", wallpaperPath)
       
       if err := cmd.Run(); err != nil {
           fmt.Printf("⚠️  Theme switching failed: %v\n", err)
           fallbackMatugen(wallpaperPath)
       } else {
           fmt.Printf("✨ %s theme applied successfully!\n", strings.Title(category))
       }
   }
   ```

4. **Add Matugen Fallback**
   ```go
   func fallbackMatugen(wallpaperPath string) {
       homeDir := getHomeDir()
       configPath := filepath.Join(homeDir, "dotfiles/matugen/config.toml")
       
       var cmd *exec.Cmd
       if _, err := os.Stat(configPath); err == nil {
           cmd = exec.Command("matugen", "image", "--config", configPath, wallpaperPath)
       } else {
           cmd = exec.Command("matugen", "image", wallpaperPath)
       }
       
       if err := cmd.Run(); err != nil {
           fmt.Printf("⚠️  Matugen color generation failed: %v\n", err)
       } else {
           fmt.Printf("🌈 Material You colors generated\n")
       }
   }
   ```

#### Testing Strategy
- Test with wallpapers from each category
- Verify theme switching works correctly
- Ensure fallback works when theme system unavailable
- Test with and without `matugen` config

#### Success Criteria
- [ ] Category detection works for all 6 categories
- [ ] Theme switcher is called correctly after wallpaper selection
- [ ] Fallback to matugen works when theme switcher unavailable
- [ ] User gets clear feedback about theme application
- [ ] No regressions in existing wallpaper functionality

---

### Phase 2: Enhanced User Experience 🔄
**Status**: After Phase 1 completion  
**Timeline**: 2-3 development sessions  
**Risk**: Medium

#### Changes Required
1. **Category Display in Wallpaper List**
   ```go
   // Modify Item struct
   type Item struct {
       Name     string
       Exec     string
       Category string  // NEW: Store detected category
       IsRandom bool
   }
   
   // Update display format
   displayName := fmt.Sprintf("[%s] %s", item.Category, item.Name)
   ```

2. **Progress Feedback During Theme Application**
   ```go
   func applyDynamicThemeWithProgress(wallpaperPath, category string) {
       fmt.Printf("🎨 Applying %s theme", category)
       
       // Start progress indicator in goroutine
       done := make(chan bool)
       go showProgress(done)
       
       // Apply theme
       result := applyDynamicTheme(wallpaperPath, category)
       
       // Stop progress
       done <- true
       fmt.Printf("\n")
       
       return result
   }
   
   func showProgress(done chan bool) {
       chars := []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}
       i := 0
       for {
           select {
           case <-done:
               return
           default:
               fmt.Printf("\r🎨 Applying theme %s", chars[i%len(chars)])
               time.Sleep(100 * time.Millisecond)
               i++
           }
       }
   }
   ```

3. **Category Filtering Option**
   ```go
   // Add new mode: ./launcher wall --category=space
   func parseArgs() (mode, category string) {
       if len(os.Args) < 2 {
           return "", ""
       }
       
       mode = os.Args[1]
       
       // Check for category filter
       for _, arg := range os.Args[2:] {
           if strings.HasPrefix(arg, "--category=") {
               category = strings.TrimPrefix(arg, "--category=")
           }
       }
       
       return mode, category
   }
   ```

4. **Enhanced Error Handling**
   ```go
   type ThemeError struct {
       Operation string
       Err       error
   }
   
   func (e *ThemeError) Error() string {
       return fmt.Sprintf("Theme %s failed: %v", e.Operation, e.Err)
   }
   
   func applyDynamicThemeWithErrors(wallpaperPath, category string) error {
       // Detailed error tracking and user-friendly messages
   }
   ```

#### Testing Strategy
- Test category display formatting
- Verify progress indicator during slow theme switches
- Test category filtering functionality
- Test error handling with broken theme system

#### Success Criteria
- [ ] Users can see wallpaper categories in the interface
- [ ] Progress feedback appears during theme application
- [ ] Category filtering works correctly
- [ ] Error messages are helpful and actionable
- [ ] Theme application never hangs the interface

---

### Phase 3: Advanced Features 📋
**Status**: Future enhancement  
**Timeline**: 3-4 development sessions  
**Risk**: Medium-High

#### Changes Required
1. **Theme-Only Mode**
   ```bash
   ./launcher theme           # Show current themes for each category
   ./launcher theme space     # Apply space theme to current wallpaper
   ./launcher theme --list    # List all available themes
   ```

2. **Configuration File Support**
   ```go
   type Config struct {
       WallpaperDir string            `toml:"wallpaper_dir"`
       AppDirs      []string          `toml:"app_dirs"`
       Themes       map[string]Theme  `toml:"themes"`
       Preview      PreviewConfig     `toml:"preview"`
   }
   
   type Theme struct {
       GTK    string `toml:"gtk"`
       Icons  string `toml:"icons"`
       Cursor string `toml:"cursor"`
   }
   ```

3. **Native Theme Application (Go Implementation)**
   ```go
   // Replace bash script calls with native Go implementation
   func applyThemeNative(category string, wallpaperPath string) error {
       theme := config.Themes[category]
       
       // Apply GTK theme via gsettings
       if err := setGSetting("org.gnome.desktop.interface", "gtk-theme", theme.GTK); err != nil {
           return err
       }
       
       // Generate colors with matugen
       if err := generateMatugenColors(wallpaperPath); err != nil {
           return err
       }
       
       // Restart applications
       return restartApplications()
   }
   ```

4. **Icon Display Support**
   ```go
   // Parse desktop files for icon information
   func parseDesktopIcon(desktopPath string) string {
       // Extract Icon= field from desktop file
   }
   
   // Display icons in TUI (if terminal supports it)
   func displayItemWithIcon(item Item) string {
       if iconPath := getIconPath(item.Icon); iconPath != "" {
           return fmt.Sprintf("🖼️  %s", item.Name)
       }
       return item.Name
   }
   ```

#### Testing Strategy
- Test theme-only mode extensively
- Validate configuration file parsing
- Test native theme application vs bash script
- Performance testing for icon loading

#### Success Criteria
- [ ] Theme-only mode works independently of wallpaper changes
- [ ] Configuration file allows full customization
- [ ] Native Go implementation is faster than bash scripts
- [ ] Icon support enhances usability without performance impact

---

## 🔧 Technical Considerations

### Performance Impact
- **Theme Application**: Currently 2-3 seconds via bash scripts
- **Target**: <1 second with native Go implementation
- **Memory**: Minimal impact, theme data is small

### Error Handling Strategy
1. **Graceful Degradation**: Always set wallpaper even if theming fails
2. **Clear Feedback**: Show specific error messages to user
3. **Fallback Chain**: Theme switcher → matugen → wallpaper only
4. **Recovery**: Never crash, always provide working state

### Compatibility Matrix
| Component | Phase 1 | Phase 2 | Phase 3 |
|-----------|---------|---------|---------|
| Existing fuzzel workflow | ✅ Full | ✅ Full | ✅ Full |
| Bash theme scripts | ✅ Required | ✅ Required | ⚠️ Optional |
| Matugen integration | ✅ Full | ✅ Full | ✅ Enhanced |
| Waybar/Dunst/Kitty | ✅ Full | ✅ Full | ✅ Full |

### Integration Points
- **Wallpaper Directory**: `~/dotfiles/assets/wallpapers/`
- **Theme Scripts**: `~/dotfiles/scripts/theming/`
- **Matugen Config**: `~/dotfiles/matugen/config.toml`
- **Application Configs**: Auto-updated by theme system

### Risk Mitigation
1. **Backup Integration**: Keep fuzzel workflow as backup
2. **Feature Flags**: Allow disabling theme integration
3. **Extensive Testing**: Test on clean and configured systems
4. **Documentation**: Comprehensive troubleshooting guide

## 📊 Success Metrics

### User Experience
- ⏱️ **Time to wallpaper change**: <5 seconds (currently ~10s with fuzzel)
- 🎨 **Theme accuracy**: 100% category detection
- 🔄 **Workflow efficiency**: Single interface vs multi-step fuzzel
- 🐛 **Error rate**: <1% theme application failures

### Technical Performance
- 🚀 **Launch time**: <100ms (Go binary)
- 💾 **Memory usage**: <10MB peak
- 🔄 **Theme switch time**: <3 seconds (Phase 1), <1 second (Phase 3)
- 📁 **File scanning**: <500ms for ~200 wallpapers

### Integration Quality
- ✅ **Compatibility**: 100% with existing theme system
- 🔄 **Reliability**: 99%+ successful theme applications
- 📚 **Maintainability**: Well-documented, modular code
- 🛠️ **Extensibility**: Easy to add new categories/themes

## 🚀 Getting Started

### Prerequisites
- Go 1.24.4+ installed
- Existing dotfiles dynamic theming system
- `swww` daemon running
- Optional: `chafa` for wallpaper previews

### Development Setup
```bash
cd app-dev/evil-launcher
go mod tidy
go build -o launcher .
./launcher wall  # Test current functionality
```

### Implementation Order
1. **Start with Phase 1**: Basic integration with existing bash scripts
2. **Test thoroughly**: Ensure no regressions in wallpaper functionality  
3. **Gather feedback**: Use for daily workflow before proceeding
4. **Phase 2**: Enhanced UX based on real usage experience
5. **Phase 3**: Advanced features as needed

This plan ensures a **stable, incremental rollout** that maintains system reliability while adding powerful new capabilities. 