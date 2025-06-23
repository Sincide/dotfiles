# Technical Implementation Guide
## Detailed Code Changes and Implementation Specifications

---

## Critical Security Fixes (Immediate Priority)

### 1. Screen Lock Security Enhancement

**File:** `hypr/conf/keybinds.conf`

```bash
# BEFORE (Security Issue):
bind = $mainMod, L, exec, hyprctl dispatch dpms off

# AFTER (Secure):
bind = $mainMod, L, exec, swaylock && hyprctl dispatch dpms off
```

**Additional Security Setup:**
- Install swaylock: `sudo pacman -S swaylock`
- Configure swaylock in `~/.config/swaylock/config`
- Test lock functionality before deployment

### 2. GPU Monitoring Script Hardening

**File:** `scripts/theming/gpu_*.sh`

**Create Dynamic GPU Detection:**
```bash
#!/usr/bin/env bash
# Function to detect AMD GPU card dynamically
detect_amd_card() {
    for card in /sys/class/drm/card*; do
        if [[ -f "$card/device/vendor" ]]; then
            vendor=$(cat "$card/device/vendor" 2>/dev/null)
            if [[ "$vendor" == "0x1002" ]]; then  # AMD vendor ID
                echo "${card##*/}"
                return 0
            fi
        fi
    done
    return 1
}

# Usage in scripts:
AMD_CARD=$(detect_amd_card)
if [[ -n "$AMD_CARD" ]]; then
    HWMON_PATH="/sys/class/drm/$AMD_CARD/device/hwmon"
else
    echo "No AMD GPU detected"
    exit 1
fi
```

### 3. Fish Shell Conflict Resolution

**File:** `fish/config.fish`

**Audit and Fix Aliases/Abbreviations:**
```fish
# Remove duplicate definitions - keep only abbreviations for interactive use
# BEFORE (duplicated):
alias gst='git status --short'
abbr -a gst 'git status --short'

# AFTER (unified):
abbr -a gst 'git status --short'  # Keep abbreviation only
```

**Fix Color Variable:**
```fish
# BEFORE:
set -u fish_color_option

# AFTER:
set -U fish_color_option
```

---

## Unified Theme Architecture

### 1. Core Theme Structure

**Create:** `themes/EvilSpace-Dynamic-Unified/`

```css
/* gtk-3.0/gtk.css */
@import url("colors.css");

/* Use dynamic color variables throughout */
.window {
    background-color: @surface_color;
    color: @on_surface_color;
}

.button {
    background-color: @primary_color;
    color: @on_primary_color;
}

/* Ensure all widgets use dynamic variables */
```

### 2. Enhanced Matugen Template System

**File:** `matugen/templates/gtk-unified.template`

```css
/* Dynamic color definitions for unified theme */
@define-color primary_color {{colors.primary.default.hex}};
@define-color on_primary_color {{colors.on_primary.default.hex}};
@define-color secondary_color {{colors.secondary.default.hex}};
@define-color on_secondary_color {{colors.on_secondary.default.hex}};
@define-color surface_color {{colors.surface.default.hex}};
@define-color on_surface_color {{colors.on_surface.default.hex}};
@define-color background_color {{colors.background.default.hex}};
@define-color on_background_color {{colors.on_background.default.hex}};
@define-color outline_color {{colors.outline.default.hex}};
@define-color accent_color {{colors.primary.default.hex}};
```

---

## Central Theme Controller Implementation

### 1. Main Theme Controller Script

**Create:** `scripts/theming/theme_controller.sh`

```bash
#!/usr/bin/env bash
# Central theme management system

set -euo pipefail

# Configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CACHE_DIR="$HOME/.cache/dotfiles"
LOG_FILE="$CACHE_DIR/theme.log"
CONFIG_FILE="$HOME/.config/dynamic-themes.conf"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Category detection with enhanced logic
detect_category() {
    local wallpaper="$1"
    local filename=$(basename "$wallpaper")
    
    case "$filename" in
        *space*|*nebula*|*galaxy*) echo "space" ;;
        *nature*|*forest*|*mountain*) echo "nature" ;;
        *gaming*|*neon*|*cyber*) echo "gaming" ;;
        *minimal*|*simple*|*clean*) echo "minimal" ;;
        *dark*) echo "dark" ;;
        *abstract*) echo "abstract" ;;
        *) echo "minimal" ;;  # Safe fallback
    esac
}

# Enhanced palette generation
generate_palette() {
    local wallpaper="$1"
    local category="$2"
    
    log "Generating palette for category: $category"
    
    # Check if light mode should be used for this category
    local light_mode="false"
    [[ "$category" == "minimal" ]] && light_mode="true"
    
    # Update matugen config for light/dark mode
    if [[ "$light_mode" == "true" ]]; then
        sed -i 's/mode = "dark"/mode = "light"/' "$DOTFILES_DIR/matugen/config.toml"
    else
        sed -i 's/mode = "light"/mode = "dark"/' "$DOTFILES_DIR/matugen/config.toml"
    fi
    
    # Generate palette
    if ! matugen image "$wallpaper"; then
        log "ERROR: Palette generation failed, using fallback"
        return 1
    fi
    
    log "Palette generated successfully"
    return 0
}

# Apply unified theme
apply_unified_theme() {
    local category="$1"
    
    # Always use the unified dynamic theme
    local gtk_theme="EvilSpace-Dynamic-Unified"
    
    # Apply category-specific icons and cursors
    apply_category_assets "$category"
    
    # Set GTK theme
    gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
    
    # Set color scheme based on category
    if [[ "$category" == "minimal" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'default'
    else
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    fi
    
    # Apply via nwg-look if available
    if command -v nwg-look >/dev/null 2>&1; then
        nwg-look -x  # Export to config files
        nwg-look -a  # Apply theme
        log "Theme applied via nwg-look"
    fi
}

# Enhanced GTK refresh sequence (inspired by linkfrg)
refresh_gtk_apps() {
    log "Refreshing GTK applications with enhanced sequence"
    
    # Multi-stage refresh for better compatibility
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
    sleep 0.5
    gsettings set org.gnome.desktop.interface gtk-theme "$1"
    sleep 0.5
    
    # Color scheme toggle for libadwaita apps
    local current_scheme=$(gsettings get org.gnome.desktop.interface color-scheme)
    gsettings set org.gnome.desktop.interface color-scheme 'default'
    sleep 0.5
    gsettings set org.gnome.desktop.interface color-scheme "$current_scheme"
    
    log "GTK refresh sequence completed"
}

# Main theme application function
apply_theme() {
    local wallpaper="$1"
    
    log "Starting theme application for: $wallpaper"
    
    # Detect category
    local category=$(detect_category "$wallpaper")
    log "Detected category: $category"
    
    # Generate palette
    if ! generate_palette "$wallpaper" "$category"; then
        log "Using fallback theme application"
        apply_fallback_theme "$category"
        return 1
    fi
    
    # Apply unified theme
    apply_unified_theme "$category"
    
    # Refresh applications
    refresh_all_applications "$category"
    
    # Send notification
    notify-send "Theme Updated" "Applied $category theme from wallpaper" -i preferences-desktop-theme
    
    log "Theme application completed successfully"
}

# Main entry point
main() {
    case "${1:-}" in
        apply)
            apply_theme "$2"
            ;;
        *)
            echo "Usage: $0 apply <wallpaper_path>"
            exit 1
            ;;
    esac
}

main "$@"
```

---

## Application Integration Enhancements

### 1. Enhanced Waybar Integration

**Update:** `matugen/templates/waybar.template`

```css
/* Enhanced Waybar theming with Material You colors */
* {
    border: none;
    border-radius: 0;
    font-family: "Noto Sans", "Font Awesome 6 Free";
    font-size: 13px;
    min-height: 0;
}

window#waybar {
    background-color: {{colors.surface.default.hex}};
    color: {{colors.on_surface.default.hex}};
    transition: background-color 0.3s ease;
}

.modules-left,
.modules-center,
.modules-right {
    background-color: {{colors.surface_variant.default.hex}};
    border-radius: 12px;
    margin: 4px;
    padding: 0 12px;
}

#clock {
    color: {{colors.primary.default.hex}};
    font-weight: bold;
}

#workspaces button.active {
    background-color: {{colors.primary.default.hex}};
    color: {{colors.on_primary.default.hex}};
}
```

### 2. Kitty Terminal Integration

**Update:** `matugen/templates/kitty.template`

```ini
# Dynamic Kitty color scheme
foreground              {{colors.on_background.default.hex}}
background              {{colors.background.default.hex}}
selection_foreground    {{colors.on_primary.default.hex}}
selection_background    {{colors.primary.default.hex}}

# Cursor colors
cursor                  {{colors.primary.default.hex}}
cursor_text_color       {{colors.on_primary.default.hex}}

# URL underline color when hovering with mouse
url_color               {{colors.secondary.default.hex}}

# Border colors
active_border_color     {{colors.primary.default.hex}}
inactive_border_color   {{colors.outline.default.hex}}
```

---

## Enhanced Category System

### 1. Category Configuration

**Update:** `scripts/theming/dynamic-themes.conf`

```toml
# Enhanced category configuration with light/dark support

[categories.space]
gtk_theme_variant = "dark"
icon_theme = "Papirus-Dark"
cursor_theme = "Bibata-Modern-Ice"
palette_bias = "vibrant"

[categories.nature]
gtk_theme_variant = "dark"
icon_theme = "Tela-circle-green"
cursor_theme = "Adwaita"
palette_bias = "natural"

[categories.gaming]
gtk_theme_variant = "dark"
icon_theme = "Papirus-Dark"
cursor_theme = "Bibata-Modern-Classic"
palette_bias = "vibrant"

[categories.minimal]
gtk_theme_variant = "light"
icon_theme = "WhiteSur"
cursor_theme = "Adwaita"
palette_bias = "muted"

[categories.dark]
gtk_theme_variant = "dark"
icon_theme = "Papirus-Dark"
cursor_theme = "Bibata-Modern-Ice"
palette_bias = "standard"

[categories.abstract]
gtk_theme_variant = "dark"
icon_theme = "Papirus-Dark"
cursor_theme = "Bibata-Modern-Ice"
palette_bias = "vibrant"
```

---

## Testing and Validation Framework

### 1. Theme Validation Script

**Create:** `scripts/testing/validate_theme.sh`

```bash
#!/usr/bin/env bash
# Theme validation and testing framework

validate_gtk_theme() {
    local theme_name="$1"
    local theme_path="$HOME/.themes/$theme_name"
    
    if [[ ! -d "$theme_path" ]]; then
        echo "ERROR: Theme directory not found: $theme_path"
        return 1
    fi
    
    if [[ ! -f "$theme_path/gtk-3.0/gtk.css" ]]; then
        echo "ERROR: GTK3 theme CSS missing"
        return 1
    fi
    
    if [[ ! -f "$theme_path/gtk-4.0/gtk.css" ]]; then
        echo "ERROR: GTK4 theme CSS missing"
        return 1
    fi
    
    echo "Theme validation passed: $theme_name"
    return 0
}

validate_color_variables() {
    local colors_file="$1"
    
    required_vars=(
        "primary_color"
        "on_primary_color"
        "secondary_color"
        "surface_color"
        "background_color"
    )
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "@define-color $var" "$colors_file"; then
            echo "ERROR: Missing color variable: $var"
            return 1
        fi
    done
    
    echo "Color variables validation passed"
    return 0
}

test_application_theming() {
    echo "Testing application theming..."
    
    # Test GTK3 apps
    if command -v gtk3-demo >/dev/null 2>&1; then
        echo "GTK3 demo available for testing"
    fi
    
    # Test GTK4 apps  
    if command -v gtk4-demo >/dev/null 2>&1; then
        echo "GTK4 demo available for testing"
    fi
    
    # Test Waybar reload
    if pgrep waybar >/dev/null; then
        echo "Waybar is running - theme will apply"
    else
        echo "WARNING: Waybar not running"
    fi
}

main() {
    echo "=== Theme Validation Framework ==="
    
    validate_gtk_theme "EvilSpace-Dynamic-Unified"
    validate_color_variables "$HOME/.config/gtk-3.0/colors.css"
    test_application_theming
    
    echo "=== Validation Complete ==="
}

main "$@"
```

---

## Deployment and Rollback Scripts

### 1. Safe Deployment Script

**Create:** `scripts/deployment/deploy_unified_theme.sh`

```bash
#!/usr/bin/env bash
# Safe deployment script with rollback capability

BACKUP_DIR="$HOME/.config/dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

backup_current_config() {
    echo "Creating backup in: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    # Backup current theme configs
    cp -r "$HOME/.themes" "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "$HOME/.config/gtk-3.0" "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "$HOME/.config/gtk-4.0" "$BACKUP_DIR/" 2>/dev/null || true
    cp -r "$HOME/.config/waybar" "$BACKUP_DIR/" 2>/dev/null || true
    
    echo "Backup completed"
}

deploy_unified_theme() {
    echo "Deploying unified theme system..."
    
    # Deploy new theme files
    ln -sf "$DOTFILES_DIR/themes/EvilSpace-Dynamic-Unified" "$HOME/.themes/"
    
    # Update scripts
    chmod +x "$DOTFILES_DIR/scripts/theming/theme_controller.sh"
    
    # Test deployment
    if "$DOTFILES_DIR/scripts/testing/validate_theme.sh"; then
        echo "Deployment successful"
        return 0
    else
        echo "Deployment failed - initiating rollback"
        rollback_deployment
        return 1
    fi
}

rollback_deployment() {
    echo "Rolling back to previous configuration..."
    
    if [[ -d "$BACKUP_DIR" ]]; then
        cp -r "$BACKUP_DIR/.themes" "$HOME/" 2>/dev/null || true
        cp -r "$BACKUP_DIR/.config/gtk-3.0" "$HOME/.config/" 2>/dev/null || true
        cp -r "$BACKUP_DIR/.config/gtk-4.0" "$HOME/.config/" 2>/dev/null || true
        echo "Rollback completed"
    else
        echo "ERROR: Backup directory not found"
        return 1
    fi
}

main() {
    echo "=== Unified Theme Deployment ==="
    
    backup_current_config
    
    if deploy_unified_theme; then
        echo "Deployment successful! Backup saved to: $BACKUP_DIR"
    else
        echo "Deployment failed! System rolled back."
        exit 1
    fi
}

main "$@"
```

This technical implementation guide provides the specific code changes and implementation details needed to execute the migration plan while ensuring security and functionality preservation. 