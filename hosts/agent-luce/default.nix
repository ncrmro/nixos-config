{ pkgs, inputs, ... }:

{
  imports = [
    ../common/optional/agent-base.nix
    ./qcow.nix
    ../../modules/users/luce.nix
    ../../modules/users/ncrmro.nix
    inputs.home-manager.nixosModules.default
    # Note: agenix secrets are configured after deployment via nixos-rebuild
    # The qcow2 build cannot include secrets - they're added post-deploy
  ];

  # Apply overlays (provides keystonePkgs for home-manager modules)
  nixpkgs.overlays = import ../../overlays { inherit inputs; };
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "agent-luce";

  # Auto-login for luce user
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "luce";

  # Set a password for ncrmro for console access if needed
  users.users.ncrmro.initialPassword = "password";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.luce = {
      imports = [
        ../../home-manager/luce/agent.nix
        # Note: himalaya.nix requires agenix secrets - add after deployment
      ];
    };
    users.ncrmro = import ../../home-manager/ncrmro/base.nix;
    extraSpecialArgs = { inherit inputs; };
  };

  system.stateVersion = "24.05";
}
