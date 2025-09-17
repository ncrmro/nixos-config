# ZFS LocalPV CSI Driver
# GitHub repo: https://github.com/openebs/zfs-localpv/tree/develop/deploy/helm/charts
# Chart repo: https://openebs.github.io/zfs-localpv
# Raw values: https://raw.githubusercontent.com/openebs/zfs-localpv/refs/heads/develop/deploy/helm/charts/values.yaml
{...}: {
  services.k3s.autoDeployCharts = {
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
