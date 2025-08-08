

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

## ZFS Snapshotting

```
zfs set com.sun:auto-snapshot=false rpool/crypt/system/nix
zfs set syncoid:no-sync=true rpool/crypt/system/nix
```

## Mounting old ubuntu disk

```
sudo cryptsetup luksOpen /dev/disk/by-id/ata-Samsung_SSD_980_PRO_2TB_S6B0NL0W127373V-part3 oldroot
sudo vgscan 
mkdir -p /media/oldroot
sudo mount /dev/mapper/vgubuntu-root /media/oldroot/
```

```
sudo umount /media/oldroot
sudo vgexport vgubuntu
sudo cryptsetup luksClose oldroot
```

# docker-compose cant pull images even thought logged in.

`ln -s ${XDG_RUNTIME_DIR}/containers/auth.json ~/.docker/config.json`