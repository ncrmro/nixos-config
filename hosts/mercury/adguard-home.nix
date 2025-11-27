{config, ...}: let
  # Mercury's Tailscale IP address
  tailscaleIP = "100.64.0.38";
in {
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    # Do not open firewall - we only want to serve on Tailscale interface
    openFirewall = false;
    allowDHCP = false;

    settings = {
      # Bind HTTP interface to localhost for nginx proxy
      http = {
        address = "127.0.0.1:3000";
      };

      # Bind DNS server to Tailscale IP only
      dns = {
        bind_hosts = [tailscaleIP];
        port = 53;
      };
    };
  };

  # Open firewall only on Tailscale interface
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [
      53 # DNS
    ];
    allowedUDPPorts = [
      53 # DNS
    ];
  };
}
