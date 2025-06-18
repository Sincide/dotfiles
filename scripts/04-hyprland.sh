#!/bin/bash

set -euo pipefail

LOGFILE="$HOME/install.log"

log() {
    echo -e "[*] $1" | tee -a "$LOGFILE"
}

ascii_art() {
cat << "EOF"

 _    _                           _           
| |  | |                         | |          
| |__| | ___ _ __ ___   ___ _ __ | |_ ___ _ __ 
|  __  |/ _ \ '_ ` _ \ / _ \ '_ \| __/ _ \ '__|
| |  | |  __/ | | | | |  __/ | | | ||  __/ |   
|_|  |_|\___|_| |_| |_|\___|_| |_|\__\___|_|   

     💻 HYPRLAND MINIMAL CONFIG MODULE

EOF
}

ascii_art

HYPRDIR="$HOME/.config/hypr"
#mkdir -p "$HYPRDIR"

log "Writing minimal Hyprland config..."

cat > "$HYPRDIR/hyprland.conf" <<EOF
# === Hyprland Minimal Config ===

# Monitor layout (example)
monitor=DP-3,2560x1440@119.998,2560x0,1
monitor=DP-1,5120x1440@165.0,0x1440,1
monitor=HDMI-A-1,2560x1440@120.03,0x0,1

# Keyboard layout
input {
  kb_layout = se
}

# Autostart swww (wallpaper daemon)
exec-once = swww init

# Keybindings
bind = SUPER, RETURN, exec, kitty
bind = SUPER, Q, killactive,
bind = SUPER, E, exec, thunar
bind = SUPER, D, exec, fuzzel

# Basic animations
animations {
  enabled = yes
}

# Gaps & Borders
general {
  gaps_in = 5
  gaps_out = 10
  border_size = 2
  col.active_border = rgba(ffffffaa)
  col.inactive_border = rgba(000000aa)
}

# Background color fallback
misc {
  disable_hyprland_logo = true
  vfr = true
}

# Optional dynamic theming (disabled for now)
# exec-once = matugen --apply dark
EOF

log "✅ Hyprland config written to $HYPRDIR/hyprland.conf"
