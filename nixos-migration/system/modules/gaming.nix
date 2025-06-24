# Gaming Configuration
# Gaming-specific packages and optimizations
{ config, pkgs, ... }:

{
  # Steam configuration
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  # GameMode for performance optimization
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };

  # Lutris and Wine
  environment.systemPackages = with pkgs; [
    # Gaming platforms
    lutris
    heroic
    bottles
    
    # Wine and compatibility
    wineWowPackages.stable
    winetricks
    
    # Performance tools
    mangohud
    goverlay
    
    # Game development
    godot_4
    
    # Emulation
    retroarch
    dolphin-emu
    
    # Gaming utilities
    discord
    obs-studio
    streamlink
  ];

  # Enable 32-bit libraries for gaming
  hardware.opengl.driSupport32Bit = true;
  hardware.pulseaudio.support32Bit = true;

  # Gaming-specific kernel parameters
  boot.kernelParams = [
    "mitigations=off" # Disable CPU mitigations for performance
  ];

  # Increase file descriptor limits for games
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "hard";
      item = "nofile";
      value = "1048576";
    }
  ];

  # Gaming-specific udev rules
  services.udev.extraRules = ''
    # Xbox controllers
    SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="028e", MODE="0666"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="028f", MODE="0666"
    
    # PlayStation controllers
    SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0268", MODE="0666"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="05c4", MODE="0666"
  '';

  # Enable controller support
  hardware.xpadneo.enable = true;
}