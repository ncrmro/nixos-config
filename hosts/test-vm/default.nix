{
  inputs,
  outputs,
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./hardware-configuration.nix
    ../common/global
    ../../modules/users/ncrmro.nix
    inputs.keystone.nixosModules.keystoneDesktop
  ];

  # Make users deterministic for test VM
  users.mutableUsers = false;

  # Set simple password for testing
  users.users.ncrmro.initialPassword = "test";

  # Set root password too for emergency access
  users.users.root.initialPassword = "test";

  # Enable keystone desktop
  keystone.desktop.enable = true;

  # Auto-login to Hyprland
  services.greetd.settings.initial_session = {
    command = "Hyprland";
    user = "ncrmro";
  };

  # Keep SSH for debugging
  services.openssh.enable = true;

  # Basic packages
  environment.systemPackages = with pkgs; [
    curl
    git
  ];

  networking.hostId = "00000000";
  system.stateVersion = "24.05";
}
