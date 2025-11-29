# OctoPrint - Web interface for 3D printers
# Only accessible via Tailscale IP for security
{
  config,
  lib,
  ...
}: let
  # Ocean's Tailscale IP address
  tailscaleIP = "100.64.0.6";
in {
  services.octoprint = {
    enable = true;
    # Bind only to Tailscale interface
    host = tailscaleIP;
    port = 5000;
    # Don't open firewall globally - we configure Tailscale-only access below
    openFirewall = false;
  };

  # Open firewall only on Tailscale interface
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [5000];
  };

  # Allow octoprint user to access USB devices (for 3D printer communication)
  users.users.octoprint.extraGroups = ["dialout"];
}
