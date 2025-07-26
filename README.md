

nix profile add nixpkgs#nixos-install-tools 

nixos-generate-config --root /tmp/config --no-filesystems

nix run github:nix-community/nixos-anywhere -- --flake .#mox --vm-test

```shell
nix run github:nix-community/nixos-anywhere -- \
--flake .#test-vm \
--generate-hardware-config nixos-generate-config ./hosts/test-vm/hardware-configuration.nix \
root@192.168.122.62
```