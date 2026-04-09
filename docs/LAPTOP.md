# Laptop Support in NixOS

This configuration includes comprehensive laptop support via `jch.laptop.enable = true`.

## Features

### Power Management
- **Deep sleep preference**: Uses S3 instead of S2idle for much better battery during sleep
- **Suspend-then-hibernate**: After 2 hours of sleep, automatically hibernates (zero power)
- **TLP integration**: CPU scaling, WiFi power saving, USB autosuspend
- **Battery thresholds**: Charges 40-80% to extend battery lifespan

### Lid Close Behavior
- **Normal**: Suspends when closed
- **Docked**: Ignores lid close when external monitor connected
- Configurable via `jch.laptop.lidCloseAction` and `jch.laptop.lidCloseDockedAction`

### Hardware
- **Touchpad**: Tap-to-click, natural scrolling, disable while typing
- **Audio**: PipeWire with Bluetooth A2DP support
- **Brightness**: `brightnessctl` and acpilight integration
- **Firmware updates**: fwupd enabled

## Configuration Options

```nix
{
  jch.laptop = {
    enable = true;                      # Enable all laptop features
    
    # Power
    hibernateAfterSuspend = true;       # Hibernate after 2h suspend
    preferDeepSleep = true;             # Use S3 instead of S2idle
    aggressivePowerSaving = false;      # Limit CPU to 50% on battery
    
    # Lid behavior
    lidCloseAction = "suspend";         # suspend/hibernate/lock/ignore
    lidCloseDockedAction = "ignore";    # When external monitor connected
    
    # Hardware
    touchpadTapToClick = true;
    nvidia = false;                     # Enable NVIDIA Optimus support
  };
}
```

## NVIDIA Hybrid Graphics (Optimus)

If your laptop has NVIDIA + Intel/AMD graphics:

```nix
{
  jch.laptop.nvidia = true;
  
  # These are auto-detected during installation, but can be overridden:
  hardware.nvidia.prime = {
    intelBusId = "PCI:0:2:0";    # Find with: lspci | grep VGA
    nvidiaBusId = "PCI:1:0:0";
  };
}
```

Use `nvidia-offload <command>` to run apps on the NVIDIA GPU.

## Hibernate Setup

For hibernate to work, you need swap >= RAM size:

```nix
# In your hardware-configuration.nix or host config:
swapDevices = [{ device = "/swapfile"; size = 16384; }];  # 16GB

# And set resume device:
boot.resumeDevice = "/dev/disk/by-label/nixos";
# boot.kernelParams = [ "resume_offset=XXXXX" ];  # For swapfile: get from filefrag
```

## Troubleshooting

### High sleep power drain
```bash
# Check which sleep state is active
cat /sys/power/mem_sleep
# Should show: s2idle [deep]
# If 'deep' is not available, your hardware may only support s2idle
```

### Touchpad not working after suspend
The configuration includes `psmouse.synaptics_intertouch=0` kernel parameter.
If still broken, try:
```bash
sudo modprobe -r psmouse && sudo modprobe psmouse
```

### WiFi issues
```bash
# Check kernel messages
dmesg | grep -i wifi
journalctl -b | grep -i firmware

# Some WiFi cards need specific firmware
# Check: https://wireless.wiki.kernel.org/
```

### NVIDIA issues
```bash
# Check if module loaded
lsmod | grep nvidia

# View errors
journalctl -b | grep -i nvidia

# Force Intel GPU for troubleshooting
# Add to kernel params: nvidia.modeset=0
```

## Hardware-Specific Notes

### Framework Laptops
Generally excellent NixOS support. Add:
```nix
imports = [ inputs.nixos-hardware.nixosModules.framework-13-inch-common ];
```

### ThinkPads
Well supported. Add the appropriate module:
```nix
imports = [ inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480 ];
```

### Snapdragon X Elite (ARM)
Experimental support via x1e-nixos-config flake. Auto-detected during installation.

### Microsoft Surface
May need linux-surface kernel. See: https://github.com/linux-surface/linux-surface

## Useful Commands

```bash
# Battery status
acpi -b

# Power analysis
sudo powertop

# Temperature monitoring
sensors

# Control brightness
brightnessctl set 50%
brightnessctl set +10%

# Boot to Windows
boot-to-windows
boot-menu
```
