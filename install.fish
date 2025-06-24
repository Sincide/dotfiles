#!/usr/bin/env fish

# Fish Shell Wrapper for Evil Space Dotfiles Installation
# This provides Fish-friendly commands for testing the bash installer

function install-dotfiles
    bash ./install.sh $argv
end

function install-test
    bash ./install.sh --dry-run $argv
end

function install-status
    bash ./install.sh --status
end

function install-help
    bash ./install.sh --help
end

# Set up convenient functions
if test (count $argv) -eq 0
    echo "🐟 Fish Shell Wrapper for Evil Space Dotfiles Installation"
    echo ""
    echo "Available commands:"
    echo "  install-dotfiles [OPTIONS]  - Run the installer with options"
    echo "  install-test [OPTIONS]      - Run installer in dry-run mode"
    echo "  install-status              - Show installation status"
    echo "  install-help                - Show help information"
    echo ""
    echo "Examples:"
    echo "  install-test                # Test installation"
    echo "  install-dotfiles --complete # Full installation"
    echo "  install-status              # Check progress"
    echo ""
    echo "Or run directly: bash ./install.sh [OPTIONS]"
else
    # Pass all arguments to the bash installer
    bash ./install.sh $argv
end