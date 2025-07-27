

nix profile add nixpkgs#nixos-install-tools 

nixos-generate-config --root /tmp/config --no-filesystems

nix run github:nix-community/nixos-anywhere -- --flake .#mox --vm-test

```shell
nix flake lock
```

ZFS based systems require a networking host id, one can be generated like so.

```shell
head -c 8 /etc/machine-id 2>/dev/null || head -c 8 /proc/sys/kernel/random/uuid | tr -d '-'
```


```shell
nix run github:nix-community/nixos-anywhere -- \
--flake .#test-vm \
--generate-hardware-config nixos-generate-config ./hosts/test-vm/hardware-configuration.nix \
root@192.168.122.62
```

```shell
nix run github:nix-community/nixos-anywhere -- \
--flake .#testbox \
--generate-hardware-config nixos-generate-config ./hosts/testbox/hardware-configuration.nix \
root@192.168.1.123
```

```shell
cryptsetup luksClose /dev/mapper/credstore
```

```shell
nixos-rebuild switch --flake .#testbox --target-host "root@192.168.1.123"
```
```shell
home-manager switch --flake /etc/nixos/flake/#ncrmro@mox
```

---

See [lanzaboote Quickstart](https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md)

```shell
sudo sbctl create-keys
```

## Enrolling Finger print

Add the following to the config 

```nix
systemd.services.fprintd = {
  wantedBy = [ "multi-user.target" ];
  serviceConfig.Type = "simple";
};
services.fprintd.enable = true;
```

```shell
fprintd-enroll
```