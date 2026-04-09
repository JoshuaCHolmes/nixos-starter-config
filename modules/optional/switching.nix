{ config, lib, pkgs, ... }:

# OS Switching utilities for dual-boot systems with Windows
# Provides easy commands to switch between operating systems
#
# Commands:
#   boot-to-windows  - Reboot into Windows (one-time)
#   boot-menu        - Interactive menu for boot options

let
  boot-to-windows = pkgs.writeShellScriptBin "boot-to-windows" ''
    set -euo pipefail
    
    if [[ $EUID -ne 0 ]]; then
      echo "This command requires root privileges."
      exec sudo "$0" "$@"
    fi
    
    echo "Finding Windows boot entry..."
    
    WINDOWS_ENTRY=$(${pkgs.efibootmgr}/bin/efibootmgr | grep -i "windows" | head -1 | grep -oP 'Boot[0-9A-F]+' | sed 's/Boot//')
    
    if [[ -z "$WINDOWS_ENTRY" ]]; then
      echo "Error: Could not find Windows Boot Manager entry"
      echo ""
      echo "Available boot entries:"
      ${pkgs.efibootmgr}/bin/efibootmgr
      exit 1
    fi
    
    echo "Setting Windows as next boot (entry $WINDOWS_ENTRY)..."
    ${pkgs.efibootmgr}/bin/efibootmgr --bootnext "$WINDOWS_ENTRY"
    
    echo ""
    echo "Your computer will restart into Windows."
    read -p "Press Enter to reboot, or Ctrl+C to cancel..."
    
    systemctl reboot
  '';
  
  boot-menu = pkgs.writeShellScriptBin "boot-menu" ''
    echo "╔════════════════════════════════════════╗"
    echo "║           Boot Options                 ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "  1) Stay on NixOS"
    echo "  2) Reboot to Windows (one-time)"
    echo "  3) Reboot to UEFI/BIOS settings"
    echo "  4) Show all boot entries"
    echo "  5) Set default OS"
    echo ""
    read -p "Select [1-5]: " choice
    
    case $choice in
      2)
        exec ${boot-to-windows}/bin/boot-to-windows
        ;;
      3)
        if [[ $EUID -ne 0 ]]; then
          exec sudo systemctl reboot --firmware-setup
        else
          systemctl reboot --firmware-setup
        fi
        ;;
      4)
        ${pkgs.efibootmgr}/bin/efibootmgr -v
        ;;
      5)
        echo ""
        echo "To change the default boot OS:"
        echo "  - Edit /boot/grub/grub.cfg (GRUB timeout/default)"
        echo "  - Or: sudo efibootmgr -o XXXX,YYYY,... (UEFI order)"
        echo ""
        ${pkgs.efibootmgr}/bin/efibootmgr
        ;;
      *)
        echo "Staying on NixOS."
        ;;
    esac
  '';

in {
  # Install switching utilities
  environment.systemPackages = [
    boot-to-windows
    boot-menu
    pkgs.efibootmgr
  ];
  
  # Ensure efivarfs is mounted (usually automatic, but be explicit)
  boot.supportedFilesystems = [ "vfat" ];
}
