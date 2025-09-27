# ZFS Backup Shares for Mac and Windows via SMB/CIFS

**Investigation Date:** 2025-01-26  
**Status:** Spike Research Complete  
**Goal:** Create network shares on ZFS datasets that Mac and Windows machines can backup to

## Executive Summary

This spike investigates setting up SMB/CIFS shares on ZFS datasets for cross-platform backup solutions, particularly focusing on macOS Time Machine and Windows backup compatibility. The research shows that SMB is the preferred protocol moving forward, as AFP is being deprecated by Apple in 2025.

## Key Findings

### Current Infrastructure Analysis

Our existing setup shows:
- **Ocean** (`/home/ncrmro/nixos-config/hosts/ocean/`) serves as the primary NAS with ZFS storage
- **Current NFS Setup**: Ocean already exports NFS shares (`/guest`, `/ocean/media`) on Tailscale network (100.64.0.0/10)
- **ZFS User Management**: Dedicated sync users (maia-sync, laptop-sync) for ZFS replication
- **Network**: Tailscale mesh networking with static IP assignments

### Protocol Recommendations

1. **SMB/CIFS is the Future**: Apple is removing AFP support entirely in upcoming macOS versions (likely macOS 16)
2. **Time Machine via SMB**: Modern macOS versions support Time Machine over SMB with proper configuration
3. **Cross-platform Compatibility**: SMB works natively on Windows, macOS, and Linux

## Technical Implementation

### ZFS Dataset Structure

Based on existing patterns, create dedicated backup datasets:

```bash
# Create backup datasets
zfs create ocean/backups/timemachine
zfs create ocean/backups/windows
zfs create ocean/backups/general

# Set appropriate permissions and quotas
zfs set quota=500G ocean/backups/timemachine
zfs set quota=1T ocean/backups/windows
zfs set compression=lz4 ocean/backups/timemachine
zfs set compression=lz4 ocean/backups/windows
```

### NixOS Samba Configuration

Create a new optional module `/hosts/common/optional/samba-backup-shares.nix`:

```nix
{ pkgs, ... }: {
  # Enable Samba with full feature set
  services.samba = {
    enable = true;
    package = pkgs.samba4Full;  # Includes Avahi support
    openFirewall = true;
    
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "Ocean NAS";
        "netbios name" = "ocean";
        "security" = "user";
        "hosts allow" = "100.64.0.0/10 127.0.0.1";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        
        # Security settings
        "server smb encrypt" = "required";
        "server min protocol" = "SMB3_00";
        
        # macOS compatibility
        "fruit:aapl" = "yes";
        "fruit:nfs_aces" = "no";
        "fruit:copyfile" = "no";
        "fruit:model" = "MacSamba";
      };
      
      # Time Machine backup share
      "timemachine" = {
        "path" = "/ocean/backups/timemachine";
        "valid users" = "backup";
        "force user" = "backup";
        "force group" = "backup";
        "read only" = "no";
        "browseable" = "yes";
        "create mask" = "0600";
        "directory mask" = "0700";
        
        # Time Machine specific settings
        "fruit:time machine" = "yes";
        "fruit:time machine max size" = "500G";
        "vfs objects" = "catia fruit streams_xattr";
      };
      
      # Windows backup share
      "windows-backup" = {
        "path" = "/ocean/backups/windows";
        "valid users" = "backup";
        "force user" = "backup";
        "force group" = "backup";
        "read only" = "no";
        "browseable" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
        "vfs objects" = "catia streams_xattr";
      };
      
      # General backup share
      "backup" = {
        "path" = "/ocean/backups/general";
        "valid users" = "backup";
        "force user" = "backup";
        "force group" = "backup";
        "read only" = "no";
        "browseable" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
    };
  };
  
  # Enable Samba Web Service Discovery
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };
  
  # Enable Avahi for service discovery
  services.avahi = {
    enable = true;
    publish.enable = true;
    publish.userServices = true;
    extraServiceFiles = {
      smb = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
        </service-group>
      '';
      timemachine = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_adisk._tcp</type>
            <txt-record>sys=waMa=0,adVF=0x100</txt-record>
            <txt-record>dk0=adVN=timemachine,adVF=0x82</txt-record>
          </service>
        </service-group>
      '';
    };
  };
  
  # Create backup user and group
  users.groups.backup = {};
  users.users.backup = {
    isSystemUser = true;
    group = "backup";
    home = "/ocean/backups";
    createHome = false;
  };
  
  # Ensure backup directories exist with correct permissions
  systemd.tmpfiles.rules = [
    "d /ocean/backups 0755 backup backup -"
    "d /ocean/backups/timemachine 0700 backup backup -"
    "d /ocean/backups/windows 0755 backup backup -"
    "d /ocean/backups/general 0755 backup backup -"
  ];
  
  # Set up Samba password on first boot
  system.activationScripts.samba_user_setup = ''
    if [ ! -f /var/lib/samba/private/smbpasswd ]; then
      echo "Setting up Samba backup user..."
      ${pkgs.samba}/bin/smbpasswd -a -n backup
      echo "Please run 'sudo smbpasswd backup' to set password"
    fi
  '';
}
```

### Integration with Existing Infrastructure

1. **Add to Ocean Host**: Import the module in `/hosts/ocean/default.nix`
2. **ZFS Permissions**: Grant backup user access to datasets
3. **Firewall**: Samba ports are auto-opened with `openFirewall = true`
4. **Tailscale Integration**: Shares accessible on Tailscale network

## Client Configuration

### macOS Time Machine Setup

1. Connect to share: `smb://100.64.0.6/timemachine`
2. Enter credentials for 'backup' user
3. Open Time Machine preferences
4. Select the mounted share as backup destination

### Windows Backup Setup

1. Map network drive: `\\100.64.0.6\windows-backup`
2. Use Windows Backup and Restore or File History
3. Point backup destination to mapped drive

### Manual File Backups

Both platforms can access the general backup share:
- macOS: `smb://100.64.0.6/backup`
- Windows: `\\100.64.0.6\backup`

## Security Considerations

1. **Network Isolation**: Shares restricted to Tailscale network (100.64.0.0/10)
2. **Encryption**: SMB3+ with server-side encryption required
3. **User Authentication**: Dedicated backup user with Samba password
4. **File Permissions**: Restrictive umask for sensitive backup data

## Benefits of This Approach

1. **Future-Proof**: SMB is the long-term standard, AFP is being deprecated
2. **Cross-Platform**: Works with macOS, Windows, and Linux clients
3. **ZFS Features**: Compression, snapshots, and replication for backup data
4. **Network Efficiency**: Runs over existing Tailscale infrastructure
5. **Service Discovery**: Avahi enables automatic share discovery

## Migration from Existing NFS

If needed, existing NFS clients can gradually migrate:
1. Keep NFS exports for existing clients
2. Test SMB shares with new clients
3. Gradually migrate NFS clients to SMB
4. Deprecate NFS exports when no longer needed

## Next Steps

1. Implement the Samba configuration module
2. Test with macOS Time Machine backup
3. Test with Windows File History/Backup
4. Document client setup procedures
5. Consider automating Samba user password management

## References

- [NixOS Samba Wiki](https://nixos.wiki/wiki/Samba)
- [Setting up Samba shares on NixOS with macOS Time Machine](https://carlosvaz.com/posts/setting-up-samba-shares-on-nixos-with-support-for-macos-time-machine-backups/)
- [AFP Support Disappearing - TidBITS](https://tidbits.com/2025/05/23/afp-support-disappearing-another-nail-in-the-time-capsule-coffin/)
- Current Ocean NFS configuration: `hosts/ocean/nfs.nix`
- Current NFS client configuration: `hosts/common/optional/nfs-client.nix`