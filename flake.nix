{
  description = "NixOS Starter Configuration - A modular, well-documented starting point";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Optional: WSL support (only loaded if needed)
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-wsl, ... }: 
  let
    # Helper function to create a NixOS system configuration
    # This reduces repetition when adding new machines
    mkHost = { 
      system, 
      hostname, 
      username ? "user",
      extraModules ? [],
      isWSL ? false,
    }: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit self username; };
      modules = [
        home-manager.nixosModules.home-manager
        ./modules/common.nix
        {
          networking.hostName = hostname;
          
          # Pass username to home-manager
          home-manager.users.${username} = import ./home;
          home-manager.extraSpecialArgs = { inherit username; };
        }
      ] 
      ++ nixpkgs.lib.optionals isWSL [ nixos-wsl.nixosModules.default ]
      ++ extraModules;
    };
  in
  {
    nixosConfigurations = {
      
      # Default configuration - edit this for your first machine!
      # After install, rename to match your hostname
      default = mkHost {
        system = "x86_64-linux";  # Change to "aarch64-linux" for ARM
        hostname = "nixos";       # Change this to your desired hostname
        username = "user";        # Change this to your username
        extraModules = [
          ./hosts/default
        ];
      };

      # Example: WSL configuration
      # Uncomment and customize for Windows Subsystem for Linux
      # my-wsl = mkHost {
      #   system = "x86_64-linux";
      #   hostname = "my-wsl";
      #   username = "myuser";
      #   isWSL = true;
      #   extraModules = [ ./hosts/wsl ];
      # };

      # Example: Desktop with GUI
      # my-desktop = mkHost {
      #   system = "x86_64-linux";
      #   hostname = "my-desktop";
      #   username = "myuser";
      #   extraModules = [
      #     ./hosts/desktop
      #     ./hosts/desktop/hardware-configuration.nix
      #   ];
      # };

    };
  };
}
