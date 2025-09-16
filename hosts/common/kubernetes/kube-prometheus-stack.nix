{...}: {
  services.k3s.autoDeployCharts = {
    # Kube Prometheus Stack Helm Chart: https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack
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
            additionalScrapeConfigs = [
              {
                job_name = "node-exporter";
                static_configs = [
                  {
                    targets = ["100.64.0.3:9100"];
                    labels = {
                      instance = "ncrmro-workstation";
                      environment = "home";
                    };
                  }
                  {
                    targets = ["100.64.0.1:9100"];
                    labels = {
                      instance = "ncrmro-laptop";
                      environment = "home";
                    };
                  }
                ];
                scrape_interval = "15s";
                metrics_path = "/metrics";
              }
            ];
          };
          ingress = {
            enabled = true;
            ingressClassName = "nginx";
            hosts = ["prometheus.ncrmro.com"];
            tls = [
              {
                # Using default ingress-nginx wildcard cert (*.ncrmro.com)
                hosts = ["prometheus.ncrmro.com"];
              }
            ];
          };
        };
        grafana = {
          persistence = {
            enabled = true;
            storageClassName = "ocean-nvme";
            size = "10Gi";
          };
          ingress = {
            enabled = true;
            ingressClassName = "nginx";
            hosts = ["grafana.ncrmro.com"];
            tls = [
              {
                # Using default ingress-nginx wildcard cert (*.ncrmro.com)
                hosts = ["grafana.ncrmro.com"];
              }
            ];
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
