# AGS Wallpaper Selector
## 🎯 Beautiful, Functional Wallpaper Management for Evil Space Dotfiles

A modern, production-ready wallpaper selector built with AGS v2 and TypeScript, featuring seamless integration with the Evil Space dotfiles theming system.

---

## ✨ Features

### 🖼️ **Visual Wallpaper Management**
- **Category-Based Organization**: Automatic detection of wallpaper categories (abstract, dark, gaming, minimal, nature, space)
- **Thumbnail Grid**: Responsive grid layout with efficient thumbnail generation
- **Live Preview**: Click-to-preview with large image display
- **One-Click Application**: Apply wallpaper and generate matching color scheme

### 🎨 **Intelligent Theming Integration**
- **Matugen Integration**: Automatic Material You color generation
- **Theme Application**: Instant application to Waybar, Kitty, Hyprland, and all themed components
- **Cross-Platform Support**: Works with GNOME, KDE, XFCE, and fallback options

### ⚡ **Performance Optimized**
- **Thumbnail Caching**: Efficient memory usage with smart caching
- **Lazy Loading**: On-demand thumbnail generation
- **Background Processing**: Non-blocking file operations
- **Startup Time**: < 2 seconds to fully functional interface

---

## 🚀 Quick Start

### **Prerequisites**
```bash
# AGS v2 with Astal support
yay -S aylurs-gtk-shell-git

# Ensure matugen is installed
cargo install matugen

# TypeScript (for development)
yay -S nodejs npm typescript
```

### **Launch the Application**
```bash
# From ~/.config/ags (automatically symlinked)
ags run

# Or with debug output
AGS_DEBUG=1 ags run
```

### **Expected Directory Structure**
The application automatically scans:
```
/home/martin/dotfiles/assets/wallpapers/
├── abstract/     # Abstract and artistic wallpapers
├── dark/         # High contrast, OLED-optimized
├── gaming/       # Gaming-themed artwork
├── minimal/      # Clean, simple designs
├── nature/       # Landscapes and natural beauty
└── space/        # Cosmic scenes, nebulae, galaxies
```

---

## 🏗️ Architecture

### **Service Layer**
- **FileSystemService**: Directory scanning and file organization
- **WallpaperService**: Cross-platform wallpaper setting
- **MatugenService**: Color generation and theme application
- **ThumbnailService**: Efficient thumbnail generation with caching

### **Component Layer**
- **CategorySidebar**: Category selection with visual feedback
- **ThumbnailGrid**: Responsive wallpaper grid with lazy loading
- **ImagePreview**: Modal preview with apply/cancel actions
- **Main Application**: State management and component orchestration

### **Technology Stack**
- **Framework**: AGS v2 (Astal-based)
- **Language**: TypeScript with JSX
- **UI**: GTK3 via Astal bindings
- **Styling**: SCSS with Evil Space aesthetic
- **Image Processing**: GdkPixbuf for thumbnail generation

---

## 🎨 UI/UX Design

### **Evil Space Aesthetic**
- **Dark Theme**: Consistent with dotfiles cosmic theme
- **Glass Effects**: Modern backdrop blur and transparency
- **Smooth Animations**: 60fps transitions and hover effects
- **Material You**: Dynamic colors from selected wallpapers

### **User Experience**
- **Intuitive Navigation**: Clear category organization
- **Quick Selection**: Minimal clicks from launch to applied wallpaper
- **Visual Feedback**: Immediate response to all interactions
- **Keyboard Support**: Full keyboard navigation capability

---

## 🔧 Development

### **Development Commands**
```bash
# Start development server
ags run

# Type checking
tsc --noEmit

# Restart after code changes
pkill ags && ags run

# Debug mode
AGS_DEBUG=1 ags run
```

### **Project Structure**
```
~/.config/ags/
├── app.ts                          # Entry point
├── wallpaper-selector/
│   ├── main.tsx                   # Main application
│   ├── services/                  # Business logic services
│   ├── components/                # UI components
│   └── utils/                     # Utility functions
├── style/
│   └── wallpaper-selector.scss   # SCSS styling
└── types/
    └── index.ts                   # TypeScript definitions
```

### **Key Design Decisions**
1. **Service Architecture**: Modular design for maintainability
2. **TypeScript Usage**: Type safety and better development experience
3. **Thumbnail Caching**: Performance optimization for large collections
4. **Cross-Platform Support**: Works across different desktop environments

---

## 📊 Performance Metrics

### **Current Targets**
- **Startup Time**: < 2 seconds to fully functional interface
- **Memory Usage**: < 100MB for typical usage (50 wallpapers)
- **Thumbnail Loading**: < 500ms for initial grid population
- **Theme Application**: < 3 seconds complete theme switching

### **Optimization Features**
- **Smart Caching**: Thumbnail cache with memory management
- **Lazy Loading**: Load thumbnails only when needed
- **Background Processing**: Non-blocking file operations
- **Efficient Memory Usage**: Automatic cleanup and garbage collection

---

## 🤝 Integration with Evil Space Dotfiles

### **Automatic Integration**
- **Matugen Templates**: Uses existing matugen configuration
- **Theme Application**: Applies to all configured applications
- **Wallpaper Categories**: Works with organized wallpaper collection
- **Color Coordination**: Matches existing theming system

### **Supported Applications**
- **Waybar**: Status bar colors and styling
- **Hyprland**: Window manager colors and decorations
- **Kitty**: Terminal color scheme
- **Dunst**: Notification styling
- **GTK Applications**: System-wide application theming

---

## 🐛 Troubleshooting

### **Common Issues**

#### **AGS Not Found**
```bash
# Install AGS v2
yay -S aylurs-gtk-shell-git

# Verify installation
which ags
```

#### **Matugen Not Available**
```bash
# Install matugen
cargo install matugen

# Verify installation
which matugen
```

#### **Wallpaper Not Applying**
- Check wallpaper directory structure
- Verify desktop environment detection
- Check file permissions

#### **Thumbnails Not Loading**
- Verify GdkPixbuf installation
- Check image file formats (PNG, JPG, WEBP supported)
- Clear thumbnail cache if corrupted

### **Debug Mode**
```bash
# Enable debug output
AGS_DEBUG=1 ags run

# Check console for error messages
# Logs include service initialization, file scanning, and error details
```

---

## 📝 Development Status

### **✅ Completed Features**
- [x] Complete project structure and architecture
- [x] FileSystem service with directory scanning
- [x] Thumbnail generation with caching
- [x] Cross-platform wallpaper setting
- [x] Matugen integration for color generation
- [x] All UI components (Sidebar, Grid, Preview)
- [x] Main application with state management
- [x] Evil Space themed SCSS styling
- [x] TypeScript type definitions

### **🚧 Development Phase**
- [ ] **Testing**: Comprehensive testing across different scenarios
- [ ] **Optimization**: Performance tuning and memory optimization
- [ ] **Error Handling**: Enhanced error recovery and user feedback
- [ ] **Documentation**: User guides and troubleshooting

### **📅 Future Enhancements**
- [ ] **Search Functionality**: Search wallpapers by name
- [ ] **Favorites System**: Mark and access favorite wallpapers
- [ ] **Custom Categories**: User-defined wallpaper categories
- [ ] **Keyboard Shortcuts**: Enhanced keyboard navigation

---

## 📚 References

### **Technical Documentation**
- [AGS v2 Documentation](https://ags.js.org/)
- [Astal Library Reference](https://github.com/Aylur/astal)
- [Material You Guidelines](https://m3.material.io/)
- [Matugen Documentation](https://github.com/InioX/matugen)

### **Evil Space Dotfiles**
- [Main Dotfiles Repository](../)
- [Dynamic Themes Documentation](../docs/DYNAMIC_THEMES.md)
- [Development Log](../docs/AGS_WALLPAPER_SELECTOR_DEVLOG.md)

---

**Status**: 🚧 Development Phase  
**Last Updated**: January 2025  
**License**: MIT  
**Maintainer**: Evil Space Dotfiles Project 