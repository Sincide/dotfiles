# System Hardware and Performance Configuration
# Hardware-specific settings and performance optimizations
{ config, pkgs, ... }:

{
  # AMD GPU Configuration (matching your current setup)
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    
    extraPackages = with pkgs; [
      # AMD GPU drivers and tools
      mesa.drivers
      amdvlk
      rocm-opencl-icd
      rocm-opencl-runtime
      
      # Video acceleration
      libvdpau-va-gl
      vaapiVdpau
    ];
    
    extraPackages32 = with pkgs.pkgsi686Linux; [
      mesa.drivers
      amdvlk
    ];
  };

  # ROCm support for AI workloads (Ollama)
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  # Hardware acceleration for media
  hardware.opengl.extraPackages = with pkgs; [
    intel-media-driver # For Intel graphics (if hybrid)
    vaapiIntel
    libvdpau-va-gl
    intel-compute-runtime # For Intel OpenCL
  ];

  # CPU performance
  powerManagement.cpuFreqGovernor = "performance";

  # Kernel modules for hardware support
  boot.kernelModules = [
    "amdgpu"
    "kvm-amd"
    "v4l2loopback" # For OBS virtual camera
  ];

  # Kernel parameters for AMD GPU
  boot.kernelParams = [
    "amd_pstate=active"
    "amdgpu.ppfeaturemask=0xffffffff"
  ];

  # Extra kernel modules
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
  ];

  # Enable firmware updates
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  # USB support
  services.udev.packages = with pkgs; [
    android-udev-rules
    platformio-core.udev
  ];

  # Performance and monitoring
  programs.htop.enable = true;
  programs.iotop.enable = true;

  # Zram swap for better memory management
  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 50;
  };

  # File system optimizations
  fileSystems."/" = {
    options = [ "noatime" "compress=zstd" "space_cache=v2" ];
  };

  # Network optimizations
  boot.kernel.sysctl = {
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 87380 134217728";
    "net.ipv4.tcp_wmem" = "4096 65536 134217728";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "vm.swappiness" = 10;
    "vm.dirty_ratio" = 15;
    "vm.dirty_background_ratio" = 5;
  };

  # Enable magic SysRq key for emergency situations
  boot.kernel.sysctl."kernel.sysrq" = 1;
}