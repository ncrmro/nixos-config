{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.keystone.os.physicalMigration;
  admin = config.keystone.os.adminUsername;
in
{
  # TODO(upstream-keystone): Graduate the script package and the receiver
  # bootstrap into keystone/modules/os/physical-migration.nix.
  options.keystone.os.physicalMigration.receiver = {
    enable = lib.mkEnableOption "physical-machine migration staging receiver";
    dataset = lib.mkOption {
      type = lib.types.str;
      default = "ocean/physical-migrations";
      description = "ZFS dataset used for resumable physical disk staging.";
    };
    mountpoint = lib.mkOption {
      type = lib.types.str;
      default = "/ocean/physical-migrations";
      description = "Mounted staging path writable by the Keystone admin.";
    };
    quota = lib.mkOption {
      type = lib.types.str;
      default = "4T";
      description = "Safety quota for all staged physical disks.";
    };
  };

  config = lib.mkIf cfg.receiver.enable {
    environment.systemPackages = [ pkgs.keystone-physical-migration ];

    systemd.services.keystone-physical-migration-receiver = {
      description = "Prepare the Keystone physical migration staging dataset";
      wantedBy = [ "multi-user.target" ];
      after = [
        "zfs.target"
        "import-ocean.service"
      ];
      wants = [ "import-ocean.service" ];
      path = [
        pkgs.coreutils
        pkgs.zfs
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -euo pipefail
        if ! zfs list -H ${lib.escapeShellArg cfg.receiver.dataset} >/dev/null 2>&1; then
          zfs create \
            -o mountpoint=${lib.escapeShellArg cfg.receiver.mountpoint} \
            -o compression=lz4 \
            -o recordsize=1M \
            -o atime=off \
            -o quota=${lib.escapeShellArg cfg.receiver.quota} \
            ${lib.escapeShellArg cfg.receiver.dataset}
        fi
        zfs set mountpoint=${lib.escapeShellArg cfg.receiver.mountpoint} ${lib.escapeShellArg cfg.receiver.dataset}
        zfs set compression=lz4 recordsize=1M atime=off quota=${lib.escapeShellArg cfg.receiver.quota} ${lib.escapeShellArg cfg.receiver.dataset}
        install -d -o ${lib.escapeShellArg admin} -g users -m 0770 ${lib.escapeShellArg cfg.receiver.mountpoint}
      '';
    };
  };
}
