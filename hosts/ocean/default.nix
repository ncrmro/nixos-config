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
    ../common/global
    ../common/optional/tailscale.nix
    ../common/optional/secureboot.nix
    ./k3s.nix
    ../common/kubernetes/default.nix
  ];

  environment.variables = {
    TERM = "xterm-256color"; # Or your preferred terminal type
  };

  services.openssh.settings.PermitRootLogin = "yes";

  networking.hostId = "89cbac5f"; # generate with: head -c 8 /etc/machine-id
  networking.hostName = "ocean";

  environment.systemPackages = [
    pkgs.sbctl
    pkgs.htop
    pkgs.usbutils
    pkgs.bottom
    pkgs.btop
  ];

  system.stateVersion = "25.11";
}
