{
  inputs,
  outputs,
  modulesPath,
  lib,
  pkgs,
  ...
} @ args: {
  imports = [
    
    inputs.lanzaboote.nixosModules.lanzaboote
    # inputs.omarchy-nix.nixosModules.default
    inputs.home-manager.nixosModules.default
    outputs.nixosModules.omarchy-config
    ../common/global/disk-config.nix
    ./hardware-configuration.nix
    ../common/global
    ../../modules/users/ncrmro.nix
    ../../modules/users/root.nix
    ../common/optional/podman.nix
    # ../common/optional/docker-rootless.nix
    # ../common/optional/docker-root.nix
  ];
  
  programs.zsh.enable = true;
  users.mutableUsers=true;
  users.users.ncrmro.shell = pkgs.zsh;
  
  
  home-manager.useGlobalPkgs = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = {inherit inputs outputs;};
  home-manager.users.ncrmro = import ../../home-manager/ncrmro/ncrmro-laptop.nix;
  
  services.hardware.bolt.enable = true;
  services.fwupd.enable = true;
  services.zfs.trim.enable = true;
  services.zfs.autoScrub.enable = true;
  services.zfs.autoSnapshot.enable = true;
  # services.sanoid = {
  #   enable = true;
  #   datasets = {
  #     "rpool" = {
  #       recursive = true;
  #       processChildrenOnly = true;
  #       hourly = 36;
  #       daily = 30;
  #       monthly = 3;
  #       yearly = 0;
  #       autosnap = "yes";
  #       autoprune = "yes";
  #     };
  #   };
  # };
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;


  environment.systemPackages = [
    # For debugging and troubleshooting Secure Boot.
    pkgs.sbctl
    inputs.alejandra.defaultPackage."x86_64-linux"
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
  systemd.services.fprintd = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "simple";
  };
  services.fprintd.enable = true;

  omarchy = {
    scale = 1;
  };
  # https://github.com/NixOS/nixpkgs/issues/231191#issuecomment-1664053176
  environment.etc."resolv.conf".mode = "direct-symlink";

  # networking.firewall.enable = true;
  # networking.firewall.logRefusedConnections = true;
  

  networking.hostName = "ncrmro-laptop";
  networking.hostId = "cac44b47";
  system.stateVersion = "25.05";
}
