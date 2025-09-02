{
  lib,
  config,
  utils,
  ...
}: {
  # This configuration ensures the ZFS pool "lake" is imported after boot
  # and does not block the boot process if there's an error with the pool

  # Create a systemd service that runs after boot is complete
  systemd.services.import-lake = {
    description = "Import ZFS pool 'lake' after boot";

    # Run after the system is fully booted
    wantedBy = ["multi-user.target"];
    after = ["multi-user.target"];

    # Don't prevent boot from completing if this service fails
    unitConfig = {
      ConditionPathExists = [
        config.disko.devices.disk.disk2.device
        config.disko.devices.disk.disk3.device
      ];
    };

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "2min";
      Restart = "no";
    };

    path = [config.boot.zfs.package];
    script = ''
      # Only attempt import if the pool isn't already imported
      if ! zpool list lake > /dev/null 2>&1; then
        # Try to import the pool but don't fail the service if it doesn't work
        zpool import -d /dev/disk/by-id lake || true
      fi
    '';
  };
}
