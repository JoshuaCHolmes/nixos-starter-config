{ config, lib, pkgs, ... }:

# Development Tools Module
# Enable with: jch.development.enable = true;
# Customize languages with: jch.development.languages.rust = false;

let
  cfg = config.jch.development;
in
{
  options.jch.development = {
    enable = lib.mkEnableOption "development tools and programming languages";
    
    # Language toggles - all enabled by default when development is enabled
    # Set to false to opt-out of specific languages
    languages = {
      python = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Python development environment";
      };
      rust = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Rust development environment";
      };
      node = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Node.js/JavaScript development environment";
      };
      go = lib.mkOption {
        type = lib.types.bool;
        default = false;  # Opt-in
        description = "Go development environment";
      };
      haskell = lib.mkOption {
        type = lib.types.bool;
        default = false;  # Opt-in
        description = "Haskell development environment";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # General development tools
      git
      gh              # GitHub CLI
      gnumake
      gcc
      gdb
      
      # Editors
      neovim
      helix
      
      # Utilities
      jq              # JSON processor
      ripgrep         # Fast grep
      fd              # Fast find
      tree
      direnv          # Per-directory environments
    ]
    # Python
    ++ lib.optionals cfg.languages.python [
      python3
      python3Packages.pip
      python3Packages.virtualenv
    ]
    # Rust
    ++ lib.optionals cfg.languages.rust [
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
    ]
    # Node.js
    ++ lib.optionals cfg.languages.node [
      nodejs
      nodePackages.npm
      nodePackages.yarn
    ]
    # Go
    ++ lib.optionals cfg.languages.go [
      go
      gopls
    ]
    # Haskell
    ++ lib.optionals cfg.languages.haskell [
      ghc
      cabal-install
      stack
      haskell-language-server
    ];
    
    # Enable direnv integration
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
