{
  description = "NixOS config";

  # Define external dependencies (inputs) for this flake
  inputs = {
    # Nixpkgs - The main package repository for Nix/NixOS
    # Using the stable 24.11 release branch
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example
    # Unstable nixpkgs for bleeding-edge packages when needed
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    # Disko - Declarative disk partitioning for NixOS
    # Useful for automated disk setup and formatting
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager - Declarative user environment management
    # Manages dotfiles, user packages, and user-specific configurations
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hyprland - Dynamic tiling Wayland compositor
    # Building from git source for latest features
    hyprland = {
      type = "git";
      url = "https://github.com/hyprwm/hyprland";
      submodules = true;
    };
  };

  # Define what this flake provides (outputs)
  outputs = {
    self,
    nixpkgs,
    home-manager,
    disko,
    ...
  } @ inputs: let
    inherit (self) outputs;
    
    # Helper function to apply a function across supported systems
    forEachSystem = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-darwin"];
    # Helper function to apply a function across package sets for each system
    forEachPkgs = f: forEachSystem (sys: f nixpkgs.legacyPackages.${sys});

    # Helper function to create NixOS system configurations
    # Takes a list of modules and creates a nixosSystem with shared specialArgs
    mkNixos = modules:
      nixpkgs.lib.nixosSystem {
        inherit modules;
        specialArgs = {inherit inputs outputs;};
      };
      
    # Helper function to create Home Manager configurations
    # Takes modules and pkgs, creates a homeManagerConfiguration with shared extraSpecialArgs
    mkHome = modules: pkgs:
      home-manager.lib.homeManagerConfiguration {
        inherit modules pkgs;
        extraSpecialArgs = {inherit inputs outputs;};
      };
  in {
    # Code formatter for this flake (alejandra is a Nix code formatter)
    formatter = forEachPkgs (pkgs: pkgs.alejandra);

    # NixOS system configurations
    # Each entry represents a complete NixOS system that can be built and deployed
    nixosConfigurations = {
      # Desktop/workstation configuration
      mox = mkNixos [./hosts/mox];
      # Another system configuration (possibly laptop or different machine)
      maia = mkNixos [./hosts/maia];
      # Virtual machine configuration for testing
      test-vm = mkNixos [
        disko.nixosModules.disko
        { 
          disko.devices.disk.disk1.device = "/dev/disk/by-id/virtio-virtio-rando123";
          boot.initrd.systemd.emergencyAccess = true;
        }
        ./hosts/test-vm
      ];
    };

    # Home Manager configurations for user environments
    # Format: "username@hostname" = configuration
    homeConfigurations = {
      # User 'ncrmro' configuration for the 'mox' system
      "ncrmro@mox" = mkHome [./home-manager/ncrmro/mox.nix] nixpkgs.legacyPackages."x86_64-linux";
    };
  };
}
