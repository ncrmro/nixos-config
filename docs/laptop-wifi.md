# Laptop WiFi Breakage: Generation 312 vs 316

## Summary

WiFi broke after updating NixOS generations. Rolled back by selecting older generation at boot.

- **Working:** Generation 312 — NixOS `26.05.20251228.c0b0e0f`, kernel `6.12.63`
- **Broken:** Generation 316 — NixOS `26.05.20260204.00c21e4`, kernel `6.12.68`
- **Hardware:** MediaTek MT7922 802.11ax (`mt7921e` driver), interface `wlp1s0`
- **Error:** `802-11-wireless-security.key-mgmt: property is missing`

## Root Cause

Known NetworkManager bug (NM 1.50+) where `nmcli device wifi connect <SSID> password <password>` fails because NM no longer auto-infers the `key-mgmt` security property. Both generations have NM 1.54.3 and wpa_supplicant 2.11. The NM rebuild against newer dependencies (systemd 258.2 → 258.3) likely triggers different connection profile validation behavior.

**NOT a kernel, firmware, or driver issue.** MT7922 firmware is byte-identical between generations.

## Package Diff (WiFi/Networking)

| Package | Working (312) | Broken (316) | Notes |
|---------|--------------|-------------|-------|
| networkmanager | 1.54.3 | 1.54.3 | Same version, different store path |
| wpa_supplicant | 2.11 | 2.11 | Same version, different store path |
| systemd | 258.2 | 258.3 | Minor bump — likely culprit |
| linux kernel | 6.12.63 | 6.12.68 | Not the wifi culprit |
| linux-firmware | 20251125-unstable | 20260110 | MT7922 firmware identical |
| wireless-tools | 30.pre9 | REMOVED | Cosmetic — NM doesn't use these |
| dnsmasq | 2.91 | 2.92 | Used by NM for DNS |
| ell | 0.80 | 0.81 | Embedded Linux Library |

### NetworkManager.conf Diff

Only change — two new unmanaged device patterns (does NOT affect wifi `wlp1s0`):
```
- unmanaged-devices=interface-name:virbr*;interface-name:vnet*
+ unmanaged-devices=interface-name:virbr*;interface-name:vnet*;interface-name:br0;interface-name:enp*
```

## Immediate Workarounds (Testing First)

1. **Use `--ask` flag:** `nmcli device wifi connect <SSID> --ask` — interactive password prompt bypasses the bug
2. **Use saved connection:** `nmcli connection up <SSID>` — use previously saved connection profile
3. **Manually add key-mgmt:** Edit `/etc/NetworkManager/system-connections/<SSID>.nmconnection` — ensure `[wifi-security]` section has `key-mgmt=wpa-psk`

## Permanent Fix Options

### Option A: Switch WiFi backend to iwd (recommended)

In `modules/client/services/networking.nix`:
```nix
networking.networkmanager.wifi.backend = "iwd";
networking.wireless.iwd.enable = true;
```

### Option B: Declare WiFi profile via ensureProfiles

```nix
networking.networkmanager.ensureProfiles.profiles.home-wifi = {
  connection = { id = "Comcast2"; type = "wifi"; };
  wifi = { ssid = "Comcast2"; mode = "infrastructure"; };
  wifi-security = { key-mgmt = "wpa-psk"; psk = "$WIFI_PASSWORD"; };
};
```

### Option C: Pin nixpkgs to working commit

Roll back flake.nix nixpkgs input to `c0b0e0f`.

## References

- [Arch Linux Forum — NM key-mgmt property missing](https://bbs.archlinux.org/viewtopic.php?id=300321)
- [Arch Linux Forum — WiFi fails with key-mgmt missing](https://bbs.archlinux.org/viewtopic.php?id=307913)
- [Manjaro Forum — Cannot connect to password-protected wireless](https://forum.manjaro.org/t/cannot-connect-to-any-password-protected-wireless-network-error-802-11-wireless-security-key-mgmt-property-is-missing/172312)
