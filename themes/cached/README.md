# Theme Cache Directory

This directory stores downloaded themes locally to avoid re-downloading them on fresh installations.

## Directory Structure

```
themes/cached/
├── gtk/          # GTK theme packages
├── icons/        # Icon theme packages  
├── cursors/      # Cursor theme packages
└── README.md     # This file
```

## How It Works

1. **First Installation**: Themes are downloaded from git repositories and cached here
2. **Subsequent Installations**: Themes are installed directly from cache (much faster)
3. **Offline Support**: Cached themes can be installed without internet connection

## Management Commands

```bash
# Cache all available git-based themes
./scripts/theming/theme_cache_manager.sh cache-all

# List cached themes
./scripts/theming/theme_cache_manager.sh list

# Install specific theme (from cache if available)
./scripts/theming/theme_cache_manager.sh install <theme_name>

# Clean cache (remove all cached themes)
./scripts/theming/theme_cache_manager.sh clean
```

## What Gets Cached

**Git-based themes** (downloaded and cached):
- ~~Nordic (GTK)~~ - **Deprecated** (replaced with Graphite-Dark)
- Orchis-Green-Dark (GTK) - **Active** (nature category)
- ~~Ultimate-Dark (GTK)~~ - **Deprecated** (replaced with Graphite-Dark)
- WhiteSur-Light (GTK) - **Active** (minimal category)
- Graphite-Dark (GTK) - **Primary** (space, gaming, dark categories)
- Tela-circle-green (Icons) - **Active** (nature category)
- WhiteSur (Icons) - **Active** (minimal category)
- ~~Qogir-dark (Icons)~~ - **Deprecated** (replaced with Papirus-Dark)

**AUR packages** (installed directly, not cached):
- ~~Yaru-Colors~~ - **Deprecated** (replaced with Graphite)
- Papirus/Papirus-Dark - **Primary** (most categories)
- ~~Numix-Circle~~ - **Deprecated** (replaced with Papirus)
- All Bibata cursor themes - **Primary** (hyprcursor support)
- Capitaine-Cursors - **Active** (minimal category)

## Benefits

- ⚡ **Faster installs**: Cached themes install in seconds
- 📦 **Offline capability**: No internet needed for cached themes
- 🔄 **Reliable**: No dependency on external git repositories being available
- 💾 **Space efficient**: Only downloads themes you actually use
- 🎯 **Portable**: Themes travel with your dotfiles

## Git Integration

The cache contents are ignored by git (see `.gitignore`) to avoid:
- Bloating the repository with large theme files
- Conflicts between different users' cached themes
- Version control issues with frequently-changing theme repositories

Only the directory structure (`.gitkeep` files) is tracked to ensure the cache system works immediately after cloning. 