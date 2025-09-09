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
      };
    };
  };
}
