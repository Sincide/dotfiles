# Theming Module for Home Manager
# Manages dynamic theming system adapted for NixOS
{ config, pkgs, lib, inputs, ... }:

let
  # Theme selection - change this to switch themes
  currentTheme = "space"; # Options: space, nature, gaming, minimal, dark, abstract
  
  # Import theme configurations
  themes = {
    space = import ../../../themes/space/default.nix { inherit pkgs; };
    nature = import ../../../themes/nature/default.nix { inherit pkgs; };
    # Add more themes as they're created
  };

  # Get active theme
  activeTheme = themes.${currentTheme};
  
  # Matugen package from flake input
  matugen = inputs.matugen.packages.${pkgs.system}.default;

in {
  # Theme-related packages
  home.packages = with pkgs; [
    # Core theming tools
    matugen
    swww           # Wallpaper daemon
    imagemagick    # Image processing
    
    # Theme switching scripts
    (writeShellScriptBin "theme-space" ''
      echo "Switching to space theme..."
      home-manager switch --flake ~/.config/home-manager#martin-space
    '')
    
    (writeShellScriptBin "theme-nature" ''
      echo "Switching to nature theme..."
      home-manager switch --flake ~/.config/home-manager#martin-nature
    '')
    
    # Wallpaper management script (adapted from original)
    (writeShellScriptBin "wallpaper-manager" ''
      #!/bin/bash
      # NixOS-adapted wallpaper manager
      set -euo pipefail
      
      WALLPAPER_DIR="$HOME/Pictures/wallpapers"
      CURRENT_THEME="${currentTheme}"
      
      # Function to set wallpaper
      set_wallpaper() {
          local wallpaper_path="$1"
          
          if [[ ! -f "$wallpaper_path" ]]; then
              echo "Error: Wallpaper file not found: $wallpaper_path"
              exit 1
          fi
          
          echo "Setting wallpaper: $wallpaper_path"
          
          # Set wallpaper with swww
          ${pkgs.swww}/bin/swww img "$wallpaper_path" \
              --transition-type wipe \
              --transition-duration 1
          
          # Note: In NixOS, theme colors are pre-generated
          # For dynamic color generation, would need Home Manager rebuild
          echo "Wallpaper set. Theme colors are pre-configured for $CURRENT_THEME theme."
      }
      
      # Function to select wallpaper interactively
      select_wallpaper() {
          if command -v fuzzel >/dev/null 2>&1; then
              local selected
              selected=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | \
                  ${pkgs.fuzzel}/bin/fuzzel --dmenu --prompt "Select wallpaper: ")
              
              if [[ -n "$selected" ]]; then
                  set_wallpaper "$selected"
              fi
          else
              echo "Available wallpapers in $WALLPAPER_DIR:"
              find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | \
                  sed 's|.*/||' | sort
              echo
              read -p "Enter wallpaper filename: " filename
              set_wallpaper "$WALLPAPER_DIR/$filename"
          fi
      }
      
      # Main logic
      case "''${1:-}" in
          select|"")
              select_wallpaper
              ;;
          *)
              set_wallpaper "$1"
              ;;
      esac
    '')
    
    # Dynamic color generation script (for manual use)
    (writeShellScriptBin "generate-theme-colors" ''
      #!/bin/bash
      # Generate colors from wallpaper using matugen
      set -euo pipefail
      
      if [[ $# -ne 1 ]]; then
          echo "Usage: $0 <wallpaper_path>"
          echo "This generates color schemes but requires Home Manager rebuild to apply"
          exit 1
      fi
      
      wallpaper_path="$1"
      
      if [[ ! -f "$wallpaper_path" ]]; then
          echo "Error: Wallpaper file not found: $wallpaper_path"
          exit 1
      fi
      
      echo "Generating colors from: $wallpaper_path"
      
      # Generate colors to temporary directory
      temp_dir=$(mktemp -d)
      
      ${matugen}/bin/matugen image "$wallpaper_path" \
          --mode dark \
          --json > "$temp_dir/colors.json"
      
      echo "Colors generated in: $temp_dir/colors.json"
      echo "To apply these colors, you would need to:"
      echo "1. Update theme configuration files"
      echo "2. Rebuild Home Manager configuration"
      echo "3. Restart applications"
      echo
      echo "For automatic theming, use pre-configured themes:"
      echo "  theme-space"
      echo "  theme-nature"
      
      # Show preview of generated colors
      if command -v jq >/dev/null 2>&1; then
          echo
          echo "Preview of generated colors:"
          jq '.colors.dark' "$temp_dir/colors.json" 2>/dev/null || cat "$temp_dir/colors.json"
      fi
    '')
    
    # GPU monitoring scripts (adapted from original)
    (writeShellScriptBin "gpu-temp-monitor" ''
      #!/bin/bash
      # AMD GPU temperature monitoring for Waybar
      HWMON_PATH="/sys/class/drm/card1/device/hwmon/hwmon1"
      
      if [[ -f "$HWMON_PATH/temp1_input" ]]; then
          temp=$(cat "$HWMON_PATH/temp1_input")
          temp_c=$((temp / 1000))
          
          # Icons based on temperature (space theme)
          if [[ $temp_c -lt 70 ]]; then
              icon="❄️"
              class=""
          elif [[ $temp_c -lt 85 ]]; then
              icon="🌡️"
              class=""
          elif [[ $temp_c -lt 100 ]]; then
              icon="🔥"
              class="warning"
          else
              icon="💀"
              class="critical"
          fi
          
          # Output for Waybar
          echo "{\"text\": \"$icon $temp_c°C\", \"class\": \"$class\", \"tooltip\": \"GPU Temperature: $temp_c°C\"}"
      else
          echo "{\"text\": \"N/A\", \"class\": \"error\", \"tooltip\": \"GPU temperature sensor not found\"}"
      fi
    '')
    
    (writeShellScriptBin "gpu-usage-monitor" ''
      #!/bin/bash
      # AMD GPU usage monitoring for Waybar
      CARD_PATH="/sys/class/drm/card1/device"
      
      if [[ -f "$CARD_PATH/gpu_busy_percent" ]]; then
          usage=$(cat "$CARD_PATH/gpu_busy_percent")
          
          # Icons based on usage
          if [[ $usage -lt 30 ]]; then
              icon="💤"
          elif [[ $usage -lt 70 ]]; then
              icon="🔋"
          elif [[ $usage -lt 90 ]]; then
              icon="⚡"
          else
              icon="🚀"
          fi
          
          echo "{\"text\": \"$icon $usage%\", \"tooltip\": \"GPU Usage: $usage%\"}"
      else
          echo "{\"text\": \"N/A\", \"tooltip\": \"GPU usage sensor not found\"}"
      fi
    '')
  ];

  # Deploy theme-specific configuration files
  home.file = {
    # Hyprland colors
    ".config/hypr/colors.conf".text = activeTheme.hyprland;
    
    # Waybar colors (top bar)
    ".config/waybar/colors.css".text = activeTheme.waybar;
    
    # GTK 3 theming
    ".config/gtk-3.0/colors.css".text = activeTheme.gtk3;
    
    # GTK 4 theming  
    ".config/gtk-4.0/colors.css".text = activeTheme.gtk4;
    
    # Kitty terminal colors
    ".config/kitty/theme-current.conf".text = activeTheme.kitty;
    
    # Dunst notification theming
    ".config/dunst/colors.conf".text = activeTheme.dunst;
    
    # Theme metadata for scripts
    ".config/current-theme".text = ''
      CURRENT_THEME="${currentTheme}"
      THEME_NAME="${activeTheme.name}"
      THEME_DESCRIPTION="${activeTheme.description}"
    '';
  };

  # Wallpaper daemon service
  systemd.user.services.swww = {
    Unit = {
      Description = "Wallpaper daemon (swww)";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    
    Service = {
      Type = "forking";
      ExecStart = "${pkgs.swww}/bin/swww init";
      ExecReload = "${pkgs.swww}/bin/swww kill; ${pkgs.swww}/bin/swww init";
      Restart = "on-failure";
      RestartSec = 5;
    };
    
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # XDG settings for theme coordination
  xdg.configFile = {
    # Ensure matugen config exists for manual color generation
    "matugen/config.toml".text = ''
      # Matugen configuration for NixOS
      [config]
      reload_apps = false  # We handle app reloading via Home Manager
      
      # Templates would go here for dynamic generation
      # In NixOS, we use pre-generated themes instead
    '';
  };

  # GTK theming integration
  gtk = {
    enable = true;
    
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome.gnome-themes-extra;
    };
    
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      size = 24;
      package = pkgs.bibata-cursors;
    };
    
    gtk3.extraCss = activeTheme.gtk3;
    gtk4.extraCss = activeTheme.gtk4;
  };

  # Qt theming
  qt = {
    enable = true;
    platformTheme = "gtk";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  # Session variables for theming
  home.sessionVariables = {
    # Theme-related environment variables
    CURRENT_THEME = currentTheme;
    WALLPAPER_DIR = "$HOME/Pictures/wallpapers";
    
    # GTK theme variables
    GTK_THEME = "Adwaita-dark";
    
    # Cursor theme
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    
    # Qt theme variables
    QT_STYLE_OVERRIDE = "adwaita-dark";
  };

  # Home activation script for theme setup
  home.activation.setupTheming = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Create wallpaper directories
    mkdir -p $HOME/Pictures/wallpapers/{space,nature,gaming,minimal,dark,abstract}
    
    # Set initial wallpaper if swww is running
    if pgrep -x swww-daemon >/dev/null; then
        # Set a default wallpaper for the current theme
        wallpaper_dir="$HOME/Pictures/wallpapers/${currentTheme}"
        if [[ -d "$wallpaper_dir" ]]; then
            default_wallpaper=$(find "$wallpaper_dir" -type f \( -name "*.jpg" -o -name "*.png" \) | head -1)
            if [[ -n "$default_wallpaper" ]]; then
                ${pkgs.swww}/bin/swww img "$default_wallpaper" 2>/dev/null || true
            fi
        fi
    fi
    
    echo "Theme '${currentTheme}' configured successfully"
  '';
}