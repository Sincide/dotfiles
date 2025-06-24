# Nature Theme Configuration
# Organic natural theme based on nature wallpapers
{ pkgs, ... }:

{
  # Theme metadata
  name = "nature";
  description = "Organic natural theme with earthy greens and browns";
  wallpaper = "forest_path.jpg";
  
  # Material Design 3 color palette (nature-inspired)
  colors = {
    # Primary colors (forest green)
    primary = "#7FB069";
    onPrimary = "#1A3A1A";
    primaryContainer = "#2D5A2D";
    onPrimaryContainer = "#B8E6A6";
    
    # Secondary colors (earthy brown)
    secondary = "#A67C52";
    onSecondary = "#2D1F0F";
    secondaryContainer = "#4A3426";
    onSecondaryContainer = "#D4B896";
    
    # Tertiary colors (sky blue)
    tertiary = "#6BB6FF";
    onTertiary = "#0F2A3D";
    tertiaryContainer = "#1E4A6B";
    onTertiaryContainer = "#B8DFFF";
    
    # Error colors
    error = "#D2691E";
    onError = "#2D1505";
    errorContainer = "#8B4513";
    onErrorContainer = "#FFE4B5";
    
    # Neutral colors (warm earth tones)
    background = "#1C1B16";
    onBackground = "#E6E1D7";
    surface = "#1C1B16";
    onSurface = "#E6E1D7";
    surfaceVariant = "#4A453B";
    onSurfaceVariant = "#CCC5B8";
    
    # Outline colors
    outline = "#968C7F";
    outlineVariant = "#4A453B";
    
    # Surface tints
    scrim = "#000000";
    shadow = "#000000";
    surfaceTint = "#7FB069";
    
    # Inverse colors
    inverseSurface = "#E6E1D7";
    inverseOnSurface = "#322F26";
    inversePrimary = "#4A7C59";
  };

  # Hyprland configuration
  hyprland = ''
    # Nature theme colors for Hyprland
    $primary = rgb(7FB069)
    $primaryContainer = rgb(2D5A2D)
    $secondary = rgb(A67C52)
    $tertiary = rgb(6BB6FF)
    $background = rgb(1C1B16)
    $surface = rgb(1C1B16)
    $surfaceVariant = rgb(4A453B)
    $outline = rgb(968C7F)
    
    # Window decorations
    decoration {
        col.shadow = rgba(32322666)
        col.shadow_inactive = rgba(32322633)
    }
    
    # Active window border
    general {
        col.active_border = $primary $tertiary 45deg
        col.inactive_border = $outline
    }
    
    # Group colors
    group {
        col.border_active = $secondary
        col.border_inactive = $surfaceVariant
        col.border_locked_active = $tertiary
        col.border_locked_inactive = $outline
    }
  '';

  # Waybar CSS styles
  waybar = ''
    /* Nature Theme for Waybar */
    * {
        font-family: "JetBrains Mono Nerd Font", monospace;
        font-size: 13px;
    }

    window#waybar {
        background-color: #1C1B16;
        border: 1px solid #968C7F;
        border-radius: 8px;
        color: #E6E1D7;
        transition-property: background-color;
        transition-duration: 0.5s;
    }

    /* Workspaces */
    #workspaces button {
        background-color: #4A453B;
        color: #CCC5B8;
        border: 1px solid #968C7F;
        border-radius: 4px;
        margin: 2px;
        padding: 0 8px;
    }

    #workspaces button.active {
        background-color: #7FB069;
        color: #1A3A1A;
        border-color: #7FB069;
    }

    #workspaces button.urgent {
        background-color: #D2691E;
        color: #2D1505;
        border-color: #8B4513;
    }

    /* Modules */
    .modules-left,
    .modules-center,
    .modules-right {
        background-color: #2D5A2D;
        border: 1px solid #4A3426;
        border-radius: 6px;
        margin: 4px;
        padding: 0 8px;
    }

    /* Individual module styling */
    #clock {
        background-color: #7FB069;
        color: #1A3A1A;
        border-radius: 4px;
        padding: 4px 8px;
        margin: 2px;
    }

    #battery {
        background-color: #6BB6FF;
        color: #0F2A3D;
        border-radius: 4px;
        padding: 4px 8px;
        margin: 2px;
    }

    #network {
        background-color: #A67C52;
        color: #2D1F0F;
        border-radius: 4px;
        padding: 4px 8px;
        margin: 2px;
    }

    /* GPU monitoring (bottom bar) */
    #custom-amdgpu_temp,
    #custom-amdgpu_fan,
    #custom-amdgpu_usage,
    #custom-amdgpu_vram,
    #custom-amdgpu_power {
        background-color: #4A3426;
        color: #D4B896;
        border: 1px solid #1E4A6B;
        border-radius: 4px;
        padding: 4px 8px;
        margin: 2px;
    }

    /* Temperature warnings */
    #custom-amdgpu_temp.warning {
        background-color: #D2691E;
        color: #2D1505;
    }

    #custom-amdgpu_temp.critical {
        background-color: #8B4513;
        color: #FFE4B5;
        animation: blink 1s linear infinite;
    }

    @keyframes blink {
        to { opacity: 0.5; }
    }
  '';

  # GTK 3 theme
  gtk3 = ''
    /* Nature Theme GTK3 Colors */
    @define-color theme_fg_color #E6E1D7;
    @define-color theme_bg_color #1C1B16;
    @define-color theme_base_color #2D5A2D;
    @define-color theme_selected_bg_color #7FB069;
    @define-color theme_selected_fg_color #1A3A1A;
    @define-color theme_text_color #E6E1D7;
    @define-color borders #968C7F;
    @define-color warning_color #D2691E;
    @define-color error_color #8B4513;
    @define-color success_color #7FB069;
  '';

  # GTK 4 theme
  gtk4 = ''
    /* Nature Theme GTK4 Colors */
    @define-color accent_color #7FB069;
    @define-color accent_bg_color #2D5A2D;
    @define-color accent_fg_color #B8E6A6;
    @define-color destructive_color #D2691E;
    @define-color destructive_bg_color #8B4513;
    @define-color destructive_fg_color #FFE4B5;
    @define-color success_color #7FB069;
    @define-color success_bg_color #2D5A2D;
    @define-color success_fg_color #B8E6A6;
    @define-color warning_color #D2691E;
    @define-color warning_bg_color #2D1505;
    @define-color warning_fg_color #FFE4B5;
    @define-color error_color #8B4513;
    @define-color error_bg_color #2D1505;
    @define-color error_fg_color #FFE4B5;
    @define-color window_bg_color #1C1B16;
    @define-color window_fg_color #E6E1D7;
    @define-color view_bg_color #2D5A2D;
    @define-color view_fg_color #B8E6A6;
    @define-color headerbar_bg_color #2D5A2D;
    @define-color headerbar_fg_color #B8E6A6;
    @define-color headerbar_border_color #968C7F;
    @define-color popover_bg_color #4A3426;
    @define-color popover_fg_color #D4B896;
    @define-color shade_color #32322699;
    @define-color scrollbar_outline_color #968C7F;
  '';

  # Kitty terminal theme
  kitty = ''
    # Nature theme for Kitty terminal
    
    # Basic colors
    foreground              #E6E1D7
    background              #1C1B16
    selection_foreground    #1A3A1A
    selection_background    #7FB069
    
    # Cursor
    cursor                  #7FB069
    cursor_text_color       #1A3A1A
    
    # URL underline color when hovering
    url_color               #6BB6FF
    
    # Kitty window border colors
    active_border_color     #7FB069
    inactive_border_color   #968C7F
    bell_border_color       #D2691E
    
    # OS Window titlebar colors
    wayland_titlebar_color  #2D5A2D
    macos_titlebar_color    #2D5A2D
    
    # Tab bar colors
    active_tab_foreground   #1A3A1A
    active_tab_background   #7FB069
    inactive_tab_foreground #CCC5B8
    inactive_tab_background #4A453B
    tab_bar_background      #1C1B16
    
    # The 16 terminal colors
    
    # black
    color0 #1C1B16
    color8 #4A453B
    
    # red
    color1 #D2691E
    color9 #8B4513
    
    # green  
    color2  #7FB069
    color10 #2D5A2D
    
    # yellow
    color3  #A67C52
    color11 #4A3426
    
    # blue
    color4  #6BB6FF
    color12 #1E4A6B
    
    # magenta
    color5  #A67C52
    color13 #4A3426
    
    # cyan
    color6  #6BB6FF
    color14 #1E4A6B
    
    # white
    color7  #E6E1D7
    color15 #CCC5B8
  '';

  # Dunst notification theme
  dunst = ''
    [global]
        frame_color = "#7FB069"
        
    [urgency_low]
        background = "#2D5A2D"
        foreground = "#B8E6A6"
        timeout = 10
        
    [urgency_normal]
        background = "#4A3426"
        foreground = "#D4B896"
        timeout = 10
        
    [urgency_critical]
        background = "#8B4513"
        foreground = "#FFE4B5"
        frame_color = "#D2691E"
        timeout = 0
  '';
}