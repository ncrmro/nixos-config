# NFS Share Configuration

## Overview

This document describes the NFS (Network File System) setup for sharing directories across hosts in the network, primarily for media and guest file sharing.

## Server Configuration (Ocean Host)

The ocean host (192.168.1.10 / 100.64.0.6) acts as the NFS server and exports two directories:

### Exported Directories

1. **`/guest`** - Public guest share with open permissions (777)
2. **`/ocean/media`** - Media share with restricted permissions (770)

### Network Access

Both shares are accessible to hosts on the Tailscale network (100.64.0.0/10).

### Configuration Files

- **`hosts/ocean/nfs.nix`** - NFS server configuration and exports
- **`hosts/ocean/zpool.ocean.noblock.nix`** - Sets ownership for `/ocean/media` after ZFS pool import

### Permissions

- `/guest`: 777 (root:root) - Anyone can read/write
- `/ocean/media`: 770 (media:media) - Only media group members can access

## Client Configuration

Clients that need NFS access should import the NFS client configuration module.

### Setup

Add to your host's `default.nix`:

```nix
imports = [
  # ... other imports
  ../common/optional/nfs-client.nix
];
```

### What This Provides

1. **NFS Support** - Enables NFS filesystem support and rpcbind service
2. **Auto-mounting** - Automatically mounts shares on demand with 10-minute idle timeout
3. **Media User/Group** - Creates media user and group for proper permissions
4. **Mount Points**:
   - `/ocean/guest` → ocean:/guest
   - `/ocean/media` → ocean:/ocean/media

### User Access

The `ncrmro` user module (`modules/users/ncrmro.nix`) automatically adds the user to the media group if it exists, granting access to `/ocean/media`.

## Current Clients

Hosts currently configured with NFS client access:
- ncrmro-laptop
- workstation

## Architecture Details

### Module Structure

- **`modules/users/media.nix`** - Defines media user and group
- **`modules/users/ncrmro.nix`** - User configuration with automatic group membership
- **`hosts/common/optional/nfs-client.nix`** - NFS client configuration and mounts

### Key Features

1. **Automatic Group Membership** - Users are added to groups only if they exist using the `ifTheyExist` pattern
2. **Lazy Loading** - NFS shares are mounted on-demand using systemd automounts
3. **Centralized User Management** - Media user/group defined once and imported where needed

## Troubleshooting

### Permission Denied

If you get permission denied accessing `/ocean/media`:
1. Verify you're in the media group: `groups`
2. Log out and back in if recently added to the group
3. Check mount status: `mount | grep ocean`

### Mount Issues

Check if the NFS server is accessible:
```bash
showmount -e 100.64.0.6
```

Check systemd mount status:
```bash
systemctl status ocean-media.mount
systemctl status ocean-media.automount
```

### Firewall

The ocean host opens the following ports for NFS:
- TCP/UDP 111 (rpcbind)
- TCP/UDP 2049 (nfsd)
- TCP/UDP 4000-4002 (statd, lockd, mountd)