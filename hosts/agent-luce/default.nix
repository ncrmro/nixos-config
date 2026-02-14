{ pkgs, inputs, ... }:

{
  imports = [
    ../common/optional/agent-base.nix
    ./qcow.nix
    ../../modules/users/luce.nix
    ../../modules/users/ncrmro.nix
    inputs.home-manager.nixosModules.default
    inputs.agenix.nixosModules.default
  ];

  # Apply overlays (provides keystonePkgs for home-manager modules)
  nixpkgs.overlays = import ../../overlays { inherit inputs; };
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "agent-luce";

  # Auto-login for luce user
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "luce";

  # Stalwart mail password for luce user (for himalaya client)
  age.secrets.stalwart-mail-luce-password = {
    file = ../../agenix-secrets/secrets/stalwart-mail-luce-password.age;
    owner = "luce";
    mode = "0400";
  };

  # Set a password for ncrmro for console access if needed
  users.users.ncrmro.initialPassword = "password";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.luce = {
      imports = [
        ../../home-manager/luce/agent.nix
        ../../home-manager/luce/himalaya.nix
      ];
    };
    users.ncrmro = import ../../home-manager/ncrmro/base.nix;
    extraSpecialArgs = { inherit inputs; };
  };

  system.stateVersion = "24.05";
}
