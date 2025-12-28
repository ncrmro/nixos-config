# disko-config.nix
{ lib, ... }:
{
  disko.devices = {
    disk = {
      # OS Disk - referenced by serial number
      os = {
        type = "disk";
        device = "/dev/disk/by-id/ata-M4-CT128M4SSD2_000000001224090D40C2";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00"; # EFI System Partition
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            rpool = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };
          };
        };
      };
    };

    # ZFS Pool Configurations
    zpool = {
      # OS Pool - Single Disk
      rpool = {
        type = "zpool";
        mode = ""; # Single disk, no RAID
        rootFsOptions = {
          compression = "zstd";
          "com.sun:auto-snapshot" = "true";
          acltype = "posixacl";
          xattr = "sa";
          relatime = "on";
        };
        datasets = {
          "root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy";
          };
          "nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              mountpoint = "legacy";
              compression = "zstd";
              "com.sun:auto-snapshot" = "false";
            };
          };
          "home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options = {
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
          };
          "var" = {
            type = "zfs_fs";
            mountpoint = "/var";
            options = {
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "false";
            };
          };
        };
      };
    };
  };
}
