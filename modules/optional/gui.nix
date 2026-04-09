{ config, lib, pkgs, ... }:

# GUI Support Module
# Enable with: jch.gui.enable = true;
# For WSL: jch.gui = { enable = true; wsl = true; };

let
  cfg = config.jch.gui;
in
{
  options.jch.gui = {
    enable = lib.mkEnableOption "graphical user interface support";

    wsl = lib.mkEnableOption "WSL-specific graphics configuration (WSLg)";
    
    desktop = lib.mkOption {
      type = lib.types.enum [ "none" "gnome" "plasma" "sway" ];
      default = "none";
      description = "Desktop environment to install";
    };
  };

  config = lib.mkIf cfg.enable {
    # Hardware graphics support
    hardware.graphics.enable = true;

    # WSL-specific GPU configuration
    environment.sessionVariables = lib.mkIf cfg.wsl {
      # Force Mesa to use the D3D12 driver for WSL GPU passthrough
      GALLIUM_DRIVER = "d3d12";
      # Ensure WSL GPU libraries are found
      LD_LIBRARY_PATH = "/usr/lib/wsl/lib";
    };

    # Cursor theme (prevents invisible cursor issues)
    environment.variables = {
      XCURSOR_THEME = "Adwaita";
      XCURSOR_SIZE = "24";
    };

    environment.systemPackages = with pkgs; [
      # Basic GUI utilities
      wl-clipboard    # Wayland clipboard
      
      # Testing tools
      mesa-demos      # glxgears, glxinfo, etc.
      
      # Terminal emulators (pick your favorite)
      foot
      kitty
      
      # Cursor theme
      adwaita-icon-theme
    ];
    
    # Desktop environments
    services.xserver.enable = lib.mkIf (cfg.desktop != "none") true;
    
    # GNOME
    services.xserver.displayManager.gdm.enable = lib.mkIf (cfg.desktop == "gnome") true;
    services.xserver.desktopManager.gnome.enable = lib.mkIf (cfg.desktop == "gnome") true;
    
    # KDE Plasma
    services.displayManager.sddm.enable = lib.mkIf (cfg.desktop == "plasma") true;
    services.desktopManager.plasma6.enable = lib.mkIf (cfg.desktop == "plasma") true;
    
    # Sway (Wayland compositor)
    programs.sway = lib.mkIf (cfg.desktop == "sway") {
      enable = true;
      wrapperFeatures.gtk = true;
    };
  };
}
