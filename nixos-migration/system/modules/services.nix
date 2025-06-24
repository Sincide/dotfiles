# System Services Configuration
# Services that run at system level
{ config, pkgs, ... }:

{
  # Ollama AI Service
  services.ollama = {
    enable = true;
    acceleration = "rocm"; # For AMD GPUs
    host = "127.0.0.1";
    port = 11434;
    # Models will be installed via separate script
    environmentVariables = {
      OLLAMA_ORIGINS = "http://localhost:*,http://127.0.0.1:*";
    };
    # Use system-wide service for better resource management
    openFirewall = false; # We handle firewall in main config
  };

  # Docker for development
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # Virtualization support (matching your virt-manager setup)
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf.enable = true;
      ovmf.packages = [ pkgs.OVMFFull.fd ];
    };
  };

  # Enable SPICE guest additions
  services.spice-vdagentd.enable = true;

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
      };
    };
  };
  services.blueman.enable = true;

  # Location services for redshift/gammastep
  services.geoclue2.enable = true;

  # Printing support
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      hplip
      cups-filters
    ];
  };

  # Scanner support
  hardware.sane.enable = true;

  # Firmware updates
  services.fwupd.enable = true;

  # Thumbnail generation
  services.tumbler.enable = true;

  # Enable dconf for GTK apps
  programs.dconf.enable = true;

  # Enable thunar file manager
  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-volman
    ];
  };

  # File system support
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # Power management
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Automatic login (optional - comment out if not desired)
  # services.getty.autologinUser = "martin";
}