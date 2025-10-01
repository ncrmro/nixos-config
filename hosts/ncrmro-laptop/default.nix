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
    ./disk-config.nix
    ../common/optional/zfs.luks.root.nix
    ./hardware-configuration.nix
    ../common/global
    ../../modules/users/ncrmro.nix
    ../../modules/users/root.nix
    # ../common/optional/podman.nix
    ../common/optional/docker-rootless.nix
    ../common/optional/virt-manager.nix
    # ../common/optional/docker-root.nix
    ../common/optional/shairport-sync.nix
    ../common/optional/tailscale.node.nix
    ../common/optional/nfs-client.nix
    ../common/optional/monitoring-client.nix
    ../common/optional/alloy-client.nix
    ./zfs.remote-replication.nix
    ../../modules/nixos/steam.nix
  ];

  programs.zsh.enable = true;
  users.mutableUsers = true;
  users.users.ncrmro.shell = pkgs.zsh;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = {inherit inputs outputs;};
  home-manager.users.ncrmro = import ../../home-manager/ncrmro/ncrmro-laptop.nix;

  services.greetd = {
    enable = true;
    settings.default_session.user = "ncrmro";
  };

  services.hardware.bolt.enable = true;
  services.fwupd.enable = true;
  services.zfs.trim.enable = true;
  services.zfs.autoScrub.enable = true;
  services.zfs.autoSnapshot.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

  # Allow unfree packages like VSCode
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [
    # For debugging and troubleshooting Secure Boot.
    pkgs.sbctl
    pkgs.nfs-utils
    pkgs.nvtopPackages.amd
    inputs.alejandra.defaultPackage."x86_64-linux"
  ];

  programs.nix-ld.enable = true;

  hardware.keyboard.uhk.enable = true;

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
    wantedBy = ["multi-user.target"];
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

  services.monitoring-client = {
    enable = true;
    listenAddress = "100.64.0.1";
  };

  services.alloy-client = {
    enable = true;
    extraLabels = {
      environment = "home";
      device_type = "laptop";
    };
  };

  # Configure Tailscale node (no tags for client machine)
  services.tailscale.node = {
    enable = true;
  };

  networking.hostName = "ncrmro-laptop";
  networking.hostId = "cac44b47";
  system.stateVersion = "25.11";
}
