{ ... }:
{
  services.k3s.manifests = {
    vaultwarden-namespace = {
      enable = true;
      target = "vaultwarden-namespace.yaml";
      content = {
        apiVersion = "v1";
        kind = "Namespace";
        metadata = {
          name = "vaultwarden";
        };
      };
    };

    vaultwarden-postgres-cluster = {
      enable = true;
      target = "vaultwarden-postgres-cluster.yaml";
      content = {
        apiVersion = "postgresql.cnpg.io/v1";
        kind = "Cluster";
        metadata = {
          name = "vaultwarden-postgres";
          namespace = "vaultwarden";
        };
        spec = {
          instances = 1;
          storage = {
            size = "1Gi";
            storageClass = "zfs-nvme";
          };
        };
      };
    };
  };

  services.k3s.autoDeployCharts = {
    # Vaultwarden Helm Chart: https://artifacthub.io/packages/helm/gabe565/vaultwarden
    vaultwarden = {
      name = "vaultwarden";
      repo = "https://gabe565.github.io/charts";
      version = "0.16.1";
      hash = "sha256-Tn3CpyiXStLUcgDqc1hz6okt9M2vNT2NKQkkLIEJxj8="; # TODO: Add hash after first deployment
      targetNamespace = "vaultwarden";
      createNamespace = false;
      values = {
        # Note: Setting .Values.env overrides the normal Helm templated env values,
        # so we need to explicitly set DOMAIN and ROCKET_PORT which are normally set by the chart
        env = [
          {
            name = "DATABASE_URL";
            valueFrom = {
              secretKeyRef = {
                name = "vaultwarden-postgres-app";
                key = "uri";
              };
            };
          }
          {
            name = "DOMAIN";
            value = "https://vaultwarden.ncrmro.com";
          }
          {
            name = "ROCKET_PORT";
            value = "8080";
          }
        ];
        persistence.data = {
          enabled = true;
          storageClass = "ocean-nvme";
          accessMode = "ReadWriteOnce";
          size = "1Gi";
        };
        ingress.main = {
          enabled = true;
          className = "nginx";
          hosts = [
            {
              host = "vaultwarden.ncrmro.com";
              paths = [
                {
                  path = "/";
                  pathType = "Prefix";
                }
              ];
            }
          ];
          tls = [
            {
              # Using default ingress-nginx wildcard cert (*.ncrmro.com)
              hosts = [ "vaultwarden.ncrmro.com" ];
            }
          ];
        };
      };
    };
  };
}
