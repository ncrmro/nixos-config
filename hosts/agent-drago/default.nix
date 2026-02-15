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
    ../../modules/users/drago.nix
    ../../modules/users/ncrmro.nix
    inputs.home-manager.nixosModules.default
    inputs.agenix.nixosModules.default
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

  # Agenix secrets (deployed after first boot when host key is known)
  age.secrets.headscale-authkey = {
    file = ../../agenix-secrets/secrets/headscale-authkey-drago.age;
    owner = "root";
    mode = "0400";
  };

  age.secrets.stalwart-mail-drago-password = {
    file = ../../agenix-secrets/secrets/stalwart-mail-drago-password.age;
    owner = "drago";
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
    users.drago = {
      imports = [
        ../../home-manager/drago/agent.nix
        ../../home-manager/drago/himalaya.nix
      ];
    };
    # ncrmro user has minimal config on agent VMs (console access only)
    extraSpecialArgs = { inherit inputs; };
  };

  system.stateVersion = "24.05";
}
