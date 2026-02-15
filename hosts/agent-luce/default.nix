{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ../common/optional/agent-base.nix
    ../common/optional/tailscale-authkey.nix
    ./qcow.nix
    ../../modules/users/luce.nix
    ../../modules/users/ncrmro.nix
    inputs.home-manager.nixosModules.default
    inputs.agenix.nixosModules.default
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

  # Agenix secrets (deployed after first boot when host key is known)
  age.secrets.headscale-authkey = {
    file = ../../agenix-secrets/secrets/headscale-authkey-luce.age;
    owner = "root";
    mode = "0400";
  };

  age.secrets.stalwart-mail-luce-password = {
    file = ../../agenix-secrets/secrets/stalwart-mail-luce-password.age;
    owner = "luce";
    mode = "0400";
  };

  # Tailscale auto-connect with headscale authkey
  services.tailscale.authkey = {
    enable = true;
    secretFile = config.age.secrets.headscale-authkey.path;
    tags = [ "tag:agent" ];
  };

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
