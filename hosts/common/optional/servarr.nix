{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  # Base SABnzbd config (non-sensitive settings)
  sabnzbdBaseConfig = pkgs.writeText "sabnzbd-base.ini" ''
    [misc]
    host = 0.0.0.0
    port = 8085
    host_whitelist = sabnzbd.ncrmro.com, localhost, 127.0.0.1
    enable_https = 0
    api_key = __API_KEY__
    nzb_key = __NZB_KEY__
    schedlines = 1 0 7 1234567 speedlimit 10M, 1 0 23 1234567 speedlimit 0
    # inet_exposure = 4 enables Full Web Interface
    # This is safe because access is restricted to Tailscale network only via:
    # 1. Firewall: Port 8085 only allowed on tailscale0 interface
    # 2. nginx reverse proxy with Tailscale IP restrictions
    inet_exposure = 4
    download_dir = /ocean/downloads/usenet/incomplete
    complete_dir = /ocean/downloads/usenet/complete
    log_dir = /var/lib/sabnzbd/logs
    nzb_backup_dir = /var/lib/sabnzbd/backup
    admin_dir = /var/lib/sabnzbd/admin
    cache_dir = /var/lib/sabnzbd/cache
    dirscan_dir = /var/lib/sabnzbd/nzb
    permissions = 660
    folder_permissions = 770

    [logging]
    max_log_size = 5242880
    log_backups = 5

    [categories]
    [[*]]
    name = *
    order = 0
    dir =
    newzbin =
    priority = 0

    [[movies]]
    name = movies
    order = 1
    dir = /ocean/downloads/usenet/complete/movies
    newzbin =
    priority = 0

    [[tv]]
    name = tv
    order = 2
    dir = /ocean/downloads/usenet/complete/tv
    newzbin =
    priority = 0

    [[music]]
    name = music
    order = 3
    dir = /ocean/downloads/usenet/complete/music
    newzbin =
    priority = 0

    [[prowlarr]]
    name = prowlarr
    order = 4
    dir = /ocean/downloads/usenet/complete/prowlarr
    newzbin =
    priority = 0
  '';
in
{
  # Allow unfree packages needed by sabnzbd (unrar)
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "unrar"
    ];

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

  services.transmission = {
    enable = true;
    openFirewall = false;
    group = "media";
    settings = {
      rpc-bind-address = "0.0.0.0";
      rpc-port = 9091;
      rpc-whitelist-enabled = false;
      rpc-host-whitelist-enabled = false;
      download-dir = "/ocean/downloads/torrents/complete";
      incomplete-dir = "/ocean/downloads/torrents/incomplete";
      incomplete-dir-enabled = true;
      umask = 7; # Results in 770/660 permissions (group writable)
    };
  };

  # SABnzbd server credentials (usenet providers)
  age.secrets.sabnzbd-servers = {
    file = ../../../secrets/sabnzbd-servers.age;
    owner = "sabnzbd";
    group = "media";
    mode = "0440";
  };

  services.sabnzbd = {
    enable = true;
    group = "media";
  };

  # Combine base config with encrypted server credentials before sabnzbd starts
  systemd.services.sabnzbd = {
    preStart = lib.mkBefore ''
      # Start with base config
      cp ${sabnzbdBaseConfig} /var/lib/sabnzbd/sabnzbd.ini

      # Read API keys from secret file and substitute placeholders
      # Handles both "key=value" and "key = value" formats
      API_KEY=$(${pkgs.gnugrep}/bin/grep -m1 -E '^api_key\s*=' ${config.age.secrets.sabnzbd-servers.path} | ${pkgs.gnused}/bin/sed 's/^api_key\s*=\s*//')
      NZB_KEY=$(${pkgs.gnugrep}/bin/grep -m1 -E '^nzb_key\s*=' ${config.age.secrets.sabnzbd-servers.path} | ${pkgs.gnused}/bin/sed 's/^nzb_key\s*=\s*//')

      echo "DEBUG: API_KEY='$API_KEY' NZB_KEY='$NZB_KEY'" >> /var/lib/sabnzbd/prestart.log
      echo "DEBUG: Secret file contents:" >> /var/lib/sabnzbd/prestart.log
      head -5 ${config.age.secrets.sabnzbd-servers.path} >> /var/lib/sabnzbd/prestart.log

      ${pkgs.gnused}/bin/sed -i "s/__API_KEY__/$API_KEY/" /var/lib/sabnzbd/sabnzbd.ini
      ${pkgs.gnused}/bin/sed -i "s/__NZB_KEY__/$NZB_KEY/" /var/lib/sabnzbd/sabnzbd.ini

      # Append [servers] section from secret
      ${pkgs.gnused}/bin/sed -n '/^\[servers\]/,$p' ${config.age.secrets.sabnzbd-servers.path} >> /var/lib/sabnzbd/sabnzbd.ini

      chown sabnzbd:media /var/lib/sabnzbd/sabnzbd.ini
      chmod 0600 /var/lib/sabnzbd/sabnzbd.ini
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
