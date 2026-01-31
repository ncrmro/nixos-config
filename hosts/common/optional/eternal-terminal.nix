{
  pkgs,
  lib,
  ...
}:
{
  # Enable Eternal Terminal daemon
  # https://eternalterminal.dev/
  services.eternal-terminal = {
    enable = true;
    port = 2022;
  };

  # Open ET port only on tailscale interface for security
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 2022 ];
  };
}
