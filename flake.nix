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
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    omarchy-nix = {
      url = "git+https://github.com/ncrmro/omarchy-nix.git?ref=feat/submodule-omarchy-arch";
      #url = "git+file:///home/ncrmro/code/omarchy/omarchy-nix/";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.home-manager.follows = "home-manager";
    };

    # Additional tools
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

    # Hyprland (latest from official flake)
    hyprland.url = "github:hyprwm/Hyprland";

    # Keystone
    keystone = {
      url = "git+file:./.submodules/keystone?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Omarchy themes (original arch version)
    omarchy = {
      url = "github:basecamp/omarchy";
      flake = false;
    };

    # Helix editor themes
    kinda-nvim-hx = {
      url = "github:strash/kinda_nvim.hx";
      flake = false;
    };

    # llama.cpp - latest for MXFP4 support
    llama-cpp = {
      url = "github:ggml-org/llama.cpp";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative Flatpak management
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    # Walker launcher
    walker = {
      url = "github:abenz1267/walker";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Ghostty terminal (latest for SIGUSR2 config reload support)
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };

    # Yazi terminal file manager
    yazi = {
      url = "github:sxyazi/yazi";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      disko,
      home-manager,
      nixos-hardware,
      nix-index-database,
      agenix,
      ...
    }:
    let
      # Import custom overlays
      overlays = import ./overlays { inherit inputs; };

      # Function to create system-specific packages with allowUnfree enabled
      pkgsForSystem =
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
          overlays = overlays;
        };

      # Same for unstable packages
      unstablePkgsForSystem =
        system:
        import nixpkgs-unstable {
          inherit system;
          config = {
            allowUnfree = true;
          };
          overlays = overlays;
        };
    in
    {
      # Code formatter (official NixOS formatter)
      formatter.x86_64-linux = (pkgsForSystem "x86_64-linux").nixfmt-rfc-style;
      formatter.aarch64-darwin = (pkgsForSystem "aarch64-darwin").nixfmt-rfc-style;

      # Import NixOS and Home Manager modules
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;

      # NixOS system configurations
      nixosConfigurations = {
        # Desktop/workstation configuration
        mox = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/mox ];
          specialArgs = {
            inherit inputs self;
            outputs = self;
          };
        };

        # Home server configuration
        maia = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/maia ];
          specialArgs = {
            inherit inputs self;
            outputs = self;
          };
        };

        # Test VM configuration - Desktop testing VM
        test-vm = nixpkgs.lib.nixosSystem {
          modules = [
            home-manager.nixosModules.default
            {
              boot.initrd.systemd.emergencyAccess = true;
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = {
                inherit inputs;
                outputs = self;
              };
              home-manager.users.ncrmro = import ./home-manager/ncrmro/test-vm.nix;
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
          modules = [ ./hosts/testbox ];
          specialArgs = {
            inherit inputs self;
            outputs = self;
          };
        };

        ncrmro-laptop = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/ncrmro-laptop ];
          specialArgs = {
            inherit inputs self;
            outputs = self;
          };
        };
        devbox = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/devbox ];
          specialArgs = {
            inherit inputs self;
            outputs = self;
          };
        };
        mercury = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/mercury ];
          specialArgs = {
            inherit inputs self;
            outputs = self;
          };
        };
        catalystPrimary = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/catalystPrimary ];
          specialArgs = {
            inherit inputs self;
            outputs = self;
          };
        };
        ocean = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/ocean ];
          specialArgs = {
            inherit inputs self;
            outputs = self;
          };
        };
        ncrmro-workstation = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/workstation ];
          specialArgs = {
            inherit inputs self;
            outputs = self;
          };
        };
      };

      # Home Manager configurations
      homeConfigurations = {
        "ncrmro@mox" = home-manager.lib.homeManagerConfiguration {
          modules = [ ./home-manager/ncrmro/mox.nix ];
          pkgs = pkgsForSystem "x86_64-linux";
          extraSpecialArgs = { inherit inputs self; };
        };
        "nicholas@unsup-macbook" = home-manager.lib.homeManagerConfiguration {
          modules = [ ./home-manager/ncrmro/unsup-macbook.nix ];
          pkgs = pkgsForSystem "aarch64-darwin";
          extraSpecialArgs = { inherit inputs self; };
        };
        "ncrmro@ncrmro-macbook" = home-manager.lib.homeManagerConfiguration {
          modules = [ ./home-manager/ncrmro/ncrmro-macbook.nix ];
          pkgs = pkgsForSystem "aarch64-darwin";
          extraSpecialArgs = { inherit inputs self; };
        };
      };
    };
}
