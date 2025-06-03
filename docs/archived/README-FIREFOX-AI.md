# 🤖 Firefox AI Dynamic Colors Extension

Real-time AI-optimized color themes from your wallpaper!
**Customized for Martin's ~/dotfiles setup** 🔥

## 🚀 Quick Start

### 1. Install Extension (from ~/dotfiles)
1. Open Firefox
2. Go to `about:debugging`
3. Click "This Firefox" → "Load Temporary Add-on"
4. Select `~/dotfiles/firefox-ai-extension/manifest.json`

### 2. Enable userChrome.css
1. Go to `about:config`
2. Search for `toolkit.legacyUserProfileCustomizations.stylesheets`
3. Set to `true`

### 3. Start Color Server
```bash
cd ~/dotfiles
python3 local-color-server.py
```

### 4. Test Integration
```bash
# Use your wallpaper-selector.sh as usual
./scripts/wallpaper-selector.sh assets/wallpapers/dark/evilpuccin.png

# Firefox gets new colors automatically! ✨
```

## 🎨 How It Integrates

Your existing workflow:
```bash
wallpaper-selector.sh → ai-color-pipeline.sh → themes updated
```

Now becomes:
```bash
wallpaper-selector.sh → ai-color-pipeline.sh → themes + Firefox updated
                                           ↓
                                    firefox-css-generator.sh
                                           ↓
                                    Extension auto-updates
```

## 🔧 Real-time Workflow

```bash
# Start monitoring (runs in background)
./scripts/ai/realtime-firefox-integration.sh &

# Now ANY wallpaper change automatically updates Firefox!
./scripts/wallpaper-selector.sh assets/wallpapers/space/nebula.jpg
# → Firefox gets new colors within 3 seconds! 🔥
```

## 🎯 Features

- ✅ **Real-time Updates**: No Firefox restart needed
- ✅ **AI Harmony Analysis**: Mathematically optimized colors
- ✅ **WCAG AAA Compliance**: Perfect accessibility
- ✅ **Site-Specific Rules**: Enhanced styling for popular sites
- ✅ **Performance Monitoring**: Built-in metrics
- ✅ **Seamless Integration**: Works with your existing pipeline

Happy theming with your epic dotfiles setup! 🎨✨
