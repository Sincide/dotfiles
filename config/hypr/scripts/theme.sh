#!/bin/bash

# Set GTK Themes
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface gtk-theme "Catppuccin-Mocha-Standard-Blue-Dark"
gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
gsettings set org.gnome.desktop.interface cursor-theme "Adwaita"
gsettings set org.gnome.desktop.interface font-name "Noto Sans 11"
gsettings set org.gnome.desktop.interface cursor-size 24

# Set GTK4 theme (if not already set by above)
mkdir -p "$HOME/.config/gtk-4.0"
cat > "$HOME/.config/gtk-4.0/gtk.css" << EOF
@define-color accent_color #89b4fa;
@define-color accent_bg_color #89b4fa;
@define-color accent_fg_color #11111b;
@define-color destructive_color #f38ba8;
@define-color destructive_bg_color #f38ba8;
@define-color destructive_fg_color #11111b;
@define-color success_color #a6e3a1;
@define-color success_bg_color #a6e3a1;
@define-color success_fg_color #11111b;
@define-color warning_color #fab387;
@define-color warning_bg_color #fab387;
@define-color warning_fg_color #11111b;
@define-color error_color #f38ba8;
@define-color error_bg_color #f38ba8;
@define-color error_fg_color #11111b;
@define-color window_bg_color #1e1e2e;
@define-color window_fg_color #cdd6f4;
@define-color view_bg_color #1e1e2e;
@define-color view_fg_color #cdd6f4;
@define-color headerbar_bg_color #181825;
@define-color headerbar_fg_color #cdd6f4;
@define-color headerbar_border_color #313244;
@define-color headerbar_backdrop_color @window_bg_color;
@define-color headerbar_shade_color rgba(0, 0, 0, 0.36);
@define-color card_bg_color #181825;
@define-color card_fg_color #cdd6f4;
@define-color card_shade_color rgba(0, 0, 0, 0.36);
@define-color dialog_bg_color #181825;
@define-color dialog_fg_color #cdd6f4;
@define-color popover_bg_color #181825;
@define-color popover_fg_color #cdd6f4;
@define-color shade_color rgba(0, 0, 0, 0.36);
@define-color scrollbar_outline_color rgba(0, 0, 0, 0.5);
@define-color blue_1 #89b4fa;
@define-color blue_2 #89b4fa;
@define-color blue_3 #89b4fa;
@define-color blue_4 #89b4fa;
@define-color blue_5 #89b4fa;
@define-color green_1 #a6e3a1;
@define-color green_2 #a6e3a1;
@define-color green_3 #a6e3a1;
@define-color green_4 #a6e3a1;
@define-color green_5 #a6e3a1;
@define-color yellow_1 #f9e2af;
@define-color yellow_2 #f9e2af;
@define-color yellow_3 #f9e2af;
@define-color yellow_4 #f9e2af;
@define-color yellow_5 #f9e2af;
@define-color orange_1 #fab387;
@define-color orange_2 #fab387;
@define-color orange_3 #fab387;
@define-color orange_4 #fab387;
@define-color orange_5 #fab387;
@define-color red_1 #f38ba8;
@define-color red_2 #f38ba8;
@define-color red_3 #f38ba8;
@define-color red_4 #f38ba8;
@define-color red_5 #f38ba8;
@define-color purple_1 #cba6f7;
@define-color purple_2 #cba6f7;
@define-color purple_3 #cba6f7;
@define-color purple_4 #cba6f7;
@define-color purple_5 #cba6f7;
@define-color brown_1 #f5c2e7;
@define-color brown_2 #f5c2e7;
@define-color brown_3 #f5c2e7;
@define-color brown_4 #f5c2e7;
@define-color brown_5 #f5c2e7;
@define-color light_1 #cdd6f4;
@define-color light_2 #cdd6f4;
@define-color light_3 #cdd6f4;
@define-color light_4 #bac2de;
@define-color light_5 #a6adc8;
@define-color dark_1 #181825;
@define-color dark_2 #1e1e2e;
@define-color dark_3 #313244;
@define-color dark_4 #45475a;
@define-color dark_5 #585b70;
EOF

# Update icon cache
gtk-update-icon-cache -f /usr/share/icons/Papirus-Dark
gtk-update-icon-cache -f /usr/share/icons/Adwaita

# Reload Waybar
killall waybar
waybar & 