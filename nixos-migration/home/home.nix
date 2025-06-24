# Home Manager Configuration
# User environment and dotfiles configuration
{ config, pkgs, inputs, ... }:

{
  imports = [
    ./modules/packages
    ./modules/hyprland
    ./modules/waybar
    ./modules/services
    ./modules/theming
    ./modules/fish
  ];

  # Basic user info
  home.username = "martin";
  home.homeDirectory = "/home/martin";
  home.stateVersion = "24.05";

  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  # Apply overlays for custom packages (matugen comes from flake input)
  nixpkgs.overlays = [
    (import ../overlays/cursor-bin.nix)
    (import ../overlays/custom-packages.nix)
  ];

  # Allow unfree packages (for some gaming/proprietary software)
  nixpkgs.config.allowUnfree = true;

  # Session variables (from your current hypr/conf/env.conf)
  home.sessionVariables = {
    # Default applications
    EDITOR = "nvim";
    BROWSER = "firefox";
    TERMINAL = "kitty";
    LAUNCHER = "fuzzel";
    
    # XDG directories
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    
    # Wayland-specific
    WAYLAND_DISPLAY = "wayland-1";
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    
    # Development
    DOTFILES_DIR = "/home/martin/dotfiles";
    PATH = "$PATH:/home/martin/.local/bin:/home/martin/dotfiles/scripts";
    
    # Theme variables (will be managed by theming module)
    GTK_THEME = "Adwaita-dark";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    
    # Performance
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
    
    # AI/Development
    OLLAMA_HOST = "127.0.0.1:11434";
  };

  # User directories
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
      templates = "${config.home.homeDirectory}/Templates";
      publicShare = "${config.home.homeDirectory}/Public";
    };
  };

  # Default applications
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
      "application/pdf" = "firefox.desktop";
      "image/jpeg" = "feh.desktop";
      "image/png" = "feh.desktop";
      "video/mp4" = "mpv.desktop";
      "audio/mpeg" = "mpv.desktop";
      "inode/directory" = "thunar.desktop";
    };
  };

  # Git configuration (matching your AI-powered git setup)
  programs.git = {
    enable = true;
    userName = "Martin";
    userEmail = "your.email@example.com"; # Update this
    
    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "nvim";
      push.default = "simple";
      pull.rebase = false;
      
      # Performance
      core.preloadindex = true;
      core.fscache = true;
      gc.auto = 256;
      
      # Security
      transfer.fsckobjects = true;
      fetch.fsckobjects = true;
      receive.fsckObjects = true;
    };
    
    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      df = "diff";
      lg = "log --oneline --graph --decorate";
    };
  };

  # Basic programs that don't need complex configuration
  programs = {
    # Terminal tools
    bat.enable = true;
    eza.enable = true;
    fzf.enable = true;
    zoxide.enable = true;
    
    # Development
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    
    # Media
    mpv.enable = true;
    
    # System monitoring
    htop.enable = true;
    btop.enable = true;
  };

  # Fonts (user-level font configuration)
  fonts.fontconfig.enable = true;

  # Services that should start with user session
  services = {
    # Notification daemon will be configured in services module
    # GPG agent
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 1800;
      enableSshSupport = true;
    };
  };

  # Home activation scripts for dynamic setup
  home.activation = {
    # Create necessary directories
    createDirectories = config.lib.dag.entryAfter ["writeBoundary"] ''
      mkdir -p $HOME/.local/{bin,share,state}
      mkdir -p $HOME/.config/{scripts,themes}
      mkdir -p $HOME/Pictures/wallpapers
      mkdir -p $HOME/Documents/{projects,notes}
    '';
    
    # Set up symlinks to scripts (maintaining compatibility)
    linkScripts = config.lib.dag.entryAfter ["createDirectories"] ''
      ln -sf ${config.home.homeDirectory}/dotfiles/nixos-migration/scripts/* $HOME/.local/bin/ || true
    '';
  };
}