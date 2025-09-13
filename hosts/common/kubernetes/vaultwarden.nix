{...}: {
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
    vaultwarden = {
      name = "vaultwarden";
      repo = "https://gabe565.github.io/charts";
      version = "0.16.1";
      hash = "sha256-Tn3CpyiXStLUcgDqc1hz6okt9M2vNT2NKQkkLIEJxj8="; # TODO: Add hash after first deployment
      targetNamespace = "vaultwarden";
      createNamespace = false;
      values = {
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
        ];
        persistence.data = {
          enabled = true;
          storageClass = "ocean-nvme";
          accessMode = "ReadWriteOnce";
          size = "1Gi";
        };
      };
    };
  };
}
