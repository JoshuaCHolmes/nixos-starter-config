{ config, lib, pkgs, username, ... }:

# Home Manager configuration
# This manages user-specific dotfiles and applications

{
  imports = [
    ./optional/shell.nix
    ./optional/git.nix
  ];

  home = {
    # Don't change this after initial setup
    stateVersion = "24.11";
    
    # User packages - add your personal applications here
    packages = with pkgs; [
      # CLI tools
      btop          # Better htop
      eza           # Better ls
      bat           # Better cat
      fzf           # Fuzzy finder
      zoxide        # Smart cd
      
      # Add more packages here!
    ];
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;
}
