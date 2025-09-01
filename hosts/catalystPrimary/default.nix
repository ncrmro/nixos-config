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
    ../common/global/openssh.nix
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

  time.timeZone = "America/Chicago";
  networking.hostName = "catalayst-primary";
  networking.hostId = "d3af8ee5";
  system.stateVersion = "25.05";
}
