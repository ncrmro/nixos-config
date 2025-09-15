{...}: {
  boot.supportedFilesystems = ["nfs"];
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
  ];

  systemd.automounts = [
    {
      wantedBy = ["multi-user.target"];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = "/ocean/guest";
    }
  ];

  # Ensure the mount point exists
  systemd.tmpfiles.rules = [
    "d /ocean/guest 0755 root root -"
  ];
}
