{ pkgs, ... }:
{
  services.immich = {
    enable = true;
    host = "127.0.0.1";
    mediaLocation = "/ocean/media/photos";
  };

  # immich needs media group to traverse /ocean/media/ (770 media:media)
  users.users.immich.extraGroups = [ "media" ];

  systemd.services.immich-server.serviceConfig = {
    # Also grant media group inside the systemd sandbox
    SupplementaryGroups = [ "media" ];
    # Ensure immich owns the photos directory on startup
    ExecStartPre = [
      "+${pkgs.coreutils}/bin/chown -R immich:immich /ocean/media/photos"
    ];
  };
}
