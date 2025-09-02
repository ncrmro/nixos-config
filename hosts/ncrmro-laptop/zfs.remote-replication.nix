{
  pkgs,
  config,
  lib,
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
    path = with pkgs; [
      config.boot.zfs.package
      openssh
      perl
      pv
      mbuffer
      lzop
      gzip
      inetutils
    ];
    script = ''
      # Sync rpool/crypt datasets to maia.mercury
      /run/current-system/sw/bin/syncoid \
        --recursive \
        --no-privilege-elevation \
        --sshkey /home/ncrmro/.ssh/id_ed25519 \
        --identifier "laptop-$(hostname)" \
        rpool/crypt laptop-sync@maia.mercury:lake/backups/ncrmro-laptop
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root"; # Need root to access ZFS
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
    };
  };

  # Ensure sanoid is installed
  environment.systemPackages = with pkgs; [
    sanoid # For ZFS snapshot management and replication
  ];
}
