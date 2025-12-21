# Host networking notes

## Workstation (ncrmro-workstation)
- IPv4: static `192.168.1.69/24`
- IPv6: static `2600:1702:6250:4c80:2f13:e7b1:1c8e:a6cb/64`
- Gateways: IPv4 `192.168.1.254`, IPv6 `2600:1702:6250:4c80::1`
- DNS/DHCP server: **ocean**
  - IPv4 `192.168.1.10`
  - IPv6 `2600:1702:6250:4c80:da5e:d3ff:fe8e:3126`
- NixOS config: `hosts/workstation/default.nix`
  - `networking.useDHCP = false;`
  - `networking.interfaces.enp5s0` carries the static IPv4/IPv6 addresses
  - `networking.defaultGateway` / `networking.defaultGateway6` set to router
  - `networking.nameservers` uses only ocean (IPv4 + IPv6)

Apply changes with `sudo nixos-rebuild switch` after updating the Nix config.***
