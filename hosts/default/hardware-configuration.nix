# THIS FILE IS AUTO-GENERATED DURING INSTALLATION
# Do not edit manually - it will be replaced by nixos-generate-config
#
# If you're seeing this placeholder, run:
#   nixos-generate-config --show-hardware-config > hosts/default/hardware-configuration.nix

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # Placeholder - will be replaced with actual hardware detection
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];  # Or kvm-amd for AMD CPUs

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_ROOT";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  # If you have swap
  # swapDevices = [ { device = "/dev/disk/by-label/NIXOS_SWAP"; } ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  # Or for AMD:
  # hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
