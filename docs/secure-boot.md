# Secure Boot (lanzaboote)

Follow the lanzaboote quickstart after first boot:
- Reference: [lanzaboote Quickstart](https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md)

```bash
bootctl status
sudo sbctl create-keys
sudo sbctl enroll-keys --microsoft
sudo reboot now
```