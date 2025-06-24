# Custom Package Overlays
# Additional AUR packages that need custom derivations
self: super: {
  
  # Pokemon colorscripts for terminal aesthetics
  pokemon-colorscripts = super.stdenv.mkDerivation rec {
    pname = "pokemon-colorscripts";
    version = "1.0.0";

    src = super.fetchFromGitHub {
      owner = "talwat";
      repo = "pokemon-colorscripts";
      rev = "main";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    installPhase = ''
      mkdir -p $out/bin $out/share/pokemon-colorscripts
      
      # Install scripts
      cp colorscripts/* $out/share/pokemon-colorscripts/
      
      # Create main executable
      cat > $out/bin/pokemon-colorscripts << 'EOF'
      #!/bin/bash
      SCRIPT_DIR="$out/share/pokemon-colorscripts"
      if [ -z "$1" ]; then
        # Random pokemon if no argument
        script=$(ls "$SCRIPT_DIR" | shuf -n 1)
        cat "$SCRIPT_DIR/$script"
      else
        # Specific pokemon
        if [ -f "$SCRIPT_DIR/$1" ]; then
          cat "$SCRIPT_DIR/$1"
        else
          echo "Pokemon $1 not found"
          exit 1
        fi
      fi
      EOF
      
      chmod +x $out/bin/pokemon-colorscripts
    '';

    meta = with super.lib; {
      description = "Pokemon-themed terminal color scripts";
      homepage = "https://github.com/talwat/pokemon-colorscripts";
      license = licenses.unlicense;
      platforms = platforms.unix;
      maintainers = [ maintainers.yourusername ];
    };
  };

  # Cliphist - Wayland clipboard manager
  cliphist = super.buildGoModule rec {
    pname = "cliphist";
    version = "0.5.0";

    src = super.fetchFromGitHub {
      owner = "sentriz";
      repo = "cliphist";
      rev = "v${version}";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    vendorHash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";

    buildInputs = with super; [
      wayland
      wl-clipboard
    ];

    nativeBuildInputs = with super; [
      pkg-config
    ];

    meta = with super.lib; {
      description = "Wayland clipboard manager";
      homepage = "https://github.com/sentriz/cliphist";
      license = licenses.gpl3Plus;
      platforms = platforms.linux;
      maintainers = [ maintainers.yourusername ];
    };
  };

  # Hyprshot - Screenshot tool for Hyprland
  hyprshot = super.stdenv.mkDerivation rec {
    pname = "hyprshot";
    version = "1.3.0";

    src = super.fetchFromGitHub {
      owner = "Gustash";
      repo = "hyprshot";
      rev = version;
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    nativeBuildInputs = with super; [
      makeWrapper
    ];

    buildInputs = with super; [
      bash
      grim
      slurp
      jq
      libnotify
      wl-clipboard
    ];

    installPhase = ''
      mkdir -p $out/bin
      cp hyprshot $out/bin/
      
      wrapProgram $out/bin/hyprshot \
        --prefix PATH : ${super.lib.makeBinPath buildInputs}
    '';

    meta = with super.lib; {
      description = "Screenshot utility for Hyprland";
      homepage = "https://github.com/Gustash/hyprshot";
      license = licenses.gpl3Plus;
      platforms = platforms.linux;
      maintainers = [ maintainers.yourusername ];
    };
  };

  # Bibata cursor theme (if not available in nixpkgs)
  bibata-cursors-extra = super.stdenv.mkDerivation rec {
    pname = "bibata-cursors-extra";
    version = "2.0.5";

    src = super.fetchFromGitHub {
      owner = "ful1e5";
      repo = "Bibata_Cursor";
      rev = "v${version}";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    nativeBuildInputs = with super; [
      python3
      python3Packages.clickgen
    ];

    buildPhase = ''
      # Build cursors using the provided build script
      python3 build.py
    '';

    installPhase = ''
      mkdir -p $out/share/icons
      cp -r themes/* $out/share/icons/
    '';

    meta = with super.lib; {
      description = "Material based cursor theme";
      homepage = "https://github.com/ful1e5/Bibata_Cursor";
      license = licenses.gpl3Plus;
      platforms = platforms.linux;
      maintainers = [ maintainers.yourusername ];
    };
  };

  # Tela icon theme (if not in nixpkgs)
  tela-icon-theme-extra = super.stdenv.mkDerivation rec {
    pname = "tela-icon-theme";
    version = "2023-02-23";

    src = super.fetchFromGitHub {
      owner = "vinceliuice";
      repo = "Tela-icon-theme";
      rev = "2023-02-23";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    nativeBuildInputs = with super; [
      gtk3
      hicolor-icon-theme
    ];

    installPhase = ''
      mkdir -p $out/share/icons
      ./install.sh -d $out/share/icons
    '';

    meta = with super.lib; {
      description = "A flat colorful design icon theme";
      homepage = "https://github.com/vinceliuice/Tela-icon-theme";
      license = licenses.gpl3Plus;
      platforms = platforms.linux;
      maintainers = [ maintainers.yourusername ];
    };
  };

  # AMD GPU monitoring script as a package
  amdgpu-monitor = super.writeShellScriptBin "amdgpu-monitor" ''
    # AMD GPU monitoring script for Waybar
    CARD_PATH="/sys/class/drm/card1/device"
    HWMON_PATH="$CARD_PATH/hwmon/hwmon1"

    # Temperature monitoring
    get_temp() {
      if [ -f "$HWMON_PATH/temp1_input" ]; then
        temp=$(cat "$HWMON_PATH/temp1_input")
        temp_c=$((temp / 1000))
        
        # Icon based on temperature
        if [ $temp_c -lt 70 ]; then
          icon="❄️"
        elif [ $temp_c -lt 85 ]; then
          icon="🌡️"
        elif [ $temp_c -lt 100 ]; then
          icon="🔥"
        else
          icon="💀"
        fi
        
        echo "$icon $temp_c°C"
      else
        echo "N/A"
      fi
    }

    # GPU usage monitoring
    get_usage() {
      if [ -f "$CARD_PATH/gpu_busy_percent" ]; then
        usage=$(cat "$CARD_PATH/gpu_busy_percent")
        
        # Icon based on usage
        if [ $usage -lt 30 ]; then
          icon="💤"
        elif [ $usage -lt 70 ]; then
          icon="🔋"
        elif [ $usage -lt 90 ]; then
          icon="⚡"
        else
          icon="🚀"
        fi
        
        echo "$icon $usage%"
      else
        echo "N/A"
      fi
    }

    # Main function
    case "$1" in
      temp) get_temp ;;
      usage) get_usage ;;
      *) echo "Usage: $0 {temp|usage}" ;;
    esac
  '';

  # Enhanced ls replacement with better defaults
  eza-enhanced = super.writeShellScriptBin "ll" ''
    ${super.eza}/bin/eza --long --header --git --icons --group-directories-first "$@"
  '';

  # Custom script packages from your dotfiles
  dotfiles-scripts = super.stdenv.mkDerivation {
    pname = "dotfiles-scripts";
    version = "1.0.0";

    src = super.lib.cleanSource ../../scripts;

    installPhase = ''
      mkdir -p $out/bin
      
      # Install all executable scripts
      find . -name "*.sh" -executable -exec cp {} $out/bin/ \;
      find . -name "*.fish" -executable -exec cp {} $out/bin/ \;
      
      # Make sure they're executable
      chmod +x $out/bin/*
    '';

    meta = with super.lib; {
      description = "Custom dotfiles automation scripts";
      license = licenses.mit;
      platforms = platforms.linux;
    };
  };
}

# Usage Notes:
# 1. Update all hash values after first build attempts
# 2. Some packages might already exist in nixpkgs - check first
# 3. Test each package individually: nix-shell -p package-name
# 4. Add any missing dependencies to buildInputs
# 5. Update maintainer information with your details