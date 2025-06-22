# Evil Launcher - SCRAPPED

## 2025-01-XX - Project Scrapped

The evil-launcher project has been completely scrapped due to:

- GTK4 crate version conflicts with system packages
- Complex dependency management issues
- Better alternatives available (fuzzel works fine)
- Not worth the development overhead

### What was attempted:
- Rust + GTK4 application launcher
- Wayland layer-shell integration
- Material You theming via matugen
- Wallpaper selector with previews
- Fuzzy search functionality

### Why it failed:
- GTK4 crate versions (0.8.x-0.9.x) incompatible with system GTK4 4.18.6
- gtk-layer-shell integration problematic
- Too much complexity for the benefit gained
- fuzzel already provides excellent functionality

### Decision:
Stick with fuzzel as the application launcher. It's:
- Already working perfectly
- Well-maintained
- Fast and reliable
- Integrates well with existing setup

### Future:
Focus on other dotfiles improvements instead of reinventing the wheel. 