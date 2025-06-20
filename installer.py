#!/usr/bin/env bash
# Wrapper script to launch the Python TUI dotfiles installer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="$SCRIPT_DIR/scripts/setup/python_installer/installer.py"

exec python3 "$INSTALLER" "$@" 