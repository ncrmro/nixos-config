# Kubernetes Node Storage Configuration
# Common storage setup for K8s nodes including ZFS and Ceph/RBD support
{pkgs, ...}: {
  # Install ceph-client for Rook Ceph cluster management and RBD kernel module access
  # environment.systemPackages = [
  #   pkgs.ceph-client
  # ];

  # Load RBD kernel module for Rook Ceph
  boot.kernelModules = ["rbd" "nbd"];

  # ZFS and RBD kernel module setup for Kubernetes storage
  environment.etc = {
    "zfs-usr-bin.conf" = {
      text = ''
        [Install]
        WantedBy=multi-user.target
      '';
    };
    "zfs-usr-bin.service" = {
      text = ''
        [Unit]
        Description=ZFS symlinks in /usr/bin

        [Service]
        Type=oneshot
        ExecStart=/run/current-system/sw/bin/mkdir -p /usr/bin
        ExecStart=/run/current-system/sw/bin/ln -sf /run/current-system/sw/bin/zfs /usr/bin/zfs
        ExecStart=/run/current-system/sw/bin/ln -sf /run/current-system/sw/bin/zpool /usr/bin/zpool
        RemainAfterExit=true

        [Install]
        WantedBy=multi-user.target
      '';
    };
  };

  systemd.services.zfs-usr-bin = {
    description = "ZFS symlinks in /usr/bin for local ZFS EBS";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        "${pkgs.coreutils}/bin/mkdir -p /usr/bin"
        "${pkgs.coreutils}/bin/ln -sf ${pkgs.zfs}/bin/zfs /usr/bin/zfs"
        "${pkgs.coreutils}/bin/ln -sf ${pkgs.zfs}/bin/zpool /usr/bin/zpool"
      ];
      RemainAfterExit = true;
    };
  };
}
