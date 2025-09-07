{
  description = "NCRMRO's NixOS config";

  inputs = {
    # Main package sources
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Tools and modules
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    omarchy-nix = {
      url = "git+https://github.com/ncrmro/omarchy-nix.git?ref=feat/submodule-omarchy-arch";
      #url = "git+file:///home/ncrmro/code/omarchy/omarchy-nix/";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.home-manager.follows = "home-manager";
    };

    # Additional tools
    alejandra.url = "github:kamadorueda/alejandra/4.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secret management
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    disko,
    home-manager,
    nixos-hardware,
    nix-index-database,
    agenix,
    ...
  }: let
    # Function to create system-specific packages with allowUnfree enabled
    pkgsForSystem = system:
      import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

    # Same for unstable packages
    unstablePkgsForSystem = system:
      import nixpkgs-unstable {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
  in {
    # Code formatter
    formatter.x86_64-linux = pkgsForSystem "x86_64-linux".alejandra;
    formatter.aarch64-darwin = pkgsForSystem "aarch64-darwin".alejandra;

    # Import NixOS and Home Manager modules
    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;

    # NixOS system configurations
    nixosConfigurations = {
      # Desktop/workstation configuration
      mox = nixpkgs.lib.nixosSystem {
        modules = [./hosts/mox];
        specialArgs = {
          inherit inputs self;
          outputs = self;
        };
      };

      # Home server configuration
      maia = nixpkgs.lib.nixosSystem {
        modules = [./hosts/maia];
        specialArgs = {
          inherit inputs self;
          outputs = self;
        };
      };

      # Test VM configuration
      test-vm = nixpkgs.lib.nixosSystem {
        modules = [
          disko.nixosModules.disko
          {
            disko.devices.disk.disk1.device = "/dev/disk/by-id/virtio-virtio-rando123";
            boot.initrd.systemd.emergencyAccess = true;
          }
          ./hosts/test-vm
        ];
        specialArgs = {
          inherit inputs self;
          outputs = self;
        };
      };

      # Additional systems
      testbox = nixpkgs.lib.nixosSystem {
        modules = [./hosts/testbox];
        specialArgs = {
          inherit inputs self;
          outputs = self;
        };
      };

      ncrmro-laptop = nixpkgs.lib.nixosSystem {
        modules = [./hosts/ncrmro-laptop];
        specialArgs = {
          inherit inputs self;
          outputs = self;
        };
      };
      devbox = nixpkgs.lib.nixosSystem {
        modules = [./hosts/devbox];
        specialArgs = {
          inherit inputs self;
          outputs = self;
        };
      };
      mercury = nixpkgs.lib.nixosSystem {
        modules = [./hosts/mercury];
        specialArgs = {
          inherit inputs self;
          outputs = self;
        };
      };
      catalystPrimary = nixpkgs.lib.nixosSystem {
        modules = [./hosts/catalystPrimary];
        specialArgs = {
          inherit inputs self;
          outputs = self;
        };
      };
      ocean = nixpkgs.lib.nixosSystem {
        modules = [./hosts/ocean];
        specialArgs = {
          inherit inputs self;
          outputs = self;
        };
      };
    };

    # Home Manager configurations
    homeConfigurations = {
      "ncrmro@mox" = home-manager.lib.homeManagerConfiguration {
        modules = [./home-manager/ncrmro/mox.nix];
        pkgs = pkgsForSystem "x86_64-linux";
        extraSpecialArgs = {inherit inputs self;};
      };
    };
  };
}
