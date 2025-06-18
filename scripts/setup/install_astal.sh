#!/bin/bash

# Astal (Aylur's GTK Shell) Installation Script
# This script handles the installation and basic configuration of Astal

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

# Configuration
ASTAL_PKG="aylurs-gtk-shell"
LOG_FILE="/tmp/astal-install-$(date +%Y%m%d_%H%M%S).log"

# Logging functions
print_status()    { echo -e "${BLUE}[*]${NC} $1"; }
print_success()   { echo -e "${GREEN}[✓]${NC} $1"; }
print_error()     { echo -e "${RED}[✗]${NC} $1"; exit 1; }
print_warning()   { echo -e "${YELLOW}[!]${NC} $1"; }

log() {
    local timestamp
    timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[$timestamp] $1${NC}"
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Confirm action with user
confirm() {
    local prompt default response
    prompt="$1"
    default="${2:-y}"  # Default to 'y' if not provided
    
    # Set the prompt
    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n] "
    else
        prompt="$prompt [y/N] "
    fi
    
    # Read the response
    read -r -p "$prompt" response
    
    # Set default if empty
    [ -z "$response" ] && response="$default"
    
    # Convert to lowercase and check
    case "${response,,}" in
        y|yes) return 0 ;;
        *) return 1 ;;
    esac
}

# Check if running as root
check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
    fi
}

# Check system requirements and compatibility
check_requirements() {
    log "Checking system requirements for Astal..."
    
    # 1. Check for required commands
    local required_commands=("yay" "git")
    local recommended_commands=("node" "sassc" "typescript" "esbuild")
    
    # Check required commands
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            print_error "Required command '$cmd' is not installed."
        fi
    done
    
    # Check recommended commands
    local missing_commands=()
    for cmd in "${recommended_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        print_warning "Recommended build tools missing: ${missing_commands[*]}"
        if ! confirm "Continue without recommended tools?" "y"; then
            print_error "Installation aborted. Please install missing tools first."
        fi
    fi
    
    # 2. Check for Wayland session
    if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_SESSION_TYPE" != "wayland" ]; then
        print_warning "Astal works best on Wayland. You're currently not in a Wayland session."
        if ! confirm "Continue with installation anyway?" "n"; then
            print_error "Installation aborted. Please switch to a Wayland session."
        fi
    fi
    
    # 3. Check for required libraries
    local required_libs=("gtk4" "libadwaita-1" "gjs")
    local missing_libs=()
    
    for lib in "${required_libs[@]}"; do
        if ! pkg-config --exists "$lib" 2>/dev/null; then
            missing_libs+=("$lib")
        fi
    done
    
    if [ ${#missing_libs[@]} -gt 0 ]; then
        print_warning "Missing required libraries: ${missing_libs[*]}"
        if confirm "Install missing libraries now?" "y"; then
            log "Installing required libraries..."
            if ! yay -S --needed --noconfirm "${missing_libs[@]}"; then
                print_error "Failed to install required libraries"
            fi
        else
            print_error "Installation aborted. Required libraries are missing."
        fi
    fi
    
    print_success "System requirements check completed"
}

# Install Astal package
install_astal() {
    log "Installing $ASTAL_PKG from AUR..."
    if yay -S --needed --noconfirm "$ASTAL_PKG"; then
        print_success "Successfully installed $ASTAL_PKG"
    else
        print_error "Failed to install $ASTAL_PKG"
    fi
}

# Create basic Astal configuration
setup_config() {
    local config_dir="$HOME/.config/ags"
    local config_file="$config_dir/app.ts"
    local styles_dir="$config_dir/styles"
    
    log "Setting up Astal configuration..."
    
    # Create config directory if it doesn't exist
    mkdir -p "$config_dir"
    mkdir -p "$styles_dir"
    
    # Create basic config file if it doesn't exist
    if [[ ! -f "$config_file" ]]; then
        log "Creating default configuration..."
        
        # Create main app.ts
        cat > "$config_file" << 'EOL'
// Astal Configuration
// This is a basic TypeScript configuration file for Astal

import { App } from 'resource:///com/github/Aylur/ags/app.js';
import { Widget } from 'resource:///com/github/Aylur/ags/widget.js';

// Import styles
import './styles/main.scss';

// Define your widgets
function Bar(monitor = 0) {
    return Widget.Window({
        name: `bar-${monitor}`,
        className: 'bar',
        monitor,
        anchor: ['top', 'left', 'right'],
        child: Widget.CenterBox({
            className: 'bar-content',
            startWidget: Widget.Label({
                className: 'clock',
                label: 'Welcome to Astal!',
            }),
            centerWidget: Widget.Box({}),
            endWidget: Widget.Box({
                children: [
                    Widget.Label({
                        className: 'workspaces',
                        label: '1 2 3 4 5',
                    }),
                    Widget.Label({
                        className: 'tray',
                        label: 'Tray',
                    }),
                ],
            }),
        }),
    });
}

// Initialize the application
App.config({
    style: './styles/main.scss',
    windows: [
        Bar(0), // Create bar for primary monitor
        // Add more windows/widgets here
    ],
});

export {};
EOL
        print_success "Created default configuration at $config_file"
        
        # Create SCSS styles
        cat > "$styles_dir/main.scss" << 'EOL'
// Main styles for Astal

* {
    all: unset;
    font-family: 'JetBrainsMono Nerd Font';
    font-size: 14px;
}

.bar {
    background-color: rgba(30, 30, 46, 0.9);
    color: #cdd6f4;
    padding: 0 16px;
}

.bar-content {
    min-height: 40px;
}

.clock {
    font-weight: bold;
    color: #f5e0dc;
}

.workspaces {
    padding: 0 8px;
    background-color: rgba(255, 255, 255, 0.1);
    border-radius: 4px;
    margin: 0 4px;
}

.tray {
    padding: 0 8px;
    background-color: rgba(255, 255, 255, 0.1);
    border-radius: 4px;
    margin: 0 4px;
}
EOL
        print_success "Created default styles at $styles_dir/main.scss"
        
        # Create tsconfig.json for TypeScript
        cat > "$config_dir/tsconfig.json" << 'EOL'
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "node",
    "esModuleInterop": true,
    "strict": true,
    "skipLibCheck": true,
    "jsx": "react-jsx",
    "jsxImportSource": "resource:///com/github/Aylur/ags",
    "baseUrl": ".",
    "paths": {
      "resource://*": ["node_modules/types-ags/*"]
    }
  },
  "include": ["**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules"]
}
EOL
        print_success "Created TypeScript configuration at $config_dir/tsconfig.json"
        
        # Create package.json for TypeScript support
        cat > "$config_dir/package.json" << 'EOL'
{
  "name": "ags-config",
  "version": "1.0.0",
  "description": "AGS Configuration for Astal",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "watch": "tsc --watch"
  },
  "dependencies": {
    "@girs/gobject-2.0": "^1.0.0",
    "@girs/gtk-3.0": "^1.0.0",
    "@girs/gtk-4.0": "^1.0.0",
    "@girs/gtk-3.0-ambient": "^1.0.0",
    "@girs/gtk-4.0-ambient": "^1.0.0",
    "@girs/gdk-3.0": "^1.0.0",
    "@girs/gdk-4.0": "^1.0.0",
    "@girs/gdkpixbuf-2.0": "^1.0.0",
    "@girs/glib-2.0": "^1.0.0",
    "@girs/gio-2.0": "^1.0.0",
    "@girs/graphene-1.0": "^1.0.0",
    "@girs/harfbuzz-0.0": "^0.0.0",
    "@girs/pango-1.0": "^1.0.0",
    "@girs/cairo-1.0": "^1.0.0",
    "@girs/atk-1.0": "^1.0.0",
    "@girs/graphene-1.0-ambient": "^1.0.0",
    "@girs/harfbuzz-0.0-ambient": "^0.0.0",
    "@girs/pango-1.0-ambient": "^1.0.0",
    "@girs/cairo-1.0-ambient": "^1.0.0",
    "@girs/atk-1.0-ambient": "^1.0.0",
    "@girs/glib-2.0-ambient": "^1.0.0",
    "@girs/gio-2.0-ambient": "^1.0.0",
    "@girs/gobject-2.0-ambient": "^1.0.0",
    "@girs/gdk-3.0-ambient": "^1.0.0",
    "@girs/gdk-4.0-ambient": "^1.0.0",
    "@girs/gdkpixbuf-2.0-ambient": "^1.0.0",
    "typescript": "^5.0.0",
    "sass": "^1.62.0",
    "esbuild": "^0.17.0"
  }
}
EOL
        print_success "Created package.json for TypeScript support"
        
        # Create a simple README
        cat > "$config_dir/README.md" << 'EOL'
# Astal Configuration

This directory contains the configuration for Astal, a GTK-based shell for Wayland.

## Development

1. Install dependencies:
   ```bash
   npm install
   ```

2. Build the TypeScript files:
   ```bash
   npm run build
   ```

3. Run Astal with your configuration:
   ```bash
   ags -c app.ts
   ```

## File Structure

- `app.ts` - Main configuration file
- `styles/` - SCSS styles for theming
- `tsconfig.json` - TypeScript configuration
- `package.json` - Project dependencies and scripts

## Documentation

- [Astal Documentation](https://aylur.github.io/astal/)
- [TypeScript Guide](https://aylur.github.io/astal/guide/typescript/)
- [Widget Reference](https://aylur.github.io/libastal/)
EOL
        print_success "Created README.md with usage instructions"
        
    else
        print_warning "Configuration file already exists at $config_file"
    fi
}

# Main function
main() {
    log "Starting Astal installation..."
    
    # Check prerequisites
    check_root
    
    # Check system requirements and install dependencies
    check_requirements
    
    # Install Astal
    install_astal
    
    # Setup configuration
    setup_config
    
    # Print completion message
    echo -e "\n${GREEN}Astal (Aylur's GTK Shell) installation completed successfully!${NC}"
    echo -e "\n${YELLOW}Next steps:${NC}"
    echo "1. Log out and log back in to ensure all components are properly loaded"
    echo "2. Configure Astal by editing ~/.config/ags/app.ts"
    echo '3. Run "ags --run-js \"console.log(\'"'"'Hello from AGS!'"'"')\"" to test the configuration'
    echo "4. Add 'ags &' to your Hyprland autostart to launch Astal on login"
    echo -e "\n${YELLOW}Log file: $LOG_FILE${NC}"
}

# Run main function
main "$@"
