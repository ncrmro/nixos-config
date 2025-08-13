## NixOS configuration (flake)

This repository contains my NixOS flake and host configurations. It includes installation instructions (including nixos-anywhere), ZFS notes, Secure Boot (lanzaboote), TPM enrollment, and a few handy post-install commands.

### Requirements
- Nix with flakes enabled
- For remote installs: SSH access as root to the target host
- For ZFS systems: a stable networking host ID

### Useful one-liners
```bash
# Lock flake inputs
nix flake lock

# Tools for installation and disk ops
nix profile add nixpkgs#nixos-install-tools

# Generate a generic hardware config without filesystems (dry-run/rooted)
nixos-generate-config --root /tmp/config --no-filesystems
```

### Generate a host ID (ZFS)
ZFS-based systems require a networking host ID.
```bash
head -c 8 /etc/machine-id 2>/dev/null || head -c 8 /proc/sys/kernel/random/uuid | tr -d '-'
```
Set this in your host config as needed.

### Install with nixos-anywhere
Docs: `github:nix-community/nixos-anywhere`

- VM test install (local emulated install of a host):
```bash
nix run github:nix-community/nixos-anywhere -- --flake .#mox --vm-test
```

- Remote host install (replace values accordingly):
```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#test-vm \
  --generate-hardware-config nixos-generate-config ./hosts/test-vm/hardware-configuration.nix \
  root@192.168.122.62
```

The installer will hang after completing, run this command on the install host

```bash
cryptsetup luksClose /dev/mapper/credstore
```

### Secure Boot (lanzaboote)
Follow the lanzaboote quickstart after first boot:
- Reference: [lanzaboote Quickstart](https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md)

```bash
bootctl status
sudo sbctl create-keys
sudo sbctl enroll-keys --microsoft
sudo reboot now
```

### TPM2 enrollment for ZFS keyslots
After Secure Boot, enroll the TPM2 for your encrypted datasets. Adjust device paths as needed.
```bash
systemd-cryptenroll /dev/zvol/rpool/credstore --wipe-slot=empty --tpm2-device=auto --tpm2-pcrs=1,7
```

### Post-install checklist
- Turn off emergency access
- Enable/verify Secure Boot
- TPM2 enrollment
- Copy WireGuard keys/configs

### Updating or deploying to a host
Replace host and address as appropriate.
```bash
# Deploy to a remote host using the flake host
nixos-rebuild switch --flake .#testbox --target-host "root@192.168.1.123"
```

### Home Manager
Switch user configuration via Home Manager (adjust user/host):
```bash
home-manager switch --flake /etc/nixos/flake/#ncrmro@mox
```

### Fingerprint enrollment (fprintd)
Add to your host config:
```nix
systemd.services.fprintd = {
  wantedBy = [ "multi-user.target" ];
  serviceConfig.Type = "simple";
};
services.fprintd.enable = true;
```
Then enroll:
```bash
fprintd-enroll
```

### ZFS snapshot policy tweaks
Optional dataset settings:
```bash
zfs set com.sun:auto-snapshot=false rpool/crypt/system/nix
zfs set syncoid:no-sync=true rpool/crypt/system/nix
```

### Mounting an old Ubuntu disk (LUKS + LVM)
Adjust device identifiers to your disk.
```bash
sudo cryptsetup luksOpen /dev/disk/by-id/ata-Samsung_SSD_980_PRO_2TB_S6B0NL0W127373V-part3 oldroot
sudo vgscan
mkdir -p /media/oldroot
sudo mount /dev/mapper/vgubuntu-root /media/oldroot/
```
When finished:
```bash
sudo umount /media/oldroot
sudo vgexport vgubuntu
sudo cryptsetup luksClose oldroot
```
