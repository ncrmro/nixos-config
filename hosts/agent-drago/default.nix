{ pkgs, inputs, ... }:

{
  imports = [
    ../common/optional/agent-base.nix
    ./qcow.nix
    ../../modules/users/drago.nix
    ../../modules/users/ncrmro.nix
    inputs.home-manager.nixosModules.default
    # Note: agenix secrets are configured after deployment via nixos-rebuild
    # The qcow2 build cannot include secrets - they're added post-deploy
  ];

  # Apply overlays (provides keystonePkgs for home-manager modules)
  nixpkgs.overlays = import ../../overlays { inherit inputs; };
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "agent-drago";

  # Auto-login for drago user
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "drago";

  # Set a password for ncrmro for console access if needed
  users.users.ncrmro.initialPassword = "password";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.drago = {
      imports = [
        ../../home-manager/drago/agent.nix
        # Note: himalaya.nix requires agenix secrets - add after deployment
      ];
    };
    # ncrmro user has minimal config on agent VMs (console access only)
    extraSpecialArgs = { inherit inputs; };
  };

  system.stateVersion = "24.05";
}
