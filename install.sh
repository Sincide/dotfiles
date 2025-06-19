#!/bin/bash

# Simple launcher for the comprehensive dotfiles installer
# This script provides easy access to the full installation system

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$SCRIPT_DIR/scripts/setup/dotfiles-installer.sh"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}              ${GREEN}Martin's Dotfiles Installer${NC}                 ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "${YELLOW}Starting comprehensive Arch Linux + Hyprland installation...${NC}"
echo

# Check if installer exists
if [[ ! -f "$INSTALLER" ]]; then
    echo -e "${RED}Error: Installer not found at $INSTALLER${NC}"
    exit 1
fi

# Make sure installer is executable
chmod +x "$INSTALLER"

# Run the installer
exec "$INSTALLER" "$@" 