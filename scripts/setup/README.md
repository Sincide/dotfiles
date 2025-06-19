# Dotfiles Installation System

A comprehensive, interactive installer for Martin's Arch Linux + Hyprland dotfiles setup.

## 🚀 Features

- **Interactive Installation**: Step-by-step prompts for complete control
- **Package Categories**: Organized package lists for different use cases
- **System Optimization**: GPU drivers, performance tweaks, and service configuration
- **Smart Deployment**: Automatic backup of existing configs before symlinking
- **Comprehensive Logging**: Detailed logs for troubleshooting
- **Error Handling**: Robust error detection and recovery

## 📦 Package Categories

### Essential (`essential.txt`)
Core system packages required for basic Hyprland functionality:
- Base system tools (git, curl, htop, etc.)
- Audio system (PipeWire)
- Wayland display server components
- Hyprland and core WM tools
- Essential fonts and utilities

### Development (`development.txt`)
Programming tools and development environment:
- Programming languages (Rust, Python, Node.js, Go, Lua)
- Development tools (Neovim, VS Code, terminal tools)
- Build systems and compilers
- Database and container tools
- Language servers for IDE support

### Theming (`theming.txt`)
Dynamic theming and aesthetic enhancements:
- Color tools (matugen, pywal)
- Icon and GTK themes
- Additional fonts and cursors
- Screenshot and preview tools
- Visual effects and utilities

### Multimedia (`multimedia.txt`)
Media players, editors, and creative tools:
- Video/audio players (MPV, VLC, Spotify)
- Creative software (GIMP, Inkscape, Blender)
- Codecs and multimedia libraries
- Office and productivity suites
- Media utilities and converters

### Gaming (`gaming.txt`)
Gaming platforms and performance tools:
- Gaming platforms (Steam, Lutris, Heroic)
- Compatibility layers (Wine, DXVK)
- Performance tools (GameMode, MangoHUD)
- Emulators and game development tools
- Controller support and monitoring

### Optional (`optional.txt`)
Nice-to-have applications and utilities:
- Communication apps (Signal, Discord, Telegram)
- Additional browsers and cloud storage
- Virtualization tools
- Productivity and note-taking apps
- System utilities and backup tools

## 🛠 Installation

### Prerequisites
- Fresh Arch Linux installation
- Internet connection
- User account with sudo privileges

### Quick Start
```bash
# Clone dotfiles (if not already done)
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Make installer executable
chmod +x scripts/setup/dotfiles-installer.sh

# Run the installer
./scripts/setup/dotfiles-installer.sh
```

### What the Installer Does

1. **System Checks**
   - Verifies Arch Linux
   - Checks internet connectivity
   - Validates sudo access

2. **AUR Helper Installation**
   - Installs yay-bin for AUR package management

3. **Package Installation**
   - Interactive selection of package categories
   - Automatic separation of official/AUR packages
   - Progress tracking and error handling

4. **Dotfiles Deployment**
   - Creates ~/.config symlinks
   - Backs up existing configurations
   - Links all dotfiles directories

5. **User Environment Setup**
   - Sets fish as default shell
   - Configures git settings
   - Generates SSH keys

6. **System Optimization**
   - Enables essential services
   - Installs appropriate GPU drivers
   - Applies performance tweaks
   - Optimizes build configuration

## 📁 Directory Structure

```
scripts/setup/
├── dotfiles-installer.sh    # Main installer script
├── packages/                # Package category files
│   ├── essential.txt
│   ├── development.txt
│   ├── theming.txt
│   ├── multimedia.txt
│   ├── gaming.txt
│   └── optional.txt
└── README.md               # This file
```

## 🎯 Best Practices

### Package Management
- Only uses `pacman` and `yay` (no pip, npm global installs)
- Separates official and AUR packages automatically
- Uses `--needed` flag to avoid reinstalling packages
- Provides package count and confirmation before installation

### Configuration Management
- Creates backups before overwriting existing configs
- Uses symbolic links for easy updates
- Maintains original file structure
- Provides rollback capabilities

### Error Handling
- Comprehensive logging to `~/dotfiles/logs/`
- Non-destructive operations with confirmation prompts
- Graceful failure handling with continuation options
- Clear error messages and troubleshooting hints

## 🔧 Customization

### Adding Packages
Edit the appropriate package file in `scripts/setup/packages/`:
```bash
# Add to essential.txt for core packages
echo "your-package-name" >> scripts/setup/packages/essential.txt
```

### Modifying Installation Flow
The main installer script is modular and can be easily customized:
- Add new package categories
- Modify system optimization steps
- Customize user environment setup
- Add additional deployment targets

### Configuration Templates
Package files support comments and empty lines:
```bash
# Category description
package-name-1
package-name-2

# Another category
package-name-3
```

## 📊 Logging and Monitoring

### Log Files
- Location: `~/dotfiles/logs/installer_YYYYMMDD_HHMMSS.log`
- Contains timestamps, operation details, and error information
- Useful for troubleshooting failed installations

### Installation Tracking
The installer tracks completion status for each component:
- Package categories (essential, development, etc.)
- Dotfiles deployment
- User environment setup
- System optimization

## 🚨 Troubleshooting

### Common Issues
1. **Permission Errors**: Ensure user has sudo privileges
2. **Network Issues**: Check internet connection and DNS
3. **Package Conflicts**: Review package manager output
4. **AUR Build Failures**: Check build dependencies and disk space

### Recovery
- Installation can be resumed from any point
- Existing configurations are backed up automatically
- Package installation is idempotent (safe to re-run)
- Logs provide detailed error information

## 🔄 Updates and Maintenance

### Updating Dotfiles
```bash
cd ~/dotfiles
git pull origin main
./scripts/setup/dotfiles-installer.sh  # Re-run to update symlinks
```

### Package Updates
```bash
# Update all packages
yay -Syu

# Update specific category (manual)
yay -S --needed $(cat scripts/setup/packages/essential.txt | grep -v '^#' | grep -v '^$')
```

## 🤝 Contributing

When adding new packages or features:
1. Test on a clean Arch Linux installation
2. Update the appropriate package category file
3. Document any new dependencies or requirements
4. Ensure compatibility with existing configurations

## 📝 License

This installation system is part of Martin's dotfiles repository and follows the same license terms. 