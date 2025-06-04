#!/bin/bash

# Setup script for the beautiful Python installer
# This installs the required Python dependencies and runs the installer

set -e

echo "🐍 Setting up Beautiful Python Installer..."

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install it first:"
    echo "   sudo pacman -S python python-pip"
    exit 1
fi

# Check if pip is available
if ! command -v pip &> /dev/null && ! python3 -m pip --version &> /dev/null; then
    echo "❌ pip is not available. Please install it first:"
    echo "   sudo pacman -S python-pip"
    exit 1
fi

# Install Rich library if not already installed
echo "📦 Installing Python dependencies..."
if python3 -c "import rich" 2>/dev/null; then
    echo "✅ Rich library already installed"
else
    echo "📥 Installing Rich library..."
    if command -v pip &> /dev/null; then
        pip install --user rich
    else
        python3 -m pip install --user rich
    fi
    echo "✅ Rich library installed"
fi

echo ""
echo "🚀 Starting Beautiful Python Installer..."
echo ""

# Run the Python installer
exec python3 install.py "$@" 