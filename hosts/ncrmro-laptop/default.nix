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

  disko.devices.disk.disk1.device = "/dev/disk/by-id/ata-Samsung_SSD_990_PRO_2TB_S7KHNJ0Y507142D";
  disko.devices.disk.disk1.content = {
    partitions = {
      zfs = {
        end = "-64G";
      };
    };
  };
  boot.initrd.systemd.emergencyAccess = true;
  # omarchy = {
  #   scale = 1;
  # };

  networking.hostId = "cac44b47";
  system.stateVersion = "25.05";
}
