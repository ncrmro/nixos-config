# qcow2 disk image settings for agent-luce
# This module configures the NixOS image builder for qcow2 output.
{
  config,
  lib,
  pkgs,
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
  system.build.qcow2 = import "${pkgs.path}/nixos/lib/make-disk-image.nix" {
    inherit config lib pkgs;
    name = "agent-luce";
    format = "qcow2";
    diskSize = "65536"; # 64GB
    partitionTableType = "efi";
    # Include the full closure
    copyChannel = false;
  };
}
