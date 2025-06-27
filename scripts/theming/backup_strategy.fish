#!/usr/bin/env fish
# Simplified Unified Theming Migration Backup Strategy
# Fixed for fish shell compatibility

set BACKUP_DATE (date '+%Y%m%d_%H%M%S')
# Find dotfiles root by looking for characteristic files
set SCRIPT_DIR (dirname (status --current-filename))
set DOTFILES_ROOT (cd $SCRIPT_DIR && cd ../../ && pwd)
set BACKUP_ROOT "$HOME/.dotfiles-backups"
set CURRENT_BACKUP "$BACKUP_ROOT/pre-unified-migration_$BACKUP_DATE"

echo "🔄 Starting backup strategy for unified theming migration"
echo "📁 Backup location: $CURRENT_BACKUP"

# Create backup directories
if not test -d $BACKUP_ROOT
    mkdir -p $BACKUP_ROOT
    echo "✅ Created backup root directory"
end

mkdir -p $CURRENT_BACKUP
mkdir -p $CURRENT_BACKUP/configs
mkdir -p $CURRENT_BACKUP/system_state
echo "✅ Created backup directories"

# Create migration branch and save Git state
echo "🔀 Backing up Git state..."
cd $DOTFILES_ROOT

if git branch | grep -q "linkfrg-migration"
    echo "⚠️  Branch 'linkfrg-migration' already exists"
else
    git checkout -b linkfrg-migration
    echo "✅ Created migration branch: linkfrg-migration"
end

# Save Git information
git rev-parse HEAD > "$CURRENT_BACKUP/current_commit.txt"
git status --porcelain > "$CURRENT_BACKUP/git_status.txt"
echo "✅ Saved Git state"

# Backup critical configurations
echo "📂 Backing up configurations..."

set critical_configs matugen gtk-3.0 gtk-4.0 waybar kitty dunst fish hypr fuzzel starship

for config in $critical_configs
    if test -d "$DOTFILES_ROOT/$config"
        cp -r "$DOTFILES_ROOT/$config" "$CURRENT_BACKUP/configs/"
        echo "✅ Backed up $config"
    else
        echo "⚠️  Directory not found: $config"
    end
end

# Backup themes and scripts
if test -d "$DOTFILES_ROOT/themes"
    cp -r "$DOTFILES_ROOT/themes" "$CURRENT_BACKUP/"
    echo "✅ Backed up themes"
end

if test -d "$DOTFILES_ROOT/scripts"
    cp -r "$DOTFILES_ROOT/scripts" "$CURRENT_BACKUP/"
    echo "✅ Backed up scripts"
end

# Backup system theme state
echo "🖥️  Backing up system theme state..."
gsettings get org.gnome.desktop.interface gtk-theme > "$CURRENT_BACKUP/system_state/gtk_theme.txt"
gsettings get org.gnome.desktop.interface icon-theme > "$CURRENT_BACKUP/system_state/icon_theme.txt"
gsettings get org.gnome.desktop.interface cursor-theme > "$CURRENT_BACKUP/system_state/cursor_theme.txt"
gsettings get org.gnome.desktop.interface color-scheme > "$CURRENT_BACKUP/system_state/color_scheme.txt"

if test -f "$HOME/.cache/swww/wallpaper"
    cp "$HOME/.cache/swww/wallpaper" "$CURRENT_BACKUP/system_state/current_wallpaper"
    echo "✅ Backed up current wallpaper"
end

if command -q hyprctl
    hyprctl monitors > "$CURRENT_BACKUP/system_state/hyprland_monitors.txt"
    hyprctl workspaces > "$CURRENT_BACKUP/system_state/hyprland_workspaces.txt"
    echo "✅ Backed up Hyprland state"
end

# Create emergency restoration script
echo "🚨 Creating emergency restoration script..."
set restore_script "$CURRENT_BACKUP/restore_emergency.fish"

printf '#!/usr/bin/env fish
# Emergency Restoration Script

set BACKUP_DIR (dirname (status --current-filename))
set DOTFILES_ROOT (cat "$BACKUP_DIR/dotfiles_path.txt")
set ORIGINAL_COMMIT (cat "$BACKUP_DIR/current_commit.txt")

echo "🚨 EMERGENCY RESTORATION INITIATED 🚨"
echo "This will restore your dotfiles to pre-migration state"
echo "Backup location: $BACKUP_DIR"
echo ""

read -P "Continue with restoration? [y/N] " -l confirm
if test "$confirm" != "y" -a "$confirm" != "Y"
    echo "Restoration cancelled"
    exit 1
end

echo "Starting restoration..."

# Restore Git state
cd $DOTFILES_ROOT
git checkout main
git reset --hard $ORIGINAL_COMMIT

# Restore configurations
cp -r "$BACKUP_DIR/configs/"* "$DOTFILES_ROOT/"

# Restore themes
if test -d "$BACKUP_DIR/themes"
    rm -rf "$DOTFILES_ROOT/themes"
    cp -r "$BACKUP_DIR/themes" "$DOTFILES_ROOT/"
end

# Restore scripts
if test -d "$BACKUP_DIR/scripts"
    rm -rf "$DOTFILES_ROOT/scripts"
    cp -r "$BACKUP_DIR/scripts" "$DOTFILES_ROOT/"
end

# Restore system theme state
gsettings set org.gnome.desktop.interface gtk-theme (cat "$BACKUP_DIR/system_state/gtk_theme.txt")
gsettings set org.gnome.desktop.interface icon-theme (cat "$BACKUP_DIR/system_state/icon_theme.txt")
gsettings set org.gnome.desktop.interface cursor-theme (cat "$BACKUP_DIR/system_state/cursor_theme.txt")
gsettings set org.gnome.desktop.interface color-scheme (cat "$BACKUP_DIR/system_state/color_scheme.txt")

echo "✅ Emergency restoration completed!"
echo "Your dotfiles have been restored to the pre-migration state"
' > "$restore_script"

chmod +x "$restore_script"
echo "$DOTFILES_ROOT" > "$CURRENT_BACKUP/dotfiles_path.txt"
echo "✅ Emergency restoration script created"

# Create symlink to latest backup
if test -L "$BACKUP_ROOT/latest"
    rm "$BACKUP_ROOT/latest"
end
ln -s "$CURRENT_BACKUP" "$BACKUP_ROOT/latest"

# Validation
set validation_errors 0

if not test -f "$CURRENT_BACKUP/current_commit.txt"
    echo "❌ Missing: current_commit.txt"
    set validation_errors (math $validation_errors + 1)
end

if not test -x "$CURRENT_BACKUP/restore_emergency.fish"
    echo "❌ Missing or not executable: restore_emergency.fish"
    set validation_errors (math $validation_errors + 1)
end

if not test -d "$CURRENT_BACKUP/configs"
    echo "❌ Missing: configs directory"
    set validation_errors (math $validation_errors + 1)
end

if test $validation_errors -eq 0
    echo ""
    echo "🎯 BACKUP STRATEGY COMPLETE ✅"
    echo "=================================="
    echo "📁 Backup Location: $CURRENT_BACKUP"
    echo "🔧 Emergency Restore: $CURRENT_BACKUP/restore_emergency.fish"
    echo "🌟 Git Branch: linkfrg-migration"
    echo ""
    echo "📋 NEXT STEPS:"
    echo "1. Verify backup location is accessible"
    echo "2. Test emergency restore script (optional)"
    echo "3. Continue with Phase 3: Unified Theme Development"
    echo ""
    echo "⚠️  CRITICAL: Keep this backup until migration is complete!"
    exit 0
else
    echo ""
    echo "❌ BACKUP FAILED - $validation_errors errors"
    echo "Please check the output above and try again"
    exit 1
end 