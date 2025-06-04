#!/bin/bash

# Setup script for the beautiful Python installer
# This installs the required Python dependencies via pacman and runs the installer

set -e

echo "🐍 Setting up Beautiful Python Installer..."

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please do not run as root"
    exit 1
fi

# Install Python and python-rich via pacman
echo "📦 Installing Python dependencies via pacman..."
if ! command -v python3 &> /dev/null || ! python3 -c "import rich" 2>/dev/null; then
    echo "📥 Installing python and python-rich..."
    sudo pacman -S --needed --noconfirm python python-rich
    echo "✅ Python and Rich library installed via pacman"
else
    echo "✅ Python and Rich library already available"
fi

echo ""
echo "🚀 Starting Beautiful Python Installer..."
echo ""

# Run the Python installer
exec python3 install.py "$@" 