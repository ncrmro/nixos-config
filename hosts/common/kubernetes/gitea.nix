{ ... }:
{
  services.k3s.autoDeployCharts = {
    # Gitea Helm Chart: https://gitea.com/gitea/helm-chart
    gitea = {
      name = "gitea";
      repo = "https://dl.gitea.com/charts/";
      version = "12.3.0";
      hash = "sha256-2vVuqlW+BJA5Tgyu9VipbAnij2zzNflDeVHJqZug/W8=";
      targetNamespace = "gitea";
      createNamespace = true;
      values = {
        # Gitea configuration
        gitea = {
          admin = {
            username = "ncrmro";
            password = "changeme"; # TODO: Use proper secret management
            email = "ncrmro@gmail.com";
          };
          config = {
            database = {
              DB_TYPE = "sqlite3";
            };
            session = {
              PROVIDER = "file";
            };
            cache = {
              ADAPTER = "valkey";
            };
            queue = {
              TYPE = "level";
            };
            server = {
              DOMAIN = "git.ncrmro.com";
              ROOT_URL = "https://git.ncrmro.com";
              SSH_PORT = "2222";
            };
          };
        };

        # Persistent storage configuration - Main data volume
        persistence = {
          enabled = true;
          storageClass = "ceph-filesystem";
          size = "10Gi";
          accessModes = [ "ReadWriteMany" ];
        };

        # Database configuration - using external PostgreSQL
        postgresql = {
          enabled = false; # Use external PostgreSQL or SQLite for simplicity
        };

        postgresql-ha = {
          enabled = false; # Use external PostgreSQL or SQLite for simplicity
        };

        # Valkey cluster configuration (enabled by default in v12+)
        valkey-cluster = {
          enabled = true;
          persistence = {
            enabled = true;
            storageClass = "zfs-nvme";
            size = "2Gi";
            accessModes = [ "ReadWriteOnce" ];
          };
          resources = {
            limits = {
              cpu = "200m";
              memory = "256Mi";
            };
            requests = {
              cpu = "100m";
              memory = "128Mi";
            };
          };
        };

        # Ingress configuration
        ingress = {
          enabled = true;
          className = "nginx";
          hosts = [
            {
              host = "git.ncrmro.com";
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
              hosts = [ "git.ncrmro.com" ];
            }
          ];
        };

        # Service configuration
        service = {
          http = {
            type = "ClusterIP";
            port = 3000;
          };
          ssh = {
            type = "LoadBalancer"; # For Git SSH access
            port = 2222;
            externalPort = 2222;
          };
        };

        # Resources configuration (example placeholder values)
        resources = {
          limits = {
            cpu = "1000m";
            memory = "1Gi";
          };
          requests = {
            cpu = "100m";
            memory = "256Mi";
          };
        };

        # Security context
        securityContext = {
          fsGroup = 1000;
        };

        # Deployment configuration
        replicaCount = 2;

        # Anti-affinity to spread pods across different nodes
        affinity = {
          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [
              {
                weight = 100;
                podAffinityTerm = {
                  labelSelector = {
                    matchLabels = {
                      "app.kubernetes.io/name" = "gitea";
                    };
                  };
                  topologyKey = "kubernetes.io/hostname";
                };
              }
            ];
          };
        };

        # Node selector removed to allow scheduling on any node
        # nodeSelector = {};
      };
    };
  };
}
