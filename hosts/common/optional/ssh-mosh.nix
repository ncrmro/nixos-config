{
  pkgs,
  lib,
  ...
}: {
  # Enable Mosh (Mobile Shell)
  # Mosh is a remote terminal application that allows roaming and supports intermittent connectivity
  # https://mosh.org/
  programs.mosh = {
    enable = true;
    # Disable automatic firewall rule opening - we'll configure it manually for tailscale only
    openFirewall = false;
  };

  # Install mosh package system-wide
  environment.systemPackages = with pkgs; [
    mosh
  ];

  # Open Mosh UDP ports only on tailscale interface
  # Mosh uses UDP ports 60000-61000 for roaming shell sessions
  networking.firewall.interfaces."tailscale0" = {
    allowedUDPPorts = lib.range 60000 61000;
  };
}
