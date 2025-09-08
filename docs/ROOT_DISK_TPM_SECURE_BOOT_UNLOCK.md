# Root Disk TPM + Secure Boot Unlock

## Secure Boot (lanzaboote)

Follow the lanzaboote quickstart after first boot:
- Reference: [lanzaboote Quickstart](https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md)

First, generate the secure boot keys:
```bash
nix-shell -p sbctl
sudo sbctl create-keys
```

Expected output:
```
Created Owner UUID 8ec4b2c3-dc7f-4362-b9a3-0cc17e5a34cd
Creating secure boot keys...✓
Secure boot keys created!
```

**Note:** Now add `inputs.lanzaboote.nixosModules.lanzaboote` module to your host nix file.

Then continue with the setup:
```bash
bootctl status
sudo sbctl enroll-keys --microsoft
sudo reboot now
```

## TPM2 enrollment for ZFS keyslots

After Secure Boot, enroll the TPM2 for your encrypted datasets. Adjust device paths as needed.

```bash
systemd-cryptenroll /dev/zvol/rpool/credstore --wipe-slot=empty --tpm2-device=auto --tpm2-pcrs=1,7
```

You should now be able to reboot without having to provide the password. 


# Verification and Explination of TPM PCRS

You can verify the TPM attestion works by turning of secureboot, updating the bios, changing hardware etc.
