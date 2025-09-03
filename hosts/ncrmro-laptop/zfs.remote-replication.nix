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
    enable = false;
    datasets = {
      "rpool" = {
        recursive = true;
        processChildrenOnly = true;
        hourly = 36;
        daily = 30;
        monthly = 3;
        yearly = 0;
        autosnap = true;
        autoprune = true;
      };
    };
  };

  # Configure syncoid for automatic snapshot replication to maia.mercury
  systemd.services.syncoid-to-maia = {
    description = "Sync ZFS snapshots to maia.mercury backup server";
    wants = ["network-online.target"];
    after = ["network-online.target"];
    startAt = "hourly"; # Run hourly
    path = with pkgs;
      [
        config.boot.zfs.package
        openssh
        perl
        pv
        mbuffer
        lzop
        gzip
        inetutils
      ]
      ++ [
        inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.sanoid # Use unstable version
      ];
    script = ''
      # Sync rpool/crypt datasets to maia.mercury
      ${inputs.nixpkgs-unstable.legacyPackages.${pkgs.system}.sanoid}/bin/syncoid \
        --no-privilege-elevation \
        --no-sync-snap \
        --sshkey /home/ncrmro/.ssh/id_ed25519 \
        --identifier "laptop-$(hostname)" \
        --skip-parent \
        --preserve-properties \
        --recursive \
        --include-snaps autosnap \
        --compress=none \
        --sendoptions="raw" \
        --exclude-datasets='docker|containers|images|nix|libvirt'\
        rpool laptop-sync@maia.mercury:lake/backups/ncrmro-laptop/rpool
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root"; # Need root to access ZFS
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
    };
  };

  # This is handled by the common module now (using unstable version)
}
