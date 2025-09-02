# ZFS Incremental Snapshot Replication: ncrmro-laptop to maia/lake

This spike outlines a process for setting up incremental ZFS snapshot replication from `ncrmro-laptop` to the ZFS pool `lake` on the host `maia`.

## Current State

- `ncrmro-laptop` has ZFS auto-snapshots enabled (`services.zfs.autoSnapshot.enable = true`)
- `maia` has a ZFS pool named `lake` that is encrypted
- No replication is currently configured between hosts

## Design Goals

1. Automatically create and maintain regular snapshots on `ncrmro-laptop`
2. Securely transfer only incremental changes to `maia`
3. Maintain a reliable backup of important datasets
4. Automate the process with appropriate scheduling

## Implementation Plan

### 1. Snapshot Management with Sanoid

Replace the auto-snapshot service with Sanoid for more fine-grained control:

```nix
# In hosts/ncrmro-laptop/default.nix
services.zfs.autoSnapshot.enable = false; # Disable default auto-snapshot
services.sanoid = {
  enable = true;
  datasets = {
    "rpool" = {
      recursive = true;
      processChildrenOnly = true;
      hourly = 36;
      daily = 30;
      monthly = 3;
      yearly = 1;
      autosnap = true;
      autoprune = true;
    };
    # Additional datasets with custom retention policies as needed
    "rpool/safe/home" = {
      hourly = 48;
      daily = 60;
      monthly = 12;
      yearly = 2;
      autosnap = true;
      autoprune = true;
    };
  };
};
```

### 2. SSH Key-Based Authentication

Create a dedicated SSH key pair for ZFS replication:

```bash
# On ncrmro-laptop
ssh-keygen -t ed25519 -f /etc/ssh/zfs_replication -C "ZFS replication key"

# Add the public key to authorized_keys on maia
# In your NixOS configuration (modules/users/ncrmro.nix or similar)
users.users.ncrmro.openssh.authorizedKeys.keys = [
  # existing keys...
  "ssh-ed25519 AAAAB3NzaC1... ZFS replication key"
];
```

### 3. Syncoid Configuration for Replication

Install and configure syncoid (part of the sanoid package) to handle replication:

```nix
# In hosts/ncrmro-laptop/default.nix
environment.systemPackages = with pkgs; [
  # existing packages...
  sanoid # includes syncoid
];
```

### 4. Systemd Service for Replication

Create a systemd service to run the replication:

```nix
# New module: modules/nixos/zfs-replication.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.zfsReplication;
in {
  options.services.zfsReplication = {
    enable = mkEnableOption "ZFS replication to remote hosts";
    
    sourceDatasets = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of ZFS datasets to replicate";
    };
    
    targetHost = mkOption {
      type = types.str;
      description = "Hostname or IP of the target machine";
    };
    
    targetPool = mkOption {
      type = types.str;
      description = "Target ZFS pool on the remote host";
    };
    
    sshKeyPath = mkOption {
      type = types.str;
      default = "/etc/ssh/zfs_replication";
      description = "Path to the SSH private key for authentication";
    };
    
    interval = mkOption {
      type = types.str;
      default = "hourly";
      description = "How often to run the replication (hourly, daily, weekly)";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.zfs-replication = {
      description = "ZFS dataset replication to remote host";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = with pkgs; [ sanoid openssh ];
      
      script = ''
        ${concatMapStringsSep "\n" (dataset: ''
          syncoid \
            --sshkey=${cfg.sshKeyPath} \
            --no-sync-snap \
            --create-bookmark \
            ${dataset} \
            ${cfg.targetHost}:${cfg.targetPool}/backups/${baseNameOf dataset}
        '') cfg.sourceDatasets}
      '';
      
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
    
    # Create appropriate timer based on interval
    systemd.timers.zfs-replication = {
      description = "Timer for ZFS replication";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnCalendar = {
          "hourly" = "hourly";
          "daily" = "daily";
          "weekly" = "weekly";
        }.${cfg.interval};
        Persistent = true;
        RandomizedDelaySec = "15m";
      };
    };
  };
}
```

### 5. Implementation on ncrmro-laptop

Add the replication configuration to ncrmro-laptop:

```nix
# In hosts/ncrmro-laptop/default.nix
imports = [
  # existing imports...
  ../../modules/nixos/zfs-replication.nix
];

services.zfsReplication = {
  enable = true;
  sourceDatasets = [
    "rpool/safe/home"
    "rpool/safe/data"
    # Add other important datasets
  ];
  targetHost = "maia";
  targetPool = "lake";
  interval = "daily";
};
```

### 6. Prepare Target Datasets on maia

Create the target datasets on maia to receive the backups:

```nix
# In hosts/maia/zpool.lake.nix or appropriate file
boot.zfs.extraPools = [ "lake" ];

# Or manually:
# zfs create lake/backups
# zfs create lake/backups/rpool-safe-home
# zfs create lake/backups/rpool-safe-data
```

## Security Considerations

1. The SSH key for replication should have restricted permissions:
   - Use the `command=` prefix in authorized_keys to restrict what commands can be run
   - Consider using a dedicated user for replication

2. Encrypt the data in transit:
   - SSH already provides encryption for the transfer
   - Both source and target pools are already encrypted at rest

3. Network security:
   - Consider using Tailscale or WireGuard for an encrypted tunnel
   - Restrict SSH access to specific IP addresses if possible

## Testing Procedure

1. Initial test with small dataset:
   ```bash
   # Manual test of syncoid
   syncoid --sshkey=/etc/ssh/zfs_replication --dryrun rpool/test ncrmro@maia:lake/backups/test
   ```

2. Monitor first full replication:
   ```bash
   # Run service manually and observe
   systemctl start zfs-replication.service
   journalctl -fu zfs-replication.service
   ```

3. Verify incremental replication:
   - Make changes to source dataset
   - Run replication again
   - Verify only changes were transferred

4. Test recovery:
   ```bash
   # On maia, try restoring data
   zfs send lake/backups/rpool-safe-home@snapshot | zfs receive rpool/restore
   ```

## Monitoring and Maintenance

1. Set up monitoring for replication failures:
   ```nix
   systemd.services.zfs-replication.serviceConfig.OnFailure = "status-email@%n.service";
   ```

2. Regular verification of backup integrity:
   ```bash
   # Add to cron job or systemd timer
   zfs list -t snapshot -o name,creation,used,referenced lake/backups
   ```

3. Periodically test restoration to ensure backups are usable

## Future Improvements

1. Implement bidirectional replication if needed
2. Add bandwidth throttling options for large datasets
3. Consider more advanced tools like zrepl for complex scenarios
4. Set up monitoring and alerting for replication failures
5. Add compression for network transfer to reduce bandwidth usage