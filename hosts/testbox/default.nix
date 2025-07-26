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
    inputs.omarchy-nix.nixosModules.default
    inputs.home-manager.nixosModules.default

    ../common/global/disk-config.nix
    ./hardware-configuration.nix
  ];
  home-manager.useGlobalPkgs = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = {inherit inputs outputs;};
  home-manager.users.ncrmro = import ../../home-manager/ncrmro;
  users.users = {
    ncrmro = {
      isNormalUser = true;
      initialPassword = "changeme";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyrDBVcGK+pUZOTUA7MLoD5vYK/kaPF6TNNyoDmwNl2 ncrmro@ncrmro-laptop-fw7k"
      ];

      extraGroups = [
        "audio"
        "input"
        "networkmanager"
        "sound"
        "tty"
        "wheel"
        "docker"
      ];
    };
  };
  omarchy = {
    full_name = "Nicholas Romero";
    email_address = "ncrmro@gmail.com";
    theme = "tokyo-night";
  };

  disko.devices.disk.disk1.device = "/dev/disk/by-id/ata-M4-CT128M4SSD2_000000001224090D40C2";
  boot.initrd.systemd.emergencyAccess = true;
  # Configure omarchy

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys =
    [
      # change this to your ssh key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyrDBVcGK+pUZOTUA7MLoD5vYK/kaPF6TNNyoDmwNl2 ncrmro@ncrmro-laptop-fw7k"
    ]
    ++ (args.extraPublicKeys or []); # this is used for unit-testing this module and can be removed if not needed

  networking.hostId = "5cbe3b03";
  system.stateVersion = "25.05";
}
