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
    inputs.lanzaboote.nixosModules.lanzaboote
    # inputs.omarchy-nix.nixosModules.default
    inputs.home-manager.nixosModules.default
    outputs.nixosModules.omarchy-config
    ../common/global/disk-config.nix
    ./hardware-configuration.nix
    ../common/global
    ../../modules/users/ncrmro.nix
    ../../modules/users/root.nix
  ];
  
  users.mutableUsers=true;
  home-manager.useGlobalPkgs = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = {inherit inputs outputs;};
  home-manager.users.ncrmro = import ../../home-manager/ncrmro;
  services.hardware.bolt.enable = true;
  services.fwupd.enable = true;

  disko.devices.disk.disk1.device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S7KHNJ0Y507142D";
  boot.initrd.systemd.emergencyAccess = true;
  environment.systemPackages = [
    # For debugging and troubleshooting Secure Boot.
    pkgs.sbctl
    inputs.alejandra.defaultPackage."x86_64-linux"
    pkgs.code-cursor
  ];

  # Lanzaboote currently replaces the systemd-boot module.
  # This setting is usually set to true in configuration.nix
  # generated at installation time. So we force it to false
  # for now.
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
  # omarchy = {
  #   scale = 1;
  # };

  networking.hostId = "cac44b47";
  system.stateVersion = "25.05";
}
