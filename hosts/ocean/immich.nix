{ pkgs, ... }:
{
  services.immich = {
    enable = true;
    host = "127.0.0.1";
    mediaLocation = "/ocean/media/photos";
  };

  # Ensure immich owns the media directory on startup
  # Fixes permission issues when files are created by other processes
  systemd.services.immich-server.serviceConfig.ExecStartPre = [
    "+${pkgs.coreutils}/bin/chown -R immich:immich /ocean/media/photos"
  ];
}
