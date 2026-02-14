# Agent Base Image Builder
# This configuration builds a generic qcow2 image containing both agent users.
# The base image can be cloned for each agent, then customized via nixos-rebuild.
#
# Build: nix build .#nixosConfigurations.agent-base.config.system.build.qcow2
# Deploy: cp result/nixos.qcow2 ~/.agentvms/agent-{name}.qcow2
{ pkgs, inputs, ... }:

{
  imports = [
    ../common/optional/agent-base.nix
    ./qcow.nix
    # Include both agent users in the base image
    ../../modules/users/drago.nix
    ../../modules/users/luce.nix
    ../../modules/users/ncrmro.nix
    inputs.home-manager.nixosModules.default
  ];

  # Apply overlays
  nixpkgs.overlays = import ../../overlays { inherit inputs; };
  nixpkgs.config.allowUnfree = true;

  networking.hostName = "agent-base";

  # Disable auto-login in base image (each agent enables for their user)
  services.displayManager.autoLogin.enable = false;

  # Set initial passwords for all users
  users.users.drago.initialPassword = "password";
  users.users.luce.initialPassword = "password";
  users.users.ncrmro.initialPassword = "password";

  # Basic home-manager setup without agent-specific config
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.drago = {
      imports = [ ../../home-manager/common/agents/base.nix ];
      home.username = "drago";
      home.homeDirectory = "/home/drago";
      programs.git.userName = "Drago";
      programs.git.userEmail = "drago@ncrmro.com";
      home.stateVersion = "24.05";
    };
    users.luce = {
      imports = [ ../../home-manager/common/agents/base.nix ];
      home.username = "luce";
      home.homeDirectory = "/home/luce";
      programs.git.userName = "Luce";
      programs.git.userEmail = "luce@ncrmro.com";
      home.stateVersion = "24.05";
    };
    users.ncrmro = import ../../home-manager/ncrmro/base.nix;
    extraSpecialArgs = { inherit inputs; };
  };

  system.stateVersion = "24.05";
}
