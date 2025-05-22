#!/bin/bash
set -e

echo "==> Installing base dependencies for Python installer..."

sudo pacman -Sy --noconfirm python python-pip git make gcc

pip install --user --upgrade pip
pip install --user rich questionary

if ! command -v yay &>/dev/null; then
    echo "==> Installing yay-bin (AUR helper)..."
    cd /tmp
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd ..
    rm -rf yay-bin
fi

echo "==> All dependencies installed. Launching the Python installer..."

if command -v python3 &>/dev/null; then
    PYTHON=python3
else
    PYTHON=python
fi

$PYTHON install.py "$@"
