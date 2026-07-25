{
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

  # Enroll this host's SSH key in agenix-secrets before enabling the
  # laptop's host-bound secrets and their dependent token services.
  keystone.binaryCache.push.enable = false;
  keystone.os.githubTokenNix.enable = false;

  programs.bambu-studio.enable = true;
  home-manager.users.ncrmro = import ../../home-manager/ncrmro/ks-test-delltop.nix;

  # Test host bootstrap credential. Store only the SHA-512 password hash.
  users.users.ncrmro.hashedPassword =
    lib.mkForce
      "$6$.Sxz7EzpE6oYB57Z$vsbqhHUKf/pzFBpdBqmN8JW80ftQ2JD4ZfgMePMNWftm43W5vgsQn9Q8xPtQM8OaqfPfJ1/uIHXH3Odm9JnGB0";

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
