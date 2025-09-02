# ZFS Remote Replication

This document describes how to set up ZFS snapshot replication between NixOS systems using sanoid and syncoid.

## Overview

ZFS snapshot replication provides a robust backup solution by sending incremental snapshots from one system to another. This guide covers:

1. Setting up snapshot management with sanoid
2. Configuring remote replication with syncoid
3. Automating the process using systemd timers
4. Troubleshooting common issues

## Prerequisites

- ZFS installed on both source and target systems
- SSH connectivity between systems
- Proper user permissions on both systems

## Snapshot Management with Sanoid

[Sanoid](https://github.com/jimsalterjrs/sanoid) is a policy-driven snapshot management tool for ZFS filesystems.

### Installation

In your NixOS configuration:

```nix
environment.systemPackages = [
  pkgs.sanoid
];

services.sanoid = {
  enable = true;
  datasets = {
    "rpool" = {
      recursive = true;
      processChildrenOnly = true;
      hourly = 36;    # Keep 36 hourly snapshots
      daily = 30;     # Keep 30 daily snapshots
      monthly = 3;    # Keep 3 monthly snapshots
      yearly = 0;     # Don't keep yearly snapshots
      autosnap = "yes";
      autoprune = "yes";
    };
  };
};
```

This configuration will automatically create and manage snapshots for all datasets in the `rpool` pool.

## Setting Up Remote Replication with Syncoid

[Syncoid](https://github.com/jimsalterjrs/sanoid) is a companion tool to sanoid that handles replication of ZFS snapshots to a remote system.

### User Setup

1. On the target system (receiver), create a dedicated user for replication:

```nix
# In your target system's configuration.nix
users.users.zfs-receiver = {
  isSystemUser = true;
  shell = pkgs.bash;
  group = "zfs-sync";
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyrDBVcGK+pUZOTUA7MLoD5vYK/kaPF6TNNyoDmwNl2 source-system-user"
  ];
};
users.groups.zfs-sync = {};
```

2. Grant the user appropriate ZFS permissions on the target system:

```bash
# On the target system
sudo zfs create -p targetpool/backups/sourcesystem
sudo zfs allow zfs-receiver create,receive,mount,compression,mountpoint,readonly targetpool/backups/sourcesystem
```

### Configuring Syncoid Service

On the source system, create a systemd service to handle replication:

```nix
# In your source system's configuration.nix
systemd.services.syncoid-to-remote = {
  description = "Sync ZFS snapshots to remote backup server";
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
  ];
  script = ''
    # Sync datasets to remote system
    /run/current-system/sw/bin/syncoid \
      --recursive \
      --no-privilege-elevation \
      --sshkey /path/to/ssh/key \
      --identifier "source-$(hostname)" \
      sourcepool/dataset zfs-receiver@remote:targetpool/backups/sourcesystem
  '';
  serviceConfig = {
    Type = "oneshot";
    User = "root"; # Need root to access ZFS
    IOSchedulingClass = "idle";
    CPUSchedulingPolicy = "idle";
  };
};
```

## Example: Laptop to Server Replication

Here's a complete example of replicating data from a laptop to a server named "maia":

### On the server (maia)

```nix
# In hosts/maia/zfs.users.nix
users.users.laptop-sync = {
  isSystemUser = true;
  shell = pkgs.bash;
  group = "zfs-sync";
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyrDBVcGK+pUZOTUA7MLoD5vYK/kaPF6TNNyoDmwNl2 ncrmro@ncrmro-laptop"
  ];
};
users.groups.zfs-sync = {};
```

### On the laptop (ncrmro-laptop)

```nix
# In hosts/ncrmro-laptop/default.nix
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
      autosnap = "yes";
      autoprune = "yes";
    };
  };
};

systemd.services.syncoid-to-maia = {
  description = "Sync ZFS snapshots to maia backup server";
  wants = ["network-online.target"];
  after = ["network-online.target"];
  startAt = "hourly";
  path = with pkgs; [
    config.boot.zfs.package
    openssh
    perl
    pv
    mbuffer
    lzop
    gzip
  ];
  script = ''
    /run/current-system/sw/bin/syncoid \
      --recursive \
      --no-privilege-elevation \
      --sshkey /home/ncrmro/.ssh/id_ed25519 \
      --identifier "laptop-$(hostname)" \
      rpool/crypt laptop-sync@maia:lake/backups/ncrmro-laptop
  '';
  serviceConfig = {
    Type = "oneshot";
    User = "root";
    IOSchedulingClass = "idle";
    CPUSchedulingPolicy = "idle";
  };
};
```

### Initial Setup Script

Run this script once to set up the receiving datasets on the target system:

```bash
#!/usr/bin/env bash
# Setup script for creating receiving datasets on maia

set -e

# Check if we can connect to maia
if ! ssh laptop-sync@maia "echo 'Connection successful'"; then
  echo "Error: Cannot connect to maia as laptop-sync user"
  echo "Make sure SSH key authentication is set up correctly"
  exit 1
fi

# Create the backup dataset on maia
ssh laptop-sync@maia "sudo zfs create -p lake/backups/ncrmro-laptop"

# Set appropriate permissions for the laptop-sync user
ssh laptop-sync@maia "sudo zfs allow laptop-sync create,receive,mount,compression,mountpoint,readonly lake/backups/ncrmro-laptop"

# Set properties on the receiving dataset
ssh laptop-sync@maia "sudo zfs set compression=zstd lake/backups/ncrmro-laptop"
ssh laptop-sync@maia "sudo zfs set mountpoint=/lake/backups/ncrmro-laptop lake/backups/ncrmro-laptop"

echo "Successfully created backup dataset on maia"
```

## Manual Replication

You can also run replication manually:

```bash
# Basic syntax
syncoid [options] SOURCE TARGET

# Example: Local to remote
syncoid rpool/data username@hostname:targetpool/backups/data

# Example: With additional options
syncoid --recursive --no-privilege-elevation --compress=lz4 rpool/data username@hostname:targetpool/backups/data
```

## Restoring from Replicated Snapshots

To restore data from replicated snapshots:

```bash
# View available snapshots
zfs list -t snapshot -o name,creation -s creation targetpool/backups/sourcesystem

# Clone a snapshot to a new dataset for access
zfs clone targetpool/backups/sourcesystem@snapshot targetpool/restore/sourcesystem

# Mount the cloned dataset
zfs set mountpoint=/mnt/restore targetpool/restore/sourcesystem
```

## Troubleshooting

### SSH Issues

If experiencing SSH connectivity problems:

```bash
# Test SSH connection
ssh -i /path/to/ssh/key username@targethost "zfs list"

# Verify SSH key permissions
chmod 600 /path/to/ssh/key
```

### Permission Issues

If encountering ZFS permission errors:

```bash
# Check delegated permissions
zfs allow targetpool/backups/sourcesystem

# Verify dataset existence and properties
zfs get all targetpool/backups/sourcesystem
```

### Service Debugging

To debug the systemd service:

```bash
# Check service status
systemctl status syncoid-to-remote

# View service logs
journalctl -u syncoid-to-remote -f

# Run the service manually for testing
systemctl start syncoid-to-remote
```

## Advanced Options

### Bandwidth Limiting

To limit bandwidth usage:

```bash
# Add to syncoid command
syncoid --mbuffer-size=1G --buffer-size=16M sourcepool/dataset username@targethost:targetpool/backups
```

### Excluding Datasets

To exclude specific datasets from replication:

```bash
# Add to syncoid command
syncoid --recursive --exclude=sourcepool/dataset/excluded sourcepool/dataset username@targethost:targetpool/backups
```

## References

- [Sanoid GitHub Repository](https://github.com/jimsalterjrs/sanoid)
- [ZFS Documentation](https://openzfs.github.io/openzfs-docs/)
- [NixOS ZFS Wiki](https://nixos.wiki/wiki/ZFS)