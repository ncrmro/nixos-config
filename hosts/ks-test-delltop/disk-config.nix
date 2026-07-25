{
  lib,
  ...
}:
{
  # Lanzaboote replaces systemd-boot, so Disko cannot auto-detect EFI tests.
  disko.tests = {
    efi = true;
    # VM tests have no enrolled TPM, so exercise the password fallback used
    # when TPM unlocking is unavailable.
    bootCommands = ''
      machine.wait_for_console_text("Please enter passphrase for")
      machine.send_chars("secretsecret\n")
    '';
  };

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
              mountOptions = [ "umask=0077" ];
            };
          };
          crypted = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              passwordFile = "/tmp/secret.key";
              settings = {
                allowDiscards = true;
                crypttabExtraOpts = [ "tpm2-device=auto" ];
              };
              content = {
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
      };
    };

    lvm_vg.pool = {
      type = "lvm_vg";
      lvs = {
        swap = {
          # The laptop has 32 GiB RAM. Keep enough headroom for a full
          # hibernation image while leaving most of the SSD for the root FS.
          size = "64G";
          content = {
            type = "swap";
            resumeDevice = true;
            discardPolicy = "once";
          };
        };
        root = {
          # Percentage-sized LVs are created after fixed-sized LVs, so this
          # receives all space left after the hibernation swap volume.
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = [
              "defaults"
              "noatime"
            ];
          };
        };
      };
    };
  };
}
