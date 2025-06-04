#!/bin/bash
# Minimal bootstrap script for Python dotfiles installer

echo "🐍 Installing Python prerequisites for dotfiles installer..."

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please do not run as root"
    exit 1
fi

# Install essential packages
sudo pacman -Syu --needed --noconfirm python git

echo "✅ Prerequisites installed! Starting dotfiles installer..."
echo

# Make the Python installer executable and run it
chmod +x dotfiles_installer.py
exec ./dotfiles_installer.py
