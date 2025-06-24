# Space Theme Configuration
# Dark cosmic theme based on space wallpapers
{ pkgs, ... }:

{
  # Theme metadata
  name = "space";
  description = "Dark cosmic theme with deep blues and purples";
  wallpaper = "dark_space.jpg";
  
  # Material Design 3 color palette (manually generated for consistency)
  colors = {
    # Primary colors
    primary = "#8EAADC";
    onPrimary = "#0D1929";
    primaryContainer = "#1B2B42";
    onPrimaryContainer = "#C7DDFF";
    
    # Secondary colors  
    secondary = "#B4C7DF";
    onSecondary = "#1F2E3F";
    secondaryContainer = "#354A60";
    onSecondaryContainer = "#D0E4FF";
    
    # Tertiary colors
    tertiary = "#C7B8E8";
    onTertiary = "#2E2545";
    tertiaryContainer = "#453A5C";
    onTertiaryContainer = "#E3D9FF";
    
    # Error colors
    error = "#FFB4AB";
    onError = "#690005";
    errorContainer = "#93000A";
    onErrorContainer = "#FFDAD6";
    
    # Neutral colors
    background = "#0F1419";
    onBackground = "#E2E2E5";
    surface = "#0F1419";
    onSurface = "#E2E2E5";
    surfaceVariant = "#42474E";
    onSurfaceVariant = "#C2C7CF";
    
    # Outline colors
    outline = "#8C9199";
    outlineVariant = "#42474E";
    
    # Surface tints
    scrim = "#000000";
    shadow = "#000000";
    surfaceTint = "#8EAADC";
    
    # Inverse colors
    inverseSurface = "#E2E2E5";
    inverseOnSurface = "#2E3036";
    inversePrimary = "#36618B";
  };

  # Hyprland configuration
  hyprland = ''
    # Space theme colors for Hyprland
    $primary = rgb(8EAADC)
    $primaryContainer = rgb(1B2B42)
    $secondary = rgb(B4C7DF)
    $tertiary = rgb(C7B8E8)
    $background = rgb(0F1419)
    $surface = rgb(0F1419)
    $surfaceVariant = rgb(42474E)
    $outline = rgb(8C9199)
    
    # Window decorations
    decoration {
        col.shadow = rgba(00000099)
        col.shadow_inactive = rgba(00000066)
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
    /* Space Theme for Waybar */
    * {
        font-family: "JetBrains Mono Nerd Font", monospace;
        font-size: 13px;
    }

    window#waybar {
        background-color: #0F1419;
        border: 1px solid #8C9199;
        border-radius: 8px;
        color: #E2E2E5;
        transition-property: background-color;
        transition-duration: 0.5s;
    }

    /* Workspaces */
    #workspaces button {
        background-color: #42474E;
        color: #C2C7CF;
        border: 1px solid #8C9199;
        border-radius: 4px;
        margin: 2px;
        padding: 0 8px;
    }

    #workspaces button.active {
        background-color: #8EAADC;
        color: #0D1929;
        border-color: #8EAADC;
    }

    #workspaces button.urgent {
        background-color: #FFB4AB;
        color: #690005;
        border-color: #93000A;
    }

    /* Modules */
    .modules-left,
    .modules-center,
    .modules-right {
        background-color: #1B2B42;
        border: 1px solid #354A60;
        border-radius: 6px;
        margin: 4px;
        padding: 0 8px;
    }

    /* Individual module styling */
    #clock {
        background-color: #8EAADC;
        color: #0D1929;
        border-radius: 4px;
        padding: 4px 8px;
        margin: 2px;
    }

    #battery {
        background-color: #C7B8E8;
        color: #2E2545;
        border-radius: 4px;
        padding: 4px 8px;
        margin: 2px;
    }

    #network {
        background-color: #B4C7DF;
        color: #1F2E3F;
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
        background-color: #354A60;
        color: #D0E4FF;
        border: 1px solid #453A5C;
        border-radius: 4px;
        padding: 4px 8px;
        margin: 2px;
    }

    /* Temperature warnings */
    #custom-amdgpu_temp.warning {
        background-color: #FFB4AB;
        color: #690005;
    }

    #custom-amdgpu_temp.critical {
        background-color: #93000A;
        color: #FFDAD6;
        animation: blink 1s linear infinite;
    }

    @keyframes blink {
        to { opacity: 0.5; }
    }
  '';

  # GTK 3 theme
  gtk3 = ''
    /* Space Theme GTK3 Colors */
    @define-color theme_fg_color #E2E2E5;
    @define-color theme_bg_color #0F1419;
    @define-color theme_base_color #1B2B42;
    @define-color theme_selected_bg_color #8EAADC;
    @define-color theme_selected_fg_color #0D1929;
    @define-color theme_text_color #E2E2E5;
    @define-color borders #8C9199;
    @define-color warning_color #FFB4AB;
    @define-color error_color #93000A;
    @define-color success_color #C7B8E8;

    /* Window background */
    window {
        background-color: @theme_bg_color;
        color: @theme_fg_color;
    }

    /* Button styling */
    button {
        background-color: #42474E;
        color: #C2C7CF;
        border: 1px solid @borders;
        border-radius: 4px;
    }

    button:hover {
        background-color: #354A60;
    }

    button:active,
    button:checked {
        background-color: @theme_selected_bg_color;
        color: @theme_selected_fg_color;
    }

    /* Entry widgets */
    entry {
        background-color: @theme_base_color;
        color: @theme_text_color;
        border: 1px solid @borders;
        border-radius: 4px;
    }

    entry:focus {
        border-color: @theme_selected_bg_color;
    }

    /* Headerbar */
    headerbar {
        background-color: #1B2B42;
        color: #C7DDFF;
        border-bottom: 1px solid @borders;
    }
  '';

  # GTK 4 theme
  gtk4 = ''
    /* Space Theme GTK4 Colors */
    @define-color accent_color #8EAADC;
    @define-color accent_bg_color #1B2B42;
    @define-color accent_fg_color #C7DDFF;
    @define-color destructive_color #FFB4AB;
    @define-color destructive_bg_color #93000A;
    @define-color destructive_fg_color #FFDAD6;
    @define-color success_color #C7B8E8;
    @define-color success_bg_color #453A5C;
    @define-color success_fg_color #E3D9FF;
    @define-color warning_color #FFB4AB;
    @define-color warning_bg_color #690005;
    @define-color warning_fg_color #FFDAD6;
    @define-color error_color #93000A;
    @define-color error_bg_color #690005;
    @define-color error_fg_color #FFDAD6;
    @define-color window_bg_color #0F1419;
    @define-color window_fg_color #E2E2E5;
    @define-color view_bg_color #1B2B42;
    @define-color view_fg_color #C7DDFF;
    @define-color headerbar_bg_color #1B2B42;
    @define-color headerbar_fg_color #C7DDFF;
    @define-color headerbar_border_color #8C9199;
    @define-color popover_bg_color #354A60;
    @define-color popover_fg_color #D0E4FF;
    @define-color shade_color #00000099;
    @define-color scrollbar_outline_color #8C9199;
  '';

  # Kitty terminal theme
  kitty = ''
    # Space theme for Kitty terminal
    
    # Basic colors
    foreground              #E2E2E5
    background              #0F1419
    selection_foreground    #0D1929
    selection_background    #8EAADC
    
    # Cursor
    cursor                  #8EAADC
    cursor_text_color       #0D1929
    
    # URL underline color when hovering
    url_color               #B4C7DF
    
    # Kitty window border colors
    active_border_color     #8EAADC
    inactive_border_color   #8C9199
    bell_border_color       #FFB4AB
    
    # OS Window titlebar colors
    wayland_titlebar_color  #1B2B42
    macos_titlebar_color    #1B2B42
    
    # Tab bar colors
    active_tab_foreground   #0D1929
    active_tab_background   #8EAADC
    inactive_tab_foreground #C2C7CF
    inactive_tab_background #42474E
    tab_bar_background      #0F1419
    
    # Colors for marks (marked text in the terminal)
    mark1_foreground #0F1419
    mark1_background #C7B8E8
    mark2_foreground #0F1419
    mark2_background #B4C7DF
    mark3_foreground #0F1419
    mark3_background #8EAADC
    
    # The 16 terminal colors
    
    # black
    color0 #0F1419
    color8 #42474E
    
    # red
    color1 #FFB4AB
    color9 #93000A
    
    # green  
    color2  #C7B8E8
    color10 #453A5C
    
    # yellow
    color3  #B4C7DF
    color11 #354A60
    
    # blue
    color4  #8EAADC
    color12 #1B2B42
    
    # magenta
    color5  #C7B8E8
    color13 #453A5C
    
    # cyan
    color6  #B4C7DF
    color14 #354A60
    
    # white
    color7  #E2E2E5
    color15 #C2C7CF
  '';

  # Dunst notification theme
  dunst = ''
    [global]
        # Display
        monitor = 0
        follow = mouse
        
        # Geometry
        width = 300
        height = 300
        origin = top-right
        offset = 10x50
        
        # Progress bar
        progress_bar = true
        progress_bar_height = 10
        progress_bar_frame_width = 1
        progress_bar_min_width = 150
        progress_bar_max_width = 300
        
        # Appearance
        frame_width = 2
        frame_color = "#8EAADC"
        separator_color = frame
        sort = yes
        
        # Text
        font = JetBrains Mono Nerd Font 10
        line_height = 0
        markup = full
        format = "<b>%s</b>\n%b"
        alignment = left
        vertical_alignment = center
        show_age_threshold = 60
        ellipsize = middle
        ignore_newline = no
        stack_duplicates = true
        hide_duplicate_count = false
        show_indicators = yes
        
        # Icons
        icon_position = left
        min_icon_size = 0
        max_icon_size = 32
        
        # History
        sticky_history = yes
        history_length = 20
        
        # Misc/Advanced
        dmenu = /usr/bin/dmenu -p dunst:
        browser = /usr/bin/firefox -new-tab
        always_run_script = true
        title = Dunst
        class = Dunst
        
    [experimental]
        per_monitor_dpi = false
        
    [urgency_low]
        background = "#1B2B42"
        foreground = "#C7DDFF"
        timeout = 10
        
    [urgency_normal]
        background = "#354A60"
        foreground = "#D0E4FF"
        timeout = 10
        
    [urgency_critical]
        background = "#93000A"
        foreground = "#FFDAD6"
        frame_color = "#FFB4AB"
        timeout = 0
  '';
}