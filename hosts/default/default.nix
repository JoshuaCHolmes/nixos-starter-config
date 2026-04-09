{ config, lib, pkgs, ... }:

# Default host configuration
# This is your machine-specific config

{
  # Import hardware configuration (generated during install)
  imports = [
    ./hardware-configuration.nix
  ];

  # ============================================================
  # Boot Configuration
  # ============================================================
  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ============================================================
  # Enable Optional Modules
  # ============================================================
  
  jch = {
    # Development tools - includes editors, git, language toolchains
    development = {
      enable = true;
      # Customize which languages to include:
      languages = {
        python = true;
        rust = true;
        node = true;
        go = false;      # Opt-in
        haskell = false; # Opt-in
      };
    };
    
    # GUI support - uncomment if you want a graphical environment
    # gui = {
    #   enable = true;
    #   desktop = "gnome";  # Options: "none", "gnome", "plasma", "sway"
    # };
  };

  # ============================================================
  # Additional System Configuration
  # ============================================================
  
  # Add any machine-specific packages here
  environment.systemPackages = with pkgs; [
    # Example: firefox
  ];

  # Enable SSH server
  services.openssh.enable = true;

  # System version - don't change this after initial install
  system.stateVersion = "24.11";
}
