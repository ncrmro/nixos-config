# ZFS snapshot policy tweaks

Optional dataset settings:
```bash
zfs set com.sun:auto-snapshot=false rpool/crypt/system/nix
zfs set syncoid:no-sync=true rpool/crypt/system/nix
```