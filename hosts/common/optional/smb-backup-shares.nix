{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.services.smb-backup-shares;
in {
  options.services.smb-backup-shares = {
    enable = lib.mkEnableOption "SMB backup shares";

    backupsRoot = lib.mkOption {
      type = lib.types.str;
      description = ''
        ZFS dataset root for backup shares. This should be the dataset path
        (e.g., "ocean/backups") which will be converted to the filesystem
        mount point by prepending "/" (e.g., "/ocean/backups").
      '';
    };

    timeMachineQuota = lib.mkOption {
      type = lib.types.str;
      default = "500G";
      description = "ZFS quota for Time Machine backup dataset";
    };

    windowsBackupQuota = lib.mkOption {
      type = lib.types.str;
      default = "1T";
      description = "ZFS quota for Windows backup dataset";
    };

    allowedNetworks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["100.64.0.0/10" "192.168.1.0/24" "127.0.0.1"];
      description = "List of networks allowed to access SMB shares";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable Samba with full feature set for backup shares
    services.samba = {
      enable = true;
      package = pkgs.samba4Full; # Includes Avahi support
      openFirewall = true;

      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "NixOS NAS";
          "netbios name" = "nixos-nas";
          "security" = "user";
          "hosts allow" = lib.concatStringsSep " " cfg.allowedNetworks;
          "hosts deny" = "0.0.0.0/0";
          "guest account" = "nobody";
          "map to guest" = "bad user";

          # Security settings
          "server smb encrypt" = "required";
          "server min protocol" = "SMB3_00";

          # macOS compatibility
          "fruit:aapl" = "yes";
          "fruit:nfs_aces" = "no";
          "fruit:copyfile" = "no";
          "fruit:model" = "MacSamba";
        };

        # Time Machine backup share
        "timemachine" = {
          # Convert ZFS dataset path to filesystem mount point by prepending "/"
          "path" = "/${cfg.backupsRoot}/timemachine";
          "valid users" = "backup";
          "force user" = "backup";
          "force group" = "backup";
          "read only" = "no";
          "browseable" = "yes";
          "create mask" = "0600";
          "directory mask" = "0700";

          # Time Machine specific settings
          "fruit:time machine" = "yes";
          "fruit:time machine max size" = cfg.timeMachineQuota;
          "vfs objects" = "catia fruit streams_xattr";
        };

        # Windows backup share
        "windows-backup" = {
          # Convert ZFS dataset path to filesystem mount point by prepending "/"
          "path" = "/${cfg.backupsRoot}/windows";
          "valid users" = "backup";
          "force user" = "backup";
          "force group" = "backup";
          "read only" = "no";
          "browseable" = "yes";
          "create mask" = "0644";
          "directory mask" = "0755";
          "vfs objects" = "catia streams_xattr";
        };
      };
    };

    # Enable Samba Web Service Discovery for Windows
    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    # Enable Avahi for service discovery
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      publish.enable = true;
      publish.userServices = true;
      extraServiceFiles = {
        smb = ''
          <?xml version="1.0" standalone='no'?>
          <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
          <service-group>
            <name replace-wildcards="yes">%h SMB</name>
            <service>
              <type>_smb._tcp</type>
              <port>445</port>
            </service>
          </service-group>
        '';
        timemachine = ''
          <?xml version="1.0" standalone='no'?>
          <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
          <service-group>
            <name replace-wildcards="yes">%h Time Machine</name>
            <service>
              <type>_adisk._tcp</type>
              <txt-record>sys=waMa=0,adVF=0x100</txt-record>
              <txt-record>dk0=adVN=timemachine,adVF=0x82</txt-record>
            </service>
          </service-group>
        '';
      };
    };

    # Ensure ZFS datasets exist before creating directories
    systemd.services.create-backup-datasets = {
      description = "Create ZFS datasets for backup shares";
      wantedBy = ["multi-user.target"];
      before = ["samba-smbd.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = let
        poolName = builtins.head (lib.splitString "/" cfg.backupsRoot);
      in ''
        # Check if ZFS pool exists
        if ! ${pkgs.zfs}/bin/zfs list ${poolName} > /dev/null 2>&1; then
          echo "Error: ZFS pool '${poolName}' not found"
          exit 1
        fi

        # Create backup datasets if they don't exist
        for dataset in ${cfg.backupsRoot} ${cfg.backupsRoot}/timemachine ${cfg.backupsRoot}/windows; do
          if ! ${pkgs.zfs}/bin/zfs list "$dataset" > /dev/null 2>&1; then
            echo "Creating ZFS dataset: $dataset"
            ${pkgs.zfs}/bin/zfs create -p "$dataset"
          fi
        done

        # Set dataset properties
        ${pkgs.zfs}/bin/zfs set compression=lz4 ${cfg.backupsRoot}/timemachine
        ${pkgs.zfs}/bin/zfs set compression=lz4 ${cfg.backupsRoot}/windows
        ${pkgs.zfs}/bin/zfs set quota=${cfg.timeMachineQuota} ${cfg.backupsRoot}/timemachine
        ${pkgs.zfs}/bin/zfs set quota=${cfg.windowsBackupQuota} ${cfg.backupsRoot}/windows
      '';
    };

    # Create backup user and group
    users.groups.backup = {};
    users.users.backup = {
      isSystemUser = true;
      group = "backup";
      home = "/${cfg.backupsRoot}";
      createHome = false;
    };

    # Ensure backup directories exist with correct permissions
    systemd.tmpfiles.rules = [
      "d /${cfg.backupsRoot} 0755 backup backup -"
      "d /${cfg.backupsRoot}/timemachine 0700 backup backup -"
      "d /${cfg.backupsRoot}/windows 0755 backup backup -"
    ];

    # Set up Samba user with generated password for headless operation
    system.activationScripts.samba_user_setup = ''
      if [ ! -f /var/lib/samba/private/smbpasswd ]; then
        echo "=== Setting up Samba backup user for headless operation ==="

        # Generate a random password
        SAMBA_PASSWORD=$(${pkgs.openssl}/bin/openssl rand -base64 32)

        # Create the backup user in Samba with the generated password
        echo -e "$SAMBA_PASSWORD\n$SAMBA_PASSWORD" | ${pkgs.samba}/bin/smbpasswd -a -s backup

        # Save the password to a secure location
        echo "backup:$SAMBA_PASSWORD" > /etc/samba/backup-credentials
        chmod 600 /etc/samba/backup-credentials
        chown root:root /etc/samba/backup-credentials

        echo "=== Samba Backup User Setup Complete ==="
        echo "Username: backup"
        echo "Password saved to: /etc/samba/backup-credentials"
        echo ""
        echo "To view the password later, run:"
        echo "  sudo cat /etc/samba/backup-credentials"
        echo ""
        echo "SMB shares are now accessible at:"
        echo "  Time Machine: smb://$(hostname)/timemachine"
        echo "  Windows Backup: smb://$(hostname)/windows-backup"
        echo "======================================"
      fi
    '';
  };
}
