{
  inputs,
  outputs,
  modulesPath,
  lib,
  pkgs,
  ...
} @ args: {
  imports = [
    inputs.disko.nixosModules.disko
    ./disko-config.nix
    ./hardware-configuration.nix
    ../common/global
    ../../modules/users/root.nix
    ../../modules/users/ncrmro.nix
    ../common/optional/tailscale.nix
    ./k3s.nix
  ];

  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.emergencyAccess = false;
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.openssh.settings.PermitRootLogin = "yes";

  environment.systemPackages = [
    pkgs.htop
  ];

  environment.variables = {
    TERM = "xterm-256color"; # Or your preferred terminal type
  };

  networking.hostName = "ncrmro-devbox";
  networking.hostId = "1cea3b82";
  system.stateVersion = "25.05";
}
