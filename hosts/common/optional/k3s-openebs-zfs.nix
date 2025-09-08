{
  config,
  lib,
  ...
}: {
  config = {
    services.k3s.manifests = {
      "openebs-zfs-localpv".content = {
        apiVersion = "helm.cattle.io/v1";
        kind = "HelmChart";
        metadata = {
          name = "zfs-localpv";
          namespace = "kube-system";
        };
        spec = {
          repo = "https://openebs.github.io/zfs-localpv";
          chart = "zfs-localpv";
          targetNamespace = "kube-system";
          valuesContent = ''
            analytics:
              enabled: false
            tolerateAllTaints: true
          '';
        };
      };
    };
  };
}