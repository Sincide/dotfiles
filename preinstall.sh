#!/bin/bash
set -e

echo "==> Installing base dependencies for Python installer..."

sudo pacman -Sy --noconfirm python python-pip git make gcc python-rich

if ! command -v yay &>/dev/null; then
    echo "==> Installing yay-bin (AUR helper)..."
    cd /tmp
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd ..
    rm -rf yay-bin
fi

if ! pacman -Q python-questionary &>/dev/null; then
    yay -S --noconfirm python-questionary
fi

echo "==> All dependencies installed. Launching the Python installer..."

if command -v python3 &>/dev/null; then
    PYTHON=python3
else
    PYTHON=python
fi

$PYTHON install.py "$@"
