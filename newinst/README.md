# Modular Dotfiles Installer

A complete rewrite of the monolithic dotfiles installer, broken down into 11 independent, focused scripts for maximum flexibility and reliability.

## 🚀 Quick Start

### Fresh System Installation
```bash
git clone https://github.com/your-username/dotfiles.git
cd dotfiles/newinst/
chmod +x *.sh

# Run all scripts in order
./00-prerequisites.sh
./01-setup-chaotic-aur.sh
./02-install-packages.sh
./03-deploy-dotfiles.sh
./04-setup-theming.sh
./05-setup-external-drives.sh
./06-setup-brave-backup.sh
./07-setup-ollama.sh
./08-setup-virt-manager.sh
./09-system-optimization.sh
./10-user-setup.sh
```

### Automated Installation
```bash
# Run all scripts with minimal interaction
for script in {00..10}-*.sh; do
    ./"$script" -y
done
```

## 📋 Script Overview

| Script | Purpose | Key Features |
|--------|---------|--------------|
| `00-prerequisites.sh` | System validation & yay setup | ✅ Arch Linux check, yay installation, basic tools |
| `01-setup-chaotic-aur.sh` | Chaotic-AUR repository | ✅ Faster package installation, keyring handling |
| `02-install-packages.sh` | Package installation | ✅ 6 categories, easy customization, conflict handling |
| `03-deploy-dotfiles.sh` | Configuration deployment | ✅ Symlinks, backups, conflict resolution |
| `04-setup-theming.sh` | Dynamic theming system | ✅ Themes, wallpapers, matugen integration |
| `05-setup-external-drives.sh` | Drive management | ✅ Auto-mounting, fstab entries, symlinks |
| `06-setup-brave-backup.sh` | Browser backup/restore | ✅ Intelligent detection, automated backups |
| `07-setup-ollama.sh` | AI platform setup | ✅ Model selection, interactive chat, utilities |
| `08-setup-virt-manager.sh` | Virtualization setup | ✅ KVM/QEMU, conflict resolution, network setup |
| `09-system-optimization.sh` | Performance tuning | ✅ Kernel params, sysctl, ZRAM, I/O scheduler |
| `10-user-setup.sh` | Final environment setup | ✅ Directories, shell config, system summary |

## 🎯 Key Features

### ✅ **Complete Independence**
- Each script is fully standalone
- No shared dependencies or configuration files
- Can be run individually or in sequence
- Safe to re-run multiple times

### ✅ **Smart Package Management**
- **One comprehensive script** with all categories
- Easy customization by editing arrays directly
- Full yay output visibility
- Automatic conflict resolution

### ✅ **Intelligent Behavior**
- **Fresh installs**: Prioritizes restoration and setup
- **Existing systems**: Handles upgrades and modifications gracefully
- **Conflict resolution**: Automatic backup and safe handling
- **Hardware detection**: Optimizations based on your system

### ✅ **User-Friendly Interface**
- Clear colored output (info, success, warning, error)
- Comprehensive help for every script (`--help`)
- Dry run mode to preview changes (`-n`)
- Skip confirmations for automation (`-y`)

## 🛠️ Usage Examples

### Individual Script Usage
```bash
# Preview what a script would do
./02-install-packages.sh -n

# Run with custom options
./02-install-packages.sh --no-gaming --no-optional

# Skip confirmations for automation
./07-setup-ollama.sh -y

# Get detailed help
./08-setup-virt-manager.sh --help
```

### Package Customization
Edit `02-install-packages.sh` directly:
```bash
# Comment out packages you don't want
get_gaming_packages() {
    local packages=(
        "steam"
        # "lutris"          # Commented out - won't install
        "gamemode"
        # "discord"         # Commented out - won't install
    )
    echo "${packages[@]}"
}
```

### AI Model Selection
The Ollama script provides an interactive menu:
```
Available AI Models:

General Purpose Models:
 1) llama3.2:1b          - Meta Llama 3.2 1B - Ultra-fast lightweight model (1.3GB)
 2) llama3.2:3b          - Meta Llama 3.2 3B - Fast general purpose model (2GB)
 3) phi4:latest          - Microsoft Phi-4 - Advanced reasoning model (7.4GB)

Selection Instructions:
• Select models by number (space-separated): 1 3 5
• Select range: 1-4 or 1-4 7 9
• Select all: all
• Skip model installation: none or just press Enter
• Recommended for beginners: 1 7 11 (small general + coding + embedding)
```

## 🔧 Advanced Configuration

### Environment Variables
```bash
# Custom dotfiles directory
export DOTFILES_DIR="/path/to/dotfiles"

# Custom log directory
export LOG_DIR="/custom/log/path"
```

### Script Flags
All scripts support these common flags:
- `-h, --help` - Show detailed help
- `-n, --dry-run` - Preview changes without applying
- `-y, --yes` - Skip confirmation prompts
- `--log-dir DIR` - Custom log directory

### Specific Script Options
```bash
# Package installation
./02-install-packages.sh --no-gaming --no-optional

# Dotfiles deployment
./03-deploy-dotfiles.sh --force --skip-backup

# Virtualization setup
./08-setup-virt-manager.sh --skip-packages --skip-user-setup

# System optimization
./09-system-optimization.sh --skip-kernel-params --skip-zram
```

## 🐛 Troubleshooting

### Common Issues

#### Package Conflicts
The installer automatically handles common conflicts:
- **iptables vs iptables-nft**: Automatically resolved in virtualization setup
- **Package overwrites**: Uses `--overwrite '*'` flag for safe handling

#### Permission Issues
```bash
# Fix script permissions
chmod +x *.sh

# Check sudo access
sudo -v
```

#### Network Issues
```bash
# Test internet connectivity
ping -c 3 google.com

# Check Chaotic-AUR setup
./01-setup-chaotic-aur.sh -n
```

### Log Files
All operations are logged in `~/dotfiles/logs/`:
```bash
# View recent logs
ls -la ~/dotfiles/logs/

# Check specific script log
tail -f ~/dotfiles/logs/packages_20231220_143022.log
```

### Recovery
If something goes wrong:
```bash
# Restore from automatic backups
ls ~/.config/dotfiles-backups/

# Re-run specific script
./03-deploy-dotfiles.sh --force
```

## 📊 What Gets Installed

### Essential Packages (80+ packages)
- **Base system**: base-devel, git, curl, wget, htop, btop
- **Network**: NetworkManager, openssh, rsync
- **Audio**: PipeWire stack (pipewire, wireplumber, pavucontrol)
- **Wayland**: Hyprland, waybar, kitty, fuzzel
- **Fonts**: Nerd fonts, system fonts

### Development Tools (40+ packages)
- **Languages**: Python, Node.js, Rust, Go
- **Editors**: VS Code, Neovim
- **Tools**: Docker, Git tools, development utilities

### Theming (30+ packages)
- **Themes**: GTK themes, icon themes, cursor themes
- **Tools**: matugen, dynamic theming utilities
- **Wallpapers**: Curated wallpaper collection

### Multimedia (20+ packages)
- **Media**: VLC, mpv, image viewers
- **Graphics**: GIMP, image manipulation tools
- **Audio**: Audio production tools

### Gaming (15+ packages)
- **Platforms**: Steam, Lutris
- **Tools**: GameMode, performance tools
- **Emulation**: RetroArch and cores

### Optional (30+ packages)
- **Productivity**: LibreOffice, document tools
- **Communication**: Messaging apps
- **Utilities**: System utilities, backup tools

## 🎨 Theming System

### Dynamic Themes
- **Automatic color extraction** from wallpapers
- **Real-time theme switching** with `restart-theme` command
- **GTK integration** with proper libadwaita support
- **Multiple theme collections** (Graphite, Orchis, WhiteSur)

### Wallpaper Collections
- **Categorized wallpapers**: Abstract, nature, space, minimal
- **High-quality images** optimized for different screen sizes
- **Automatic theme generation** based on wallpaper colors

## 🤖 AI Integration

### Ollama Platform
- **Local AI models** running on your system
- **Interactive chat** with `ollama-chat` command
- **Model management** with `ollama-models` utility
- **Multiple model types**: General, coding, embedding, vision

### Model Selection
Choose from 14 different models across categories:
- **General Purpose**: Llama 3.2, Phi-4, Mistral, Qwen
- **Coding**: CodeGemma, Code Llama, DeepSeek Coder
- **Embedding**: Nomic Embed, MixedBread Embed
- **Specialized**: LLaVA (vision), Neural Chat

## 🖥️ Virtualization

### KVM/QEMU Setup
- **Hardware detection** (VT-x/AMD-V support)
- **Complete package installation** (QEMU, libvirt, virt-manager)
- **Network configuration** with default virtual network
- **User permissions** (libvirt and kvm groups)

### VM Management
- **GUI**: virt-manager for easy VM creation
- **CLI**: `vm-manager` utility for command-line operations
- **Automatic service setup** with proper permissions

## ⚡ Performance Optimization

### System Tuning
- **Kernel parameters**: SSD optimization, boot speed improvements
- **Sysctl configuration**: Memory, network, and I/O tuning
- **ZRAM setup**: Compressed RAM for better memory usage
- **I/O scheduler**: Automatic selection based on storage type

### Monitoring
- **System monitor**: `system-monitor` command for performance tracking
- **Resource optimization**: Based on detected hardware
- **Safe defaults**: All changes backed up automatically

## 📁 Directory Structure

```
newinst/
├── 00-prerequisites.sh           # System validation & yay
├── 01-setup-chaotic-aur.sh      # Chaotic-AUR repository
├── 02-install-packages.sh       # Package installation
├── 03-deploy-dotfiles.sh        # Configuration deployment
├── 04-setup-theming.sh          # Dynamic theming
├── 05-setup-external-drives.sh  # Drive management
├── 06-setup-brave-backup.sh     # Browser backup/restore
├── 07-setup-ollama.sh           # AI platform setup
├── 08-setup-virt-manager.sh     # Virtualization
├── 09-system-optimization.sh    # Performance tuning
├── 10-user-setup.sh             # Final environment setup
├── README.md                     # This file
├── DEVLOG.md                     # Development log
└── *.txt                         # Package lists for reference
```

## 🔄 Recent Updates

### Version 2.0 (Latest)
- ✅ **Fixed iptables conflict** in virtualization setup
- ✅ **Added AI model selection menu** with descriptions and sizes
- ✅ **Improved network activation** for virtualization
- ✅ **Fixed hostname detection** without external dependencies
- ✅ **Enhanced error handling** across all scripts
- ✅ **Added comprehensive logging** for troubleshooting

### Key Improvements
- **Conflict resolution**: Automatic handling of package conflicts
- **User experience**: Better prompts, clearer instructions
- **Reliability**: More robust error handling and recovery
- **Documentation**: Comprehensive help and examples

## 🤝 Contributing

### Reporting Issues
- Check logs in `~/dotfiles/logs/` first
- Include system information (OS, kernel, hardware)
- Provide specific error messages and steps to reproduce

### Customization
- Edit package arrays directly in scripts
- Modify configuration templates in `../matugen/templates/`
- Add custom optimizations to system scripts

## 📜 License

This project is licensed under the MIT License - see the main repository for details.

## 🙏 Acknowledgments

- **Hyprland community** for the amazing window manager
- **Arch Linux** for the rolling release model
- **AUR maintainers** for package availability
- **Open source contributors** for all the tools and themes

---

**🎉 Ready to transform your Arch Linux system? Start with `./00-prerequisites.sh` and enjoy the journey!** 