{ config, lib, pkgs, ... }:

# Laptop power management for NixOS
# Addresses common issues with suspend power consumption
#
# Key settings:
# - Prefer S3 (deep) sleep over S2idle when available
# - Enable TLP for comprehensive power optimization
# - Hibernate after extended suspend to save battery
# - Auto-cpufreq for dynamic CPU scaling

let
  cfg = config.jch.laptop;
in {
  options.jch.laptop = {
    enable = lib.mkEnableOption "laptop power management optimizations";
    
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
    
    # Prefer S3 (deep) sleep - much lower power than S2idle on most hardware
    boot.kernelParams = lib.mkIf cfg.preferDeepSleep [
      "mem_sleep_default=deep"
    ];
    
    # Hibernate after prolonged suspend (suspend-then-hibernate)
    # This prevents waking up to a dead battery
    systemd.sleep.extraConfig = lib.mkIf cfg.hibernateAfterSuspend ''
      HibernateDelaySec=2h
      SuspendState=mem
    '';
    
    # Use suspend-then-hibernate by default for lid close etc
    services.logind = lib.mkIf cfg.hibernateAfterSuspend {
      lidSwitch = "suspend-then-hibernate";
      lidSwitchExternalPower = "suspend";  # Just suspend when plugged in
    };
    
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
    ];
    
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
    # Power Status in Shell Prompt (optional)
    # ============================================================
    
    # You can add battery status to your shell prompt using:
    # $(acpi -b | grep -oP '\d+%')
  };
}
