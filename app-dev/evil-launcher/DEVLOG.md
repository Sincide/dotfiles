# Evil Launcher - Development Log

## 📝 Project Timeline

### 2024-12-29 - Project Initiation
**Status**: Analysis & Planning Complete  
**Focus**: Dynamic theming integration analysis

#### Decisions Made
1. **Architecture Decision**: Keep existing TUI implementation, add theme integration as enhancement
2. **Integration Strategy**: Call existing `dynamic_theme_switcher.sh` rather than reimplementing in Go (Phase 1)
3. **Compatibility Priority**: Maintain 100% backward compatibility with current fuzzel workflow
4. **Phased Approach**: 3-phase implementation (Basic → Enhanced → Advanced)

#### Analysis Results
- **Current System Analysis**: Comprehensive understanding of fuzzel-based wallpaper selection
- **Theme System Integration**: Mapped all integration points with existing dynamic theming
- **Category Detection**: Simple string matching on file paths is sufficient
- **Error Handling**: Need robust fallback chain for theme system failures

#### Technical Findings
- Evil Launcher already scans correct wallpaper directory structure
- Categories are naturally organized in subdirectories (`space/`, `nature/`, etc.)
- `swww` integration is already working perfectly
- Theme switching takes 2-3 seconds, need progress feedback

#### Documentation Created
- ✅ `README.md`: Comprehensive project overview and usage
- ✅ `CHANGE_PLAN.md`: Detailed 3-phase implementation plan  
- ✅ `DEVLOG.md`: This development log

#### Next Steps
- [ ] Implement Phase 1: Basic theme integration
- [ ] Add category detection function
- [ ] Add theme switcher call after wallpaper selection
- [ ] Test with all wallpaper categories

---

## 🔍 Analysis Deep Dive

### Current System Architecture
```
Evil Launcher (Go TUI)
├── Application Launcher
│   ├── Desktop file scanning
│   ├── Fuzzy search filtering
│   └── Process launching
└── Wallpaper Selector
    ├── Directory scanning (/dotfiles/assets/wallpapers/)
    ├── Category organization (space/, nature/, etc.)
    ├── Live chafa previews
    └── swww integration ✅
```

### Target Integration
```
Evil Launcher (Enhanced)
├── Application Launcher (unchanged)
└── Wallpaper Selector
    ├── Directory scanning (unchanged)
    ├── Category detection ← NEW
    ├── swww integration (unchanged)
    └── Dynamic theme application ← NEW
        ├── Call dynamic_theme_switcher.sh
        ├── Fallback to matugen
        └── User feedback
```

### Fuzzel Workflow Replacement
```
BEFORE (Multi-step):
wallpaper_manager.sh select
↓
fuzzel (select category)
↓  
fuzzel (select wallpaper)
↓
apply_wallpaper()
↓
dynamic_theme_switcher.sh apply
↓
Theme applied

AFTER (Single interface):
./launcher wall
↓
TUI selection (with preview)
↓
swww + theme application
↓
Theme applied
```

### Theme System Integration Points
1. **Category Detection**: From wallpaper file path
2. **Theme Switcher**: `~/dotfiles/scripts/theming/dynamic_theme_switcher.sh`
3. **Matugen Config**: `~/dotfiles/matugen/config.toml`
4. **Fallback Chain**: theme_switcher → matugen → wallpaper-only

### Category Mapping Verification
```bash
# Verified wallpaper directory structure:
~/dotfiles/assets/wallpapers/
├── abstract/    → abstract theme (Graphite + Papirus + Bibata-Modern-Amber)
├── dark/        → dark theme (Graphite-Dark + Papirus-Dark + Bibata-Modern-Classic)  
├── gaming/      → gaming theme (Graphite-Dark + Papirus + Bibata-Modern-Classic)
├── minimal/     → minimal theme (WhiteSur-Light + WhiteSur + Capitaine-Cursors)
├── nature/      → nature theme (Orchis-Green-Dark + Tela-circle-green + Bibata-Modern-Amber)
└── space/       → space theme (Graphite-Dark + Papirus-Dark + Bibata-Modern-Ice)
```

---

## 🚧 Implementation Notes

### Phase 1 Implementation Strategy

#### Code Changes Required
1. **New Functions to Add**:
   - `detectCategory(wallpaperPath string) string`
   - `applyDynamicTheme(wallpaperPath, category string)`
   - `fallbackMatugen(wallpaperPath string)`

2. **Integration Point**: 
   - In `main()` function, after successful `swww` command
   - Before printing success message

3. **Error Handling Philosophy**:
   - **Never fail wallpaper setting** due to theme issues
   - Always provide user feedback about what happened
   - Graceful degradation: theme_switcher → matugen → wallpaper-only

#### Testing Matrix
| Category | Test Wallpaper | Expected Theme | Test Status |
|----------|----------------|----------------|-------------|
| space | `space/galaxy.jpg` | Graphite-Dark + Papirus-Dark + Bibata-Modern-Ice | ⏳ Pending |
| nature | `nature/forest.jpg` | Orchis-Green-Dark + Tela-circle-green + Bibata-Modern-Amber | ⏳ Pending |
| gaming | `gaming/neon.jpg` | Graphite-Dark + Papirus + Bibata-Modern-Classic | ⏳ Pending |
| minimal | `minimal/simple.jpg` | WhiteSur-Light + WhiteSur + Capitaine-Cursors | ⏳ Pending |
| dark | `dark/black.jpg` | Graphite-Dark + Papirus-Dark + Bibata-Modern-Classic | ⏳ Pending |
| abstract | `abstract/art.jpg` | Graphite + Papirus + Bibata-Modern-Amber | ⏳ Pending |

#### Edge Cases to Handle
1. **Theme switcher missing**: Fall back to matugen
2. **Matugen missing**: Continue with wallpaper-only
3. **Invalid wallpaper path**: Should not reach theme application
4. **Category detection failure**: Use "minimal" as safe fallback
5. **Theme application timeout**: Need timeout handling

---

## 📊 Performance Considerations

### Current Performance Baseline
- **Launcher startup**: ~50ms (Go binary advantage)
- **Wallpaper scanning**: ~100ms for ~50 wallpapers
- **Desktop file scanning**: ~200ms for ~150 applications
- **Chafa preview generation**: ~300ms per wallpaper

### Expected Performance Impact
- **Category detection**: +1ms (string matching)
- **Theme application**: +2-3 seconds (bash script execution)
- **Total wallpaper change time**: ~3-4 seconds (vs ~10s with fuzzel)

### Optimization Opportunities
1. **Phase 1**: Use existing bash scripts (reliable, tested)
2. **Phase 2**: Add progress indicators (user experience)
3. **Phase 3**: Native Go implementation (performance)

---

## 🐛 Known Issues & Considerations

### Current Limitations
1. **Hard-coded paths**: Directory paths are compiled into binary
2. **No configuration**: Cannot customize theme mappings without code changes
3. **Bash dependency**: Requires bash and theme scripts to be present
4. **No progress feedback**: User waits with no indication during theme application

### Design Decisions Rationale

#### Why Call Bash Scripts Instead of Native Go?
**Pros of Bash Script Approach (Phase 1)**:
- ✅ Proven, battle-tested theme switching logic
- ✅ No risk of reimplementation bugs
- ✅ Maintains exact compatibility with current system
- ✅ Faster development time
- ✅ Easier to debug and troubleshoot

**Cons**:
- ❌ Slower execution (2-3 seconds)
- ❌ Bash dependency
- ❌ Less control over error handling

**Decision**: Start with bash scripts for reliability, optimize later in Phase 3.

#### Why Category Detection from File Path?
**Alternative Considered**: Parse category from filename patterns
**Decision**: Use directory structure because:
- ✅ More reliable than filename parsing
- ✅ Matches current wallpaper organization
- ✅ Simpler implementation
- ✅ Consistent with fuzzel workflow

#### Why Keep TUI Instead of GUI?
**Alternative Considered**: Create GTK/Qt wallpaper selector
**Decision**: Keep TUI because:
- ✅ Consistent with dotfiles philosophy (terminal-centric)
- ✅ Faster than GUI applications
- ✅ Works over SSH/remote sessions
- ✅ Minimal dependencies
- ✅ Fits well with Hyprland workflow

---

## 🎯 Success Criteria & Testing

### Phase 1 Acceptance Criteria
- [ ] **Functionality**: All 6 categories detected correctly
- [ ] **Integration**: Theme switcher called after wallpaper selection
- [ ] **Fallback**: Matugen fallback works when theme switcher unavailable
- [ ] **Compatibility**: No regressions in existing wallpaper/app launcher
- [ ] **Feedback**: Clear user messages about theme application status
- [ ] **Error Handling**: Graceful degradation when theme system fails

### User Acceptance Testing Plan
1. **Basic Functionality**: Test wallpaper selection from each category
2. **Error Scenarios**: Test with missing theme scripts, broken matugen
3. **Performance**: Time complete wallpaper+theme change workflow
4. **Daily Usage**: Use as primary launcher for 1 week
5. **Edge Cases**: Test with unusual wallpaper filenames, empty categories

### Integration Testing Checklist
- [ ] swww daemon running and functional
- [ ] dynamic_theme_switcher.sh present and executable
- [ ] matugen installed and configured
- [ ] All 6 wallpaper categories have test images
- [ ] GTK themes, icon themes, cursor themes installed
- [ ] Waybar, Dunst, Kitty respond to theme changes

---

## 📚 References & Dependencies

### External Dependencies
- **Go 1.24.4+**: Core language requirement
- **swww**: Wallpaper daemon and CLI tool
- **stty**: Terminal control (standard on Linux)
- **chafa**: Optional wallpaper previews
- **bash**: Required for theme switching scripts

### Internal Dependencies (Dotfiles)
- `scripts/theming/dynamic_theme_switcher.sh`: Core theme switching logic
- `scripts/theming/wallpaper_manager.sh`: Reference implementation
- `matugen/config.toml`: Material You color generation config
- `assets/wallpapers/`: Category-organized wallpaper collection

### Documentation References
- `../../../docs/DYNAMIC_THEMES.md`: Complete theming system documentation
- `../../../scripts/theming/`: Theme switching implementation
- `../../../matugen/`: Matugen configuration and templates

### Related Tools & Projects
- [matugen](https://github.com/InioX/matugen): Material You color generation
- [swww](https://github.com/Horus645/swww): Wayland wallpaper daemon
- [chafa](https://hpjansson.org/chafa/): Terminal image viewer
- [nwg-look](https://github.com/nwg-piotr/nwg-look): GTK theme application for Wayland

---

## 🚀 Next Session Action Items

### Immediate Tasks (Phase 1 Implementation)
1. **[ ]** Add `detectCategory()` function to main.go
2. **[ ]** Add `applyDynamicTheme()` function to main.go  
3. **[ ]** Add `fallbackMatugen()` function to main.go
4. **[ ]** Integrate theme application call in wallpaper mode
5. **[ ]** Test basic functionality with one wallpaper from each category
6. **[ ]** Handle error cases and user feedback

### Development Environment Setup
```bash
# Verify development environment
cd app-dev/evil-launcher
go version  # Should be 1.24.4+
which swww  # Should exist
ls ~/dotfiles/scripts/theming/dynamic_theme_switcher.sh  # Should exist
ls ~/dotfiles/assets/wallpapers/  # Should show 6 categories

# Test current functionality
go build -o launcher .
./launcher wall  # Verify wallpaper selection works
```

### Code Quality Checklist
- [ ] Add comprehensive error handling
- [ ] Add helpful user feedback messages
- [ ] Maintain existing code style and patterns
- [ ] Add comments for new functions
- [ ] Ensure graceful degradation for all failure modes

### Documentation Updates
- [ ] Update README.md with new functionality
- [ ] Document any new command-line options
- [ ] Update installation/usage instructions
- [ ] Add troubleshooting section for theme integration

**Ready to begin Phase 1 implementation! 🚀** 