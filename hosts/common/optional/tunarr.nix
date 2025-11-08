{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../../modules/nixos/tunarr
  ];

  services.tunarr = {
    enable = true;
    openFirewall = false;
  };

  # Open port on tailscale interface only
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [
      8000 # Tunarr
    ];
  };
}
