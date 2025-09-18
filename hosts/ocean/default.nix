{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disk-config.nix
    ../common/optional/zfs.luks.root.nix
    ./zpool.ocean.noblock.nix
    ./zfs.users.nix
    ../common/global
    ../common/optional/tailscale.node.nix
    ../common/optional/secureboot.nix
    ../common/optional/agenix.nix
    ../common/optional/adguard-home.nix
    ./k3s.nix
    ./k3s-storage-classes.nix
    ./nfs.nix
    ../common/kubernetes/default.nix
    ../common/kubernetes/adguard-home.nix
    ../../modules/users/ncrmro.nix
    ../../modules/users/root.nix
  ];

  environment.variables = {
    TERM = "xterm-256color"; # Or your preferred terminal type
  };

  # Configure Tailscale node with Kubernetes tags
  services.tailscale.node = {
    enable = true;
    tags = ["tag:k8s-cluster" "tag:k8s-master"];
  };

  services.openssh.settings.PermitRootLogin = "yes";

  networking.hostId = "89cbac5f"; # generate with: head -c 8 /etc/machine-id
  networking.hostName = "ocean";

  networking.interfaces.enp4s0 = {
    ipv4.addresses = [
      {
        address = "192.168.1.10";
        prefixLength = 24;
      }
    ];
  };

  networking.defaultGateway = {
    address = "192.168.1.254";
    interface = "enp4s0";
  };

  networking.nameservers = ["1.1.1.1" "8.8.8.8"];

  environment.systemPackages = [
    pkgs.sbctl
    pkgs.htop
    pkgs.usbutils
    pkgs.bottom
    pkgs.btop
    pkgs.dig
  ];

  system.stateVersion = "25.11";
}
