#!/bin/bash

# Simple launcher for the Python installer
# Installs dependencies and runs the beautiful Python installer

set -e

echo "🐍 Python Dotfiles Installer"
echo

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please do not run as root"
    exit 1
fi

# Install Python and Rich if needed
if ! command -v python3 &> /dev/null || ! python3 -c "import rich" 2>/dev/null; then
    echo "📦 Installing Python dependencies..."
    sudo pacman -S --needed --noconfirm python python-rich
    echo "✅ Dependencies installed"
    echo
fi

# Run the Python installer
echo "🚀 Starting installer..."
echo
exec python3 install.py "$@" 