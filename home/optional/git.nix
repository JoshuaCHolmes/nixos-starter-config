{ config, lib, pkgs, ... }:

# Git configuration

{
  programs.git = {
    enable = true;
    
    # Set your name and email!
    userName = "Your Name";       # TODO: Change this
    userEmail = "you@example.com"; # TODO: Change this
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      
      # Better diffs
      diff.colorMoved = "default";
      
      # Aliases
      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        lg = "log --oneline --graph --decorate";
      };
    };
    
    # Delta for better diffs (optional but nice)
    delta = {
      enable = true;
      options = {
        navigate = true;
        side-by-side = true;
        line-numbers = true;
      };
    };
  };
  
  # GitHub CLI
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };
}
