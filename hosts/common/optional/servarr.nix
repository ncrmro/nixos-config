{
  config,
  lib,
  pkgs,
  ...
}: {
  services.jellyfin = {
    enable = true;
    openFirewall = false;
    group = "media";
  };

  services.radarr = {
    enable = true;
    openFirewall = false;
    group = "media";
  };

  services.sonarr = {
    enable = true;
    openFirewall = false;
    group = "media";
  };

  services.prowlarr = {
    enable = true;
    openFirewall = false;
  };

  services.bazarr = {
    enable = true;
    openFirewall = false;
    group = "media";
  };

  services.lidarr = {
    enable = true;
    openFirewall = false;
    group = "media";
  };

  services.readarr = {
    enable = true;
    openFirewall = false;
    group = "media";
  };

  services.jellyseerr = {
    enable = true;
    openFirewall = false;
  };

  # Open ports on tailscale interface only for web UIs
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [
      8096 # Jellyfin
      8920 # Jellyfin HTTPS (optional)
      7878 # Radarr
      8989 # Sonarr
      9696 # Prowlarr
      6767 # Bazarr
      8686 # Lidarr
      8787 # Readarr
      5055 # Jellyseerr
    ];
  };

  # Allow Jellyfin discovery protocols on all interfaces (for LAN clients)
  networking.firewall = {
    allowedUDPPorts = [
      1900 # DLNA/SSDP discovery
      7359 # Jellyfin client discovery
    ];
  };
}
