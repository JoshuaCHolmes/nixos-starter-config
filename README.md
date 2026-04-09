# NixOS Starter Configuration

A modular, well-documented NixOS configuration to get you started.

## Quick Start

1. **Edit your settings** in `flake.nix`:
   - Change `hostname` to your machine name
   - Change `username` to your username
   - Change `system` if you're on ARM (`aarch64-linux`)

2. **Customize your host** in `hosts/default/default.nix`:
   - Enable/disable development tools
   - Enable GUI if you want a desktop environment
   - Add machine-specific packages

3. **Set your git identity** in `home/optional/git.nix`:
   - Change `userName` and `userEmail`

4. **Rebuild**:
   ```bash
   sudo nixos-rebuild switch --flake .
   ```

## Structure

```
.
├── flake.nix              # Entry point - defines all your machines
├── modules/
│   ├── common.nix         # Shared settings for all machines
│   └── optional/
│       ├── development.nix # Dev tools (languages, editors)
│       └── gui.nix        # Desktop environment options
├── hosts/
│   └── default/
│       ├── default.nix    # Machine-specific config
│       └── hardware-configuration.nix  # Auto-generated
└── home/
    ├── default.nix        # Home Manager entry point
    └── optional/
        ├── shell.nix      # Zsh + prompt configuration
        └── git.nix        # Git configuration
```

## Optional Modules

### Development (`jch.development`)

Enable with:
```nix
jch.development = {
  enable = true;
  languages = {
    python = true;   # Enabled by default
    rust = true;     # Enabled by default
    node = true;     # Enabled by default
    go = false;      # Opt-in
    haskell = false; # Opt-in
  };
};
```

### GUI (`jch.gui`)

Enable with:
```nix
jch.gui = {
  enable = true;
  desktop = "gnome";  # Options: "none", "gnome", "plasma", "sway"
  # wsl = true;       # For WSL with WSLg
};
```

## Adding a New Machine

1. Create a new directory in `hosts/`:
   ```bash
   mkdir -p hosts/my-laptop
   ```

2. Copy and customize the default config:
   ```bash
   cp hosts/default/default.nix hosts/my-laptop/default.nix
   ```

3. Add to `flake.nix`:
   ```nix
   my-laptop = mkHost {
     system = "x86_64-linux";
     hostname = "my-laptop";
     username = "me";
     extraModules = [
       ./hosts/my-laptop
       ./hosts/my-laptop/hardware-configuration.nix
     ];
   };
   ```

4. Generate hardware config:
   ```bash
   nixos-generate-config --show-hardware-config > hosts/my-laptop/hardware-configuration.nix
   ```

## Tips

- **Update packages**: `nix flake update`
- **Garbage collect**: `nix-collect-garbage -d`
- **Search packages**: `nix search nixpkgs firefox`
- **Try a package**: `nix shell nixpkgs#cowsay`

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nixpkgs Search](https://search.nixos.org/packages)
- [NixOS Options Search](https://search.nixos.org/options)
