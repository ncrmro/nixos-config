# qcow2 disk image settings for agent-drago
# This module configures the NixOS image builder for qcow2 output.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  # Virtio block device for qcow2
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "virtio_net"
  ];

  # QCOW2 image configuration
  system.build.qcow2 = import "${toString modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    diskSize = 65536; # 64GB
    format = "qcow2";
    partitionTableType = "hybrid";
  };
}
