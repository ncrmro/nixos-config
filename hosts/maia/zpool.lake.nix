# initrd service order for ZFS "lake" and its credstore
# 1) modprobe@zfs.service: load ZFS kernel module
# 2) import-lake-bare.service: wait for USB devices, then `zpool import -N` for pool "lake"
#    - Ordered after the USB disk .device units; before/wants cryptsetup-pre.target
# 3) systemd-cryptsetup@lake-credstore.service: open LUKS on /dev/zvol/lake/credstore
# 4) etc-lake-credstore.mount: mount /etc/lake-credstore (from fstab)
# 5) lake-load-key.service: RequiresMountsFor=/etc/credstore; ImportCredential=zfs-lake.mount;
#    runs `zfs load-key` for dataset lake/crypt
# 6) sysroot.mount and initrd.target continue; switch-root is ordered to wait until credstore
#    units can stop cleanly via conflicts/after
{
  lib,
  config,
  utils,
  ...
}:
{
  boot.initrd.systemd.emergencyAccess = lib.mkDefault false;
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd = {
    # This would be a nightmare without systemd initrd
    systemd.enable = true;

    # TODO remove this eventually
    # Bound device and start timeouts during initrd to avoid indefinite waits
    systemd.extraConfig = ''
      DefaultDeviceTimeoutSec=120s
      DefaultTimeoutStartSec=120s
    '';

    # Disable NixOS's systemd service that imports the pool
    # systemd.services.zfs-import-rpool.enable = false;

    systemd.services.import-lake-bare =
      let
        # Compute the systemd units for the devices in the pool
        devices = map (p: utils.escapeSystemdPath p + ".device") [
          config.disko.devices.disk.disk2.device
          config.disko.devices.disk.disk3.device
        ];
      in
      {
        after = [ "modprobe@zfs.service" ] ++ devices;
        requires = [ "modprobe@zfs.service" ];

        # Devices are added to 'wants' instead of 'requires' so that a
        # degraded import may be attempted if one of them times out.
        # 'cryptsetup-pre.target' is wanted because it isn't pulled in
        # normally and we want this service to finish before
        # 'systemd-cryptsetup@.service' instances begin running.
        wants = [ "cryptsetup-pre.target" ] ++ devices;
        before = [ "cryptsetup-pre.target" ];

        unitConfig.DefaultDependencies = false;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          # TimeoutStartSec = "120s";
        };
        path = [ config.boot.zfs.package ];
        enableStrictShellChecks = true;
        script =
          let
            # Check that the FSes we're about to mount actually come from
            # our encryptionroot. If not, they may be fraudulent.
            shouldCheckFS = fs: fs.fsType == "zfs" && utils.fsNeededForBoot fs;
            checkFS = fs: ''
              encroot="$(zfs get -H -o value encryptionroot ${fs.device})"
              if [ "$encroot" != lake/crypt ]; then
                echo ${fs.device} has invalid encryptionroot "$encroot" >&2
                exit 1
              else
                echo ${fs.device} has valid encryptionroot "$encroot" >&2
              fi
            '';
          in
          ''
            function cleanup() {
              exit_code=$?
              if [ "$exit_code" != 0 ]; then
                zpool export lake
              fi
            }
            trap cleanup EXIT
            zpool import -N -d /dev/disk/by-id lake

            # Check that the file systems we will mount have the right encryptionroot.
            ${lib.concatStringsSep "\n" (
              lib.map checkFS (lib.filter shouldCheckFS config.system.build.fileSystems)
            )}
          '';
      };

    luks.devices.lake-credstore = {
      device = "/dev/zvol/lake/credstore";
      # 'tpm2-device=auto' usually isn't necessary, but for reasons
      # that bewilder me, adding 'tpm2-measure-pcr=yes' makes it
      # required. And 'tpm2-measure-pcr=yes' is necessary to make sure
      # the TPM2 enters a state where the LUKS volume can no longer be
      # decrypted. That way if we accidentally boot an untrustworthy
      # OS somehow, they can't decrypt the LUKS volume.
      crypttabExtraOpts = [
        "tpm2-measure-pcr=yes"
        "tpm2-device=auto"
        "x-systemd.device-timeout=120s"
      ];
    };
    # Adding an fstab is the easiest way to add file systems whose
    # purpose is solely in the initrd and aren't a part of '/sysroot'.
    # The 'x-systemd.after=' might seem unnecessary, since the mount
    # unit will already be ordered after the mapped device, but it
    # helps when stopping the mount unit and cryptsetup service to
    # make sure the LUKS device can close, thanks to how systemd
    # orders the way units are stopped.
    supportedFilesystems.ext4 = true;
    systemd.contents."/etc/fstab".text = ''
      /dev/mapper/lake-credstore /etc/lake-credstore ext4 defaults,x-systemd.after=systemd-cryptsetup@lake-credstore.service 0 2
    '';
    # Add some conflicts to ensure the credstore closes before leaving initrd.
    systemd.targets.initrd-switch-root = {
      conflicts = [
        "etc-credstore.mount"
        "systemd-cryptsetup@credstore.service"
      ];
      after = [
        "etc-credstore.mount"
        "systemd-cryptsetup@credstore.service"
      ];
    };

    # After the pool is imported and the credstore is mounted, finally
    # load the key. This uses systemd credentials, which is why the
    # credstore is mounted at '/etc/credstore'. systemd will look
    # there for a credential file called 'zfs-sysroot.mount' and
    # provide it in the 'CREDENTIALS_DIRECTORY' that is private to
    # this service. If we really wanted, we could make the credstore a
    # 'WantsMountsFor' instead and allow providing the key through any
    # of the numerous other systemd credential provision mechanisms.
    systemd.services.lake-load-key = {
      requiredBy = [ "initrd.target" ];
      before = [
        "sysroot.mount"
        "initrd.target"
      ];
      requires = [ "import-lake-bare.service" ];
      after = [ "import-lake-bare.service" ];
      unitConfig.RequiresMountsFor = "/etc/credstore";
      unitConfig.DefaultDependencies = false;
      serviceConfig = {
        Type = "oneshot";
        ImportCredential = "zfs-lake.mount";
        RemainAfterExit = true;
        ExecStart = "${config.boot.zfs.package}/bin/zfs load-key -L file://\"\${CREDENTIALS_DIRECTORY}\"/zfs-lake.mount lake/crypt";
      };
    };
  };
}
