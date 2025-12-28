{
  lib,
  config,
  utils,
  ...
}:
{
  disko.devices = {
    disk.disk1 = {
      type = "disk";
      device = "/dev/disk/by-id/ata-512GB_SSD_MQ08B81904931";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            name = "ESP";
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          zfs = {
            end = "-8G";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
          encryptedSwap = {
            size = "100%";
            content = {
              type = "swap";
              randomEncryption = true;
            };
          };
        };
      };
    };
    disk.disk2 = {
      type = "disk";
      device = "/dev/disk/by-id/ata-WDC_WD102KFBX-68M95N0_VH12TB1M";
      content = {
        type = "zfs";
        pool = "lake";
      };
    };
    disk.disk3 = {
      type = "disk";
      device = "/dev/disk/by-id/ata-WDC_WD102KFBX-68M95N0_VH12TBYM";
      content = {
        type = "zfs";
        pool = "lake";
      };
    };
    zpool = {
      rpool = {
        type = "zpool";
        rootFsOptions = {
          mountpoint = "none";
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
          "com.sun:auto-snapshot" = "true";
        };
        options.ashift = "12";
        datasets = {
          credstore = {
            type = "zfs_volume";
            size = "100M";
            content = {
              type = "luks";
              name = "credstore";
              content = {
                type = "filesystem";
                format = "ext4";
              };
            };
          };
          crypt = {
            type = "zfs_fs";
            options.mountpoint = "none";
            options.encryption = "aes-256-gcm";
            options.keyformat = "raw";
            options.keylocation = "file:///etc/credstore/zfs-sysroot.mount";
            preCreateHook = "mount -o X-mount.mkdir /dev/mapper/credstore /etc/credstore && head -c 32 /dev/urandom > /etc/credstore/zfs-sysroot.mount";
            postCreateHook = "umount /etc/credstore && cryptsetup luksClose /dev/mapper/credstore";
          };
          "crypt/system" = {
            type = "zfs_fs";
            mountpoint = "/";
          };
          "crypt/system/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              "com.sun:auto-snapshot" = "false";
            };
          };
          "crypt/system/var" = {
            type = "zfs_fs";
            mountpoint = "/var";
          };
        };
      };
      lake = {
        type = "zpool";
        mode = "mirror";
        rootFsOptions = {
          mountpoint = "none";
        };
        options.ashift = "12";
        datasets = {
          credstore = {
            type = "zfs_volume";
            size = "100M";
            content = {
              type = "luks";
              name = "lake-credstore";
              content = {
                type = "filesystem";
                format = "ext4";
              };
            };
          };
          crypt = {
            type = "zfs_fs";
            options.mountpoint = "none";
            options.encryption = "aes-256-gcm";
            options.keyformat = "raw";
            options.keylocation = "file:///etc/lake-credstore/zfs-lake.mount";
            preCreateHook = "mount -o X-mount.mkdir /dev/mapper/lake-credstore /etc/lake-credstore && head -c 32 /dev/urandom > /etc/lake-credstore/zfs-lake.mount";
            postCreateHook = "umount /etc/lake-credstore && cryptsetup luksClose /dev/mapper/lake-credstore";
          };
        };
      };
    };
  };
}
