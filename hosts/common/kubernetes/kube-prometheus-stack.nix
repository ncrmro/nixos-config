{...}: {
  services.k3s.autoDeployCharts = {
    kube-prometheus-stack = {
      name = "kube-prometheus-stack";
      repo = "https://prometheus-community.github.io/helm-charts";
      version = "77.5.0";
      hash = "sha256-FYeBIPU2EZXeclNatYllbKajZhQHttxoU/zHySkUX6E=";
      targetNamespace = "monitoring";
      createNamespace = true;
      values = {
        # Prometheus Stack configuration
        prometheus = {
          prometheusSpec = {
            retention = "90d";
            storageSpec = {
              volumeClaimTemplate = {
                spec = {
                  storageClassName = "ocean-nvme";
                  accessModes = ["ReadWriteOnce"];
                  resources = {
                    requests = {
                      storage = "50Gi";
                    };
                  };
                };
              };
            };
          };
        };
        grafana = {
          persistence = {
            enabled = true;
            storageClassName = "ocean-nvme";
            size = "10Gi";
          };
        };
        alertmanager = {
          alertmanagerSpec = {
            storage = {
              volumeClaimTemplate = {
                spec = {
                  storageClassName = "ocean-nvme";
                  accessModes = ["ReadWriteOnce"];
                  resources = {
                    requests = {
                      storage = "10Gi";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
