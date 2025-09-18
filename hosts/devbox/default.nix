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
    ../common/optional/tailscale.node.nix
    #../common/optional/k3s-openebs-zfs.nix
    ./k3s.nix
  ];

  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.emergencyAccess = false;
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.openssh.settings.PermitRootLogin = "yes";

  environment.systemPackages = [
    pkgs.htop
    pkgs.btop
    pkgs.bottom
    pkgs.iftop
  ];

  environment.variables = {
    TERM = "xterm-256color"; # Or your preferred terminal type
  };

  # Configure Tailscale node with Kubernetes tags
  services.tailscale.node = {
    enable = true;
    tags = ["tag:k8s-cluster"];
  };

  networking.hostName = "ncrmro-devbox";
  networking.hostId = "1cea3b82";
  networking.hosts = {
    "127.0.0.1" = ["devbox.ncrmro.com" "cr.devbox.ncrmro.com" "devbox.catalyst.ncrmro.com"];
  };
  system.stateVersion = "25.05";
}
