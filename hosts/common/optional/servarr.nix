{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
in {
  # Allow unfree packages needed by sabnzbd (unrar)
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "unrar"
    ];

  services.jellyfin = {
    enable = true;
    package = pkgs-unstable.jellyfin;
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

  services.transmission = {
    enable = true;
    openFirewall = false;
    group = "media";
    settings = {
      rpc-bind-address = "0.0.0.0";
      rpc-port = 9091;
      rpc-whitelist-enabled = false;
      rpc-host-whitelist-enabled = false;
    };
  };

  services.sabnzbd = {
    enable = true;
    group = "media";
    configFile = pkgs.writeText "sabnzbd.ini" ''
      [misc]
      host = 0.0.0.0
      port = 8085
      host_whitelist = sabnzbd.ncrmro.com, localhost, 127.0.0.1
      enable_https = 0
      # inet_exposure = 4 enables Full Web Interface
      # This is safe because access is restricted to Tailscale network only via:
      # 1. Firewall: Port 8080 only allowed on tailscale0 interface (see networking.firewall.interfaces.tailscale0 in this file)
      # 2. Ingress: nginx.ingress.kubernetes.io/whitelist-source-range in hosts/common/kubernetes/servarr.nix
      inet_exposure = 4
      download_dir = /ocean/downloads/usenet/incomplete
      complete_dir = /ocean/downloads/usenet/complete
      log_dir = /var/lib/sabnzbd/logs
      nzb_backup_dir = /var/lib/sabnzbd/backup
      admin_dir = /var/lib/sabnzbd/admin
      cache_dir = /var/lib/sabnzbd/cache
      dirscan_dir = /var/lib/sabnzbd/nzb

      [logging]
      max_log_size = 5242880
      log_backups = 5
    '';
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
      9091 # Transmission
      8085 # SABnzbd
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
