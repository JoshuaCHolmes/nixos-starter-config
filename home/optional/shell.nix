{ config, lib, pkgs, ... }:

# Shell configuration - zsh with nice defaults

{
  programs.zsh = {
    enable = true;
    
    # Plugins
    enableAutosuggestions = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    
    # History
    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      ignoreSpace = true;
    };
    
    # Aliases
    shellAliases = {
      # Better defaults
      ls = "eza --icons";
      ll = "eza -la --icons";
      cat = "bat";
      
      # NixOS
      rebuild = "sudo nixos-rebuild switch --flake .";
      update = "nix flake update";
      
      # Git shortcuts
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
    };
    
    # Initialize zoxide (smart cd)
    initExtra = ''
      eval "$(zoxide init zsh)"
    '';
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
      };
    };
  };
}
