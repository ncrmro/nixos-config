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

  # Configure syncoid for automatic local backup
  services.syncoid = {
    enable = true;
    interval = "hourly";
    user = "root"; # Need root for local ZFS access

    commands."rpool-to-ocean" = {
      source = "rpool";
      target = "ocean/backups/ocean/rpool";
      recursive = true;
      sendOptions = "w"; # raw send to preserve encryption
      extraArgs = [
        "--no-sync-snap"
        "--identifier=ocean-local-backup"
        "--skip-parent"
        "--include-snaps=autosnap"
        "--compress=none"
        "--exclude-datasets=nix$|k3s/server$|k3s/agent$"
      ];
    };
  };
}
