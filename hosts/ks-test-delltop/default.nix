{
  inputs,
  lib,
  outputs,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/keystone/os.nix
    ../../modules/keystone/desktop.nix
    ./disk-config.nix
    ../common/optional/zfs.luks.root.nix
    ./hardware-configuration.nix
    ../common/optional/eternal-terminal.nix
    ../common/optional/nfs-client.nix
    ../common/optional/monitoring-client.nix
    ../common/optional/alloy-client.nix
    ../common/optional/ableton-live.nix
    ../../modules/nixos/steam.nix
    outputs.nixosModules.bambu-studio
  ];

  keystone.os.iphoneTether.enable = true;
  keystone.os.hypervisor.connections = [
    "qemu+ssh://ncrmro@ocean/session"
    "qemu+ssh://ncrmro@ncrmro-workstation/session"
  ];

  # Enroll ks-test-delltop-ssh-passphrase.age before enabling auto-load.
  keystone.os.users.ncrmro.sshAutoLoad.enable = lib.mkForce false;

  age.secrets = {
    stalwart-mail-ncrmro-password = {
      file = "${inputs.agenix-secrets}/secrets/stalwart-mail-ncrmro-password.age";
      owner = "ncrmro";
      mode = "0400";
    };
    cliflux-config = {
      file = "${inputs.agenix-secrets}/secrets/cliflux-config.age";
      owner = "ncrmro";
      mode = "0400";
    };
    attic-push-token.file = "${inputs.agenix-secrets}/secrets/attic-push-token.age";
    github-agents-token = {
      file = "${inputs.agenix-secrets}/secrets/github-agents-token.age";
      owner = "ncrmro";
      mode = "0400";
    };
    nix-github-token = {
      file = "${inputs.agenix-secrets}/secrets/nix-github-token.age";
      owner = "root";
      mode = "0400";
    };
    grafana-api-token = {
      file = "${inputs.agenix-secrets}/secrets/grafana-api-token.age";
      owner = "ncrmro";
      mode = "0400";
    };
    ncrmro-immich-api-key = {
      file = "${inputs.agenix-secrets}/secrets/ncrmro-immich-api-key.age";
      owner = "ncrmro";
      mode = "0400";
    };
  };

  keystone.binaryCache.push.enable = true;
  keystone.os.githubTokenNix.enable = true;

  programs.bambu-studio.enable = true;
  home-manager.users.ncrmro = import ../../home-manager/ncrmro/ks-test-delltop.nix;

  # Hyprland renders on Intel; the RTX A1000 remains available via
  # nvidia-offload for CUDA/graphics workloads.
  keystone.desktop.obs.gpuType = "intel";

  services = {
    hardware.bolt.enable = true;
    fwupd.enable = true;
    gnome.gnome-keyring.enable = true;
    fprintd.enable = true;
    thermald.enable = true;
    monitoring-client.enable = true;
    alloy-client = {
      enable = true;
      extraLabels = {
        environment = "development";
        device_type = "laptop";
      };
    };
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = [
    pkgs.nfs-utils
    pkgs.nvtopPackages.intel
  ];
  programs.nix-ld.enable = true;
  keystone.hardware.uhk.enable = true;

  networking = {
    hostName = "ks-test-delltop";
    hostId = "817fc626";
  };
  system.stateVersion = "25.11";
}
