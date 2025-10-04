# ZFS LocalPV CSI Driver
# GitHub repo: https://github.com/openebs/zfs-localpv/tree/develop/deploy/helm/charts
# Chart repo: https://openebs.github.io/zfs-localpv
# Raw values: https://raw.githubusercontent.com/openebs/zfs-localpv/refs/heads/develop/deploy/helm/charts/values.yaml
{
  pkgs,
  config,
  lib,
  ...
}: {
  # Install ZFS tools for LocalPV
  environment.systemPackages = [
    pkgs.zfs
  ];

  # ZFS symlinks for CSI driver compatibility
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

  # Only deploy Helm charts on K3s server nodes
  services.k3s.autoDeployCharts = lib.mkIf (config.services.k3s.enable && config.services.k3s.role == "server") {
    zfs-localpv = {
      name = "zfs-localpv";
      repo = "https://openebs.github.io/zfs-localpv";
      version = "2.8.0";
      hash = "sha256-Ktqf0B+320jkiaQEY5hh2ICjBlSe5PXYKkqrGS4ECIE=";
      targetNamespace = "kube-system";
      createNamespace = false;
      values = {
        # Configure tolerations to allow scheduling on maia node with custom taint
        zfsController = {
          tolerations = [
            {
              key = "ncrmro.com/region";
              operator = "Equal";
              value = "us-south-2";
              effect = "NoSchedule";
            }
          ];
        };

        zfsNode = {
          tolerations = [
            {
              key = "ncrmro.com/region";
              operator = "Equal";
              value = "us-south-2";
              effect = "NoSchedule";
            }
          ];
        };
      };
    };
  };
}
