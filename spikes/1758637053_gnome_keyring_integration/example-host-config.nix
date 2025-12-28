{
  inputs,
  outputs,
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  # Example host configuration demonstrating full GNOME Keyring integration
  # This example shows how to enable comprehensive credential management
  # across SSH, Docker, 1Password, and Bitwarden

  imports = [
    # Core system imports
    inputs.home-manager.nixosModules.default
    ./hardware-configuration.nix
    ../common/global
    ../../modules/users/ncrmro.nix

    # Enable enhanced GNOME Keyring support
    ../common/optional/gnome-keyring-full.nix

    # Other optional modules
    ../common/optional/docker-rootless.nix
    ../common/optional/tailscale.node.nix
  ];

  # Enable full GNOME Keyring integration
  services.gnome-keyring-full.enable = true;

  # Configure display manager for automatic keyring unlock
  services.greetd = {
    enable = true;
    settings.default_session.user = "ncrmro";
  };

  # Home Manager configuration
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = { inherit inputs outputs; };

  # User configuration with keyring integration
  home-manager.users.ncrmro = import ./home.nix;

  # Basic system configuration
  programs.zsh.enable = true;
  users.mutableUsers = true;
  users.users.ncrmro.shell = pkgs.zsh;

  # Networking
  networking.hostName = "example-laptop";
  networking.hostId = "12345678"; # Generate unique ID: head -c 8 /etc/machine-id

  # System state version
  system.stateVersion = "25.05";
}
