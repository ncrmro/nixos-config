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
      device = lib.mkDefault "/dev/vda";
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
            end = "-64G";
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
          # Adding this after an install causes the system to crash ?
          # "rpool/crypt/system/docker" = {
          #   type = "zfs_fs";
          #   mountpoint = "/var/lib/containers/storage";
          #   options = {
          #     "com.sun:auto-snapshot" = "false";
          #   };
          # };
          # "crypt/system/containers-storage" = {
          #   type = "zfs_fs";
          #   mountpoint = "/var/lib/containers/storage";
          #   options = {
          #     "com.sun:auto-snapshot" = "false";
          #   };
          # };
          # "crypt/system/ncrmro-docker" = {
          #   type = "zfs_fs";
          #   mountpoint = "/home/ncrmro/.local/share/docker";
          #   options = {
          #     "com.sun:auto-snapshot" = "false";
          #   };
          # };
          # "crypt/system/var/lib/libvirt/storage" = {
          #   type = "zfs_fs";
          #   mountpoint = "/var/lib/libvirt/storage";
          #   options = {
          #     "com.sun:auto-snapshot" = "false";
          #   };
          # };
          # "crypt/system/var/lib/libvirt/images" = {
          #   type = "zfs_fs";
          #   mountpoint = "/var/lib/libvirt/images";
          #   options = {
          #     "com.sun:auto-snapshot" = "false";
          #   };
          # };
        };
      };
    };
  };
}
