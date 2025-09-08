# Root Disk TPM + Secure Boot Unlock

## Secure Boot (lanzaboote)

Follow the lanzaboote quickstart after first boot:
- Reference: [lanzaboote Quickstart](https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md)

```bash
bootctl status
sudo sbctl create-keys
sudo sbctl enroll-keys --microsoft
sudo reboot now
```

## TPM2 enrollment for ZFS keyslots

After Secure Boot, enroll the TPM2 for your encrypted datasets. Adjust device paths as needed.

```bash
systemd-cryptenroll /dev/zvol/rpool/credstore --wipe-slot=empty --tpm2-device=auto --tpm2-pcrs=1,7
```