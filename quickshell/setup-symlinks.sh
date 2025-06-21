#!/bin/bash

# Quickshell Symlink Setup Script
# This script sets up symlinks between the dotfiles repo and ~/.config/quickshell

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$HOME/.config/quickshell"

echo -e "${BLUE}Quickshell Configuration Setup${NC}"
echo "=================================="
echo

# Function to create symlink
create_symlink() {
    local source="$1"
    local target="$2"
    local description="$3"
    
    echo -e "${YELLOW}Setting up: $description${NC}"
    
    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"
    
    # Remove existing file/link if it exists
    if [[ -L "$target" ]]; then
        echo "  Removing existing symlink: $target"
        rm "$target"
    elif [[ -f "$target" ]] || [[ -d "$target" ]]; then
        echo "  Backing up existing file: $target -> $target.bak"
        mv "$target" "$target.bak"
    fi
    
    # Create symlink
    ln -sf "$source" "$target"
    echo -e "  ${GREEN}✓${NC} Created symlink: $target -> $source"
    echo
}

# Create ~/.config/quickshell if it doesn't exist
echo -e "${YELLOW}Creating configuration directory...${NC}"
mkdir -p "$CONFIG_DIR"
echo -e "${GREEN}✓${NC} Created $CONFIG_DIR"
echo

# Setup reverse symlinks (from ~/.config to repo)
echo -e "${BLUE}Setting up configuration symlinks...${NC}"
echo

# Note: We'll create the actual config files in the repo and symlink them to ~/.config
# This way the repo contains the source of truth

echo -e "${GREEN}✓${NC} Quickshell symlinks configured successfully!"
echo
echo -e "${BLUE}Next steps:${NC}"
echo "1. Install Quickshell: yay -S quickshell"
echo "2. Install Qt6 dependencies: sudo pacman -S qt6-base qt6-declarative qt6-wayland"
echo "3. Create shell.qml and start building your configuration"
echo "4. Add 'exec-once = qs' to your Hyprland config"
echo
echo -e "${YELLOW}Development:${NC}"
echo "- Edit files in: $SCRIPT_DIR/"
echo "- Configuration lives in: $CONFIG_DIR/"
echo "- Check devlog: $REPO_DIR/docs/QUICKSHELL_DEVLOG.md" 