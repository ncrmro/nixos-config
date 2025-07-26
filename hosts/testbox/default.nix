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
    # inputs.omarchy-nix.nixosModules.default
    inputs.home-manager.nixosModules.default
    outputs.nixosModules.omarchy-config
    ../common/global/disk-config.nix
    ./hardware-configuration.nix
    ../common/global
    ../../modules/users/ncrmro.nix
    ../../modules/users/root.nix
  ];
  home-manager.useGlobalPkgs = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = {inherit inputs outputs;};
  home-manager.users.ncrmro = import ../../home-manager/ncrmro;

  disko.devices.disk.disk1.device = "/dev/disk/by-id/ata-M4-CT128M4SSD2_000000001224090D40C2";
  boot.initrd.systemd.emergencyAccess = false;
  omarchy = {
    scale = 1;
  };

  networking.hostId = "5cbe3b03";
  system.stateVersion = "25.05";
}
