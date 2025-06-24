# NixOS System Configuration
# Main system configuration for NixOS migration from Arch + Hyprland dotfiles
{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/system.nix
    ./modules/services.nix
    ./modules/gaming.nix
  ];

  # System Information
  system.stateVersion = "24.05";
  networking.hostName = "nixos-hyprland";

  # Nix Configuration
  nix = {
    settings = {
      # Enable flakes and new command line
      experimental-features = [ "nix-command" "flakes" ];
      # Optimize storage
      auto-optimise-store = true;
    };
    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Boot Configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    # Enable latest kernel for hardware support
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # Networking
  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 8080 9090 11434 ]; # Dashboard, qBittorrent, Ollama
    };
  };

  # Time and Locale
  time.timeZone = "America/New_York"; # Adjust to your timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # Audio
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # Enable other programs
  programs = {
    fish.enable = true;
    git.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
    };
  };

  # Fonts (matching your current setup)
  fonts.packages = with pkgs; [
    jetbrains-mono
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    font-awesome
    (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" ]; })
  ];

  # System packages (minimal - most will be in Home Manager)
  environment.systemPackages = with pkgs; [
    vim
    curl
    wget
    git
    home-manager
    # Matugen from flake input (CRITICAL for theming)
    inputs.matugen.packages.${pkgs.system}.default
  ];

  # User configuration
  users.users.martin = {
    isNormalUser = true;
    description = "Martin";
    extraGroups = [ 
      "wheel" 
      "networkmanager" 
      "audio" 
      "video" 
      "docker"
      "libvirtd"
    ];
    shell = pkgs.fish;
  };

  # Security
  security.sudo.wheelNeedsPassword = true;
  
  # Enable polkit for GUI applications
  security.polkit.enable = true;
  
  # XDG portal for screen sharing, file dialogs, etc.
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };
}