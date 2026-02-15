# Minimal qcow2 disk image - 8GB
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "virtio_net"
  ];

  system.build.qcow2 = import "${toString modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    diskSize = 8192; # 8GB - minimal
    format = "qcow2";
    partitionTableType = "hybrid";
  };
}
