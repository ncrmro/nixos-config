{ ... }:
{
  imports = [
    ../../../modules/users/media.nix
  ];

  boot.supportedFilesystems = [ "nfs" ];
  services.rpcbind.enable = true; # needed for NFS

  systemd.mounts = [
    {
      type = "nfs";
      mountConfig = {
        Options = "noatime";
      };
      what = "100.64.0.6:/guest";
      where = "/ocean/guest";
    }
    {
      type = "nfs";
      mountConfig = {
        Options = "noatime";
      };
      what = "100.64.0.6:/ocean/media";
      where = "/ocean/media";
    }
  ];

  systemd.automounts = [
    {
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = "/ocean/guest";
    }
    {
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = "/ocean/media";
    }
  ];

  # Ensure the mount points exist
  systemd.tmpfiles.rules = [
    "d /ocean/guest 0755 root root -"
    "d /ocean/media 0770 media media -"
  ];
}
