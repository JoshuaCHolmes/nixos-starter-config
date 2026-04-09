{ config, lib, pkgs, username, ... }:

{
  imports = [
    ./optional/development.nix
    ./optional/gui.nix
  ];

  # ============================================================
  # Core Nix Settings
  # ============================================================
  
  nix = {
    settings = {
      # Enable flakes and new nix command
      experimental-features = [ "nix-command" "flakes" ];
      # Optimize storage by hard-linking identical files
      auto-optimise-store = true;
      # Don't warn about dirty git trees
      warn-dirty = false;
    };
    # Automatic garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Allow unfree packages (NVIDIA drivers, VSCode, etc.)
  nixpkgs.config.allowUnfree = true;

  # ============================================================
  # Base System Packages
  # ============================================================
  
  # Keep this minimal - most software goes in home-manager
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    htop
  ];

  # ============================================================
  # Shell Configuration
  # ============================================================
  
  # Enable zsh system-wide (users can still choose bash)
  programs.zsh.enable = true;

  # ============================================================
  # User Configuration
  # ============================================================
  
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
    # Password is set during installation or via:
    # passwd <username>
  };

  # Allow wheel group to use sudo
  security.sudo.wheelNeedsPassword = true;  # Set to false for convenience

  # ============================================================
  # Networking
  # ============================================================
  
  networking.networkmanager.enable = true;
  
  # Firewall - enabled by default, customize as needed
  networking.firewall = {
    enable = true;
    # allowedTCPPorts = [ 22 80 443 ];
    # allowedUDPPorts = [ ];
  };

  # ============================================================
  # Locale & Time
  # ============================================================
  
  time.timeZone = "America/Chicago";  # Change to your timezone
  
  i18n.defaultLocale = "en_US.UTF-8";

  # ============================================================
  # Home Manager Integration
  # ============================================================
  
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };
}
