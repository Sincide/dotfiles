#!/bin/bash

# GPTDiag Installation Script for Arch Linux
# This script installs dependencies and sets up GPTDiag

set -e

echo "🚀 GPTDiag Installation Script for Arch Linux"
echo "=============================================="

# Check if we're on Arch Linux
if ! command -v pacman &> /dev/null; then
    echo "❌ Error: This script is designed for Arch Linux (pacman not found)"
    exit 1
fi

# Check if yay is installed
if ! command -v yay &> /dev/null; then
    echo "⚠️  Warning: yay AUR helper not found. Some packages may not be available."
    echo "   Install yay first: https://github.com/Jguer/yay"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "📦 Installing core dependencies via pacman..."

# Core packages available in official repos
PACMAN_PACKAGES=(
    "python"
    "python-rich"
    "python-psutil" 
    "python-aiohttp"
    "python-aiofiles"
    "python-click"
    "python-yaml"
    "python-dateutil"
    "python-tabulate"
)

# Check which packages are available
AVAILABLE_PACKAGES=()
for pkg in "${PACMAN_PACKAGES[@]}"; do
    if pacman -Si "$pkg" &>/dev/null; then
        AVAILABLE_PACKAGES+=("$pkg")
    else
        echo "⚠️  Package $pkg not available in official repos"
    fi
done

if [ ${#AVAILABLE_PACKAGES[@]} -gt 0 ]; then
    echo "Installing: ${AVAILABLE_PACKAGES[*]}"
    sudo pacman -S --needed "${AVAILABLE_PACKAGES[@]}"
else
    echo "❌ No packages available to install via pacman"
fi

# AUR packages
if command -v yay &> /dev/null; then
    echo "📦 Installing AUR dependencies via yay..."
    
    AUR_PACKAGES=(
        "python-textual"
        "python-plotext"
    )
    
    for pkg in "${AUR_PACKAGES[@]}"; do
        echo "Installing $pkg from AUR..."
        if yay -S --needed "$pkg"; then
            echo "✅ $pkg installed successfully"
        else
            echo "⚠️  Failed to install $pkg from AUR"
        fi
    done
fi

echo "🔧 Setting up GPTDiag..."

# Create config directories
mkdir -p ~/.config/gptdiag
mkdir -p ~/.local/share/gptdiag
mkdir -p ~/.cache/gptdiag

echo "🏗️  Installing GPTDiag..."

# Install the package
if python setup.py install --user; then
    echo "✅ GPTDiag installed successfully!"
else
    echo "❌ Failed to install GPTDiag"
    exit 1
fi

# Create symlink for easy access
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

if [ -f "$HOME/.local/lib/python*/site-packages/gptdiag" ]; then
    echo "Creating symlink..."
    ln -sf "$(python -c 'import gptdiag; print(gptdiag.__file__)')" "$INSTALL_DIR/gptdiag" 2>/dev/null || true
fi

# Alternative: direct execution script
cat > "$INSTALL_DIR/gptdiag" << 'EOF'
#!/bin/bash
cd "$(dirname "$(readlink -f "$0")")/../../../Apps/gptdiag"
python -m gptdiag.main "$@"
EOF

chmod +x "$INSTALL_DIR/gptdiag"

echo ""
echo "🎉 Installation completed!"
echo ""
echo "Usage:"
echo "  $INSTALL_DIR/gptdiag           # Launch main TUI"
echo "  $INSTALL_DIR/gptdiag --help    # Show help"
echo ""
echo "Make sure $INSTALL_DIR is in your PATH:"
echo "  echo 'export PATH=\$PATH:$INSTALL_DIR' >> ~/.bashrc"
echo "  # or for fish shell:"
echo "  echo 'set -gx PATH \$PATH $INSTALL_DIR' >> ~/.config/fish/config.fish"
echo ""
echo "You can also run directly:"
echo "  cd $(pwd)"
echo "  python -m gptdiag.main" 