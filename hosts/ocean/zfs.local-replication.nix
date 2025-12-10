{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: {
  # Import the common ZFS remote replication module
  imports = [
    ../common/optional/zfs.remote-replication.nix
  ];

  # Configure sanoid for snapshot management
  services.sanoid = {
    enable = true;
    datasets = {
      "rpool" = {
        recursive = true;
        processChildrenOnly = true;
        hourly = 0; # Disabled (using autoSnapshot instead)
        daily = 7; # Keep 7 daily snapshots
        weekly = 4; # Keep 4 weekly snapshots
        monthly = 6; # Keep 6 monthly snapshots
        yearly = 0; # No yearly snapshots
        autosnap = true; # Tag snapshots for replication
        autoprune = true; # Auto-prune old snapshots
      };
    };
  };

  # Configure syncoid for automatic local backup from rpool to ocean pool
  systemd.services.syncoid-local-backup = {
    description = "Sync rpool snapshots to ocean pool local backup";

    # Don't start on boot, only via timer
    wantedBy = lib.mkForce [];

    # Don't restart during nixos-rebuild (prevents blocking)
    unitConfig = {
      X-RestartIfChanged = false;
    };

    # Dependencies - wait for ocean pool to be imported
    wants = ["import-ocean.service"];
    after = ["import-ocean.service"];
    requires = ["import-ocean.service"]; # Don't run if ocean isn't imported

    # Schedule - run hourly
    startAt = "hourly";

    # Tools in PATH
    path = with pkgs;
      [
        config.boot.zfs.package
        perl
        pv
        mbuffer
        lzop
        gzip
      ]
      ++ [
        inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.sanoid
      ];

    # Replication script
    script = ''
      # Check if ocean pool is imported
      if ! zpool list ocean > /dev/null 2>&1; then
        echo "Ocean pool not imported, skipping backup"
        exit 0
      fi

      # Create parent dataset if it doesn't exist
      if ! zfs list ocean/backups/ocean/rpool > /dev/null 2>&1; then
        echo "Creating parent dataset ocean/backups/ocean/rpool"
        zfs create -p ocean/backups/ocean/rpool
      fi

      # Sync entire rpool to ocean pool
      ${inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.sanoid}/bin/syncoid \
        --no-privilege-elevation \
        --no-sync-snap \
        --identifier "ocean-local-backup" \
        --skip-parent \
        --preserve-properties \
        --recursive \
        --include-snaps autosnap \
        --compress=none \
        --sendoptions="raw" \
        --exclude='nix$|k3s/server$|k3s/agent$' \
        rpool \
        ocean/backups/ocean/rpool
    '';

    serviceConfig = {
      Type = "oneshot";
      User = "root"; # Need root to access ZFS
      IOSchedulingClass = "idle"; # Don't starve other I/O
      CPUSchedulingPolicy = "idle"; # Don't starve CPU
    };
  };
}
