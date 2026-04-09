{ config, lib, pkgs, ... }:

# Comprehensive laptop support for NixOS
# 
# This module addresses common laptop issues:
# - Power management and battery life
# - Suspend/hibernate behavior
# - Lid close handling (especially with external monitors)
# - Touchpad configuration
# - Brightness controls
# - Audio (PipeWire)
# - NVIDIA hybrid graphics (optional)
#
# Enable with: jch.laptop.enable = true;

let
  cfg = config.jch.laptop;
in {
  options.jch.laptop = {
    enable = lib.mkEnableOption "laptop optimizations and power management";
    
    # Power settings
    hibernateAfterSuspend = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Hibernate after 2 hours of suspend to prevent battery drain";
    };
    
    preferDeepSleep = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Prefer S3 (deep) sleep over S2idle/Modern Standby when available";
    };
    
    aggressivePowerSaving = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable aggressive power saving (may affect performance)";
    };
    
    # Lid behavior
    lidCloseAction = lib.mkOption {
      type = lib.types.enum [ "suspend" "hibernate" "lock" "ignore" ];
      default = "suspend";
      description = "Action when laptop lid is closed";
    };
    
    lidCloseDockedAction = lib.mkOption {
      type = lib.types.enum [ "suspend" "hibernate" "lock" "ignore" ];
      default = "ignore";
      description = "Action when lid is closed with external monitor/dock connected";
    };
    
    # Hardware
    touchpadTapToClick = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable tap-to-click on touchpad";
    };
    
    nvidia = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable NVIDIA hybrid graphics support (for Optimus laptops)";
    };
  };

  config = lib.mkIf cfg.enable {
    # ============================================================
    # Core Power Management
    # ============================================================
    
    powerManagement = {
      enable = true;
      # Run powertop auto-tune on boot
      powertop.enable = true;
    };
    
    # ============================================================
    # Sleep State Configuration
    # ============================================================
    
    # Kernel parameters for sleep and touchpad fixes
    boot.kernelParams = 
      (lib.optionals cfg.preferDeepSleep [ "mem_sleep_default=deep" ]) ++
      [ "psmouse.synaptics_intertouch=0" ];  # Fix for some Synaptics touchpads
    
    # Hibernate after prolonged suspend (suspend-then-hibernate)
    # This prevents waking up to a dead battery
    systemd.sleep.extraConfig = lib.mkIf cfg.hibernateAfterSuspend ''
      HibernateDelaySec=2h
      SuspendState=mem
    '';
    
    # ============================================================
    # TLP - Comprehensive Power Management
    # ============================================================
    
    services.tlp = {
      enable = true;
      settings = {
        # CPU scaling
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        
        # Turbo boost
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        
        # Platform profile (for Intel/AMD mobile platforms)
        PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "low-power";
        
        # WiFi power saving
        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";
        
        # USB autosuspend
        USB_AUTOSUSPEND = 1;
        
        # PCIe ASPM (Active State Power Management)
        PCIE_ASPM_ON_AC = "default";
        PCIE_ASPM_ON_BAT = "powersupersave";
        
        # NVMe power saving
        AHCI_RUNTIME_PM_ON_AC = "on";
        AHCI_RUNTIME_PM_ON_BAT = "auto";
        
        # Battery charge thresholds (if supported by hardware)
        # Charging to 80% extends battery lifespan significantly
        START_CHARGE_THRESH_BAT0 = 40;
        STOP_CHARGE_THRESH_BAT0 = 80;
      } // lib.optionalAttrs cfg.aggressivePowerSaving {
        # Even more aggressive settings
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_MAX_PERF_ON_BAT = 50;  # Limit to 50% max frequency
        RUNTIME_PM_ON_BAT = "auto";
      };
    };
    
    # Disable power-profiles-daemon (conflicts with TLP)
    services.power-profiles-daemon.enable = false;
    
    # ============================================================
    # Thermal Management
    # ============================================================
    
    # Intel thermal daemon (for Intel CPUs)
    services.thermald.enable = true;
    
    # ============================================================
    # Helpful Tools
    # ============================================================
    
    environment.systemPackages = with pkgs; [
      powertop       # Power consumption analyzer
      acpi           # Battery status
      lm_sensors     # Hardware sensors
      brightnessctl  # Screen brightness control
    ];
    
    # ============================================================
    # Lid Close Behavior
    # ============================================================
    
    services.logind = {
      # Normal lid close behavior
      lidSwitch = if cfg.hibernateAfterSuspend 
        then "suspend-then-hibernate" 
        else cfg.lidCloseAction;
      
      # When on external power (charger)
      lidSwitchExternalPower = cfg.lidCloseAction;
      
      # When docked (external monitor/dock connected)
      # "ignore" is usually best - keep working on external display
      lidSwitchDocked = cfg.lidCloseDockedAction;
    };
    
    # ============================================================
    # Touchpad Configuration
    # ============================================================
    
    services.libinput = {
      enable = true;
      touchpad = {
        tapping = cfg.touchpadTapToClick;
        naturalScrolling = true;  # macOS-style scrolling
        disableWhileTyping = true;
        clickMethod = "clickfinger";  # Two-finger = right click
      };
    };
    
    # ============================================================
    # Audio - PipeWire (modern, low-latency)
    # ============================================================
    
    # Enable real-time scheduling for audio
    security.rtkit.enable = true;
    
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;  # PulseAudio compatibility
      wireplumber.enable = true;
    };
    
    # Disable PulseAudio (we use PipeWire's pulse compatibility)
    hardware.pulseaudio.enable = false;
    
    # ============================================================
    # Bluetooth
    # ============================================================
    
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          # Enable A2DP high-quality audio
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
    services.blueman.enable = true;  # Bluetooth GUI manager
    
    # ============================================================
    # NVIDIA Hybrid Graphics (Optimus)
    # ============================================================
    
    hardware.nvidia = lib.mkIf cfg.nvidia {
      # Use the stable driver - less likely to break with kernel updates
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      
      modesetting.enable = true;
      
      # Power management for hybrid graphics
      powerManagement.enable = true;
      powerManagement.finegrained = true;  # Turn off GPU when not in use
      
      # Optimus PRIME - use Intel/AMD for display, NVIDIA for compute
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;  # Adds `nvidia-offload` command
        };
        # These need to be set per-machine in hardware-configuration.nix:
        # intelBusId = "PCI:0:2:0";
        # nvidiaBusId = "PCI:1:0:0";
      };
      
      # Don't use open-source kernel module (not ready for most cards)
      open = false;
    };
    
    # ============================================================
    # Hibernate Setup (requires swap)
    # ============================================================
    
    # Note: For hibernate to work, you need:
    # 1. A swap partition or swapfile >= RAM size
    # 2. boot.resumeDevice set to swap partition
    # 
    # Example for swapfile:
    # swapDevices = [{ device = "/swapfile"; size = 16384; }];  # 16GB
    # boot.resumeDevice = "/dev/disk/by-label/nixos";
    # boot.kernelParams = [ "resume_offset=XXXXX" ];  # from filefrag
    
    # ============================================================
    # Firmware Updates
    # ============================================================
    
    # Enable fwupd for firmware updates (BIOS, SSD, etc.)
    services.fwupd.enable = true;
    
    # ============================================================
    # Backlight / Brightness
    # ============================================================
    
    # Allow users in video group to control backlight
    hardware.acpilight.enable = true;
    
    # ============================================================
    # Battery Monitoring
    # ============================================================
    
    # UPower for battery status reporting to desktop environments
    services.upower = {
      enable = true;
      criticalPowerAction = "Hibernate";  # Hibernate instead of shutdown
    };
  };
}
