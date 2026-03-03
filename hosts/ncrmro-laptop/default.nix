{
  inputs,
  outputs,
  modulesPath,
  lib,
  pkgs,
  ...
}@args:
{
  imports = [
    # lanzaboote provided by keystone operating-system module
    # inputs.omarchy-nix.nixosModules.default
    ../common/optional/home-manager-base.nix
    ../../modules/keystone.nix
    ../../modules/keystone.desktop.nix
    # outputs.nixosModules.omarchy-config
    ./disk-config.nix
    ../common/optional/zfs.luks.root.nix
    ./hardware-configuration.nix
    ../common/global
    # ../common/optional/podman.nix
    ../common/optional/docker-rootless.nix
    # ../common/optional/docker-root.nix
    ../common/optional/tailscale.node.nix
    ../common/optional/eternal-terminal.nix
    ../common/optional/nfs-client.nix
    ../common/optional/monitoring-client.nix
    ../common/optional/alloy-client.nix
    ../common/optional/iphone-tether.nix
    ../common/optional/agenix.nix
    ./zfs.remote-replication.nix
    ../../modules/nixos/steam.nix
    outputs.nixosModules.bambu-studio
  ];

  # Stalwart mail user password for himalaya
  age.secrets.stalwart-mail-ncrmro-password = {
    file = "${inputs.agenix-secrets}/secrets/stalwart-mail-ncrmro-password.age";
    owner = "ncrmro";
    mode = "0400";
  };

  # Cliflux config (Miniflux CLI client)
  age.secrets.cliflux-config = {
    file = "${inputs.agenix-secrets}/secrets/cliflux-config.age";
    owner = "ncrmro";
    mode = "0400";
  };

  # GitHub agents token
  age.secrets.github-agents-token = {
    file = "${inputs.agenix-secrets}/secrets/github-agents-token.age";
    owner = "ncrmro";
    mode = "0400";
  };

  programs.bambu-studio.enable = true;

  # Per-host home-manager config: monitor layout, rebuild target
  home-manager.users.ncrmro = import ../../home-manager/ncrmro/ncrmro-laptop.nix;

  # services.greetd = {
  #   enable = true;
  #   settings.default_session.user = "ncrmro";
  # };

  services.hardware.bolt.enable = true;
  services.fwupd.enable = true;
  services.zfs.trim.enable = true;
  services.zfs.autoScrub.enable = true;
  services.zfs.autoSnapshot.enable = true;
  services.gnome.gnome-keyring.enable = true;
  # security.pam.services.greetd.enableGnomeKeyring = true;

  # Allow unfree packages like VSCode
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [
    # For debugging and troubleshooting Secure Boot.
    pkgs.sbctl
    pkgs.nfs-utils
    pkgs.nvtopPackages.amd
    # inputs.alejandra.defaultPackage."x86_64-linux"
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
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "simple";
  };
  services.fprintd.enable = true;

  # networking.firewall.enable = true;
  # networking.firewall.logRefusedConnections = true;

  services.monitoring-client = {
    enable = true;
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
