{
  lib,
  config,
  utils,
  ...
}: {
  imports = [
    ../../modules/users/media.nix
  ];
  # This configuration ensures the ZFS pool "ocean" is imported after boot
  # and does not block the boot process if there's an error with the pool
  #
  # SETUP NOTES:
  # 1. Create the "ocean" ZFS pool on additional storage devices
  # 2. The k3s storage classes reference "ocean/crypt/kube-pv" so ensure
  #    the pool has the proper dataset structure for Kubernetes storage
  # 3. Service will attempt import regardless of disk presence to support disk swapping

  # Create a systemd service that runs after boot is complete
  systemd.services.import-ocean = {
    description = "Import ZFS pool 'ocean' after boot";

    # Run after the system is fully booted
    wantedBy = ["multi-user.target"];
    after = ["multi-user.target"];

    # Don't prevent boot from completing if this service fails
    # No ConditionPathExists - service will run even if specific disks aren't present
    # This allows for disk swapping scenarios where pools may be temporarily unavailable
    unitConfig = {};

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = "2min";
      Restart = "no";
    };

    path = [config.boot.zfs.package];
    script = ''
      # Only attempt import if the pool isn't already imported
      if ! zpool list ocean > /dev/null 2>&1; then
        # Try to import the pool but don't fail the service if it doesn't work
        zpool import -d /dev/disk/by-id ocean || true
      fi

      # Set proper ownership for /ocean/media after pool import
      if [ -d "/ocean/media" ]; then
        chown media:media /ocean/media
        chmod 770 /ocean/media
      fi
    '';
  };
}
