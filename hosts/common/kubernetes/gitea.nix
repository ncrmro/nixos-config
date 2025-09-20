{...}: {
  services.k3s.manifests = {
    gitea-namespace = {
      enable = true;
      target = "gitea-namespace.yaml";
      content = {
        apiVersion = "v1";
        kind = "Namespace";
        metadata = {
          name = "gitea";
        };
      };
    };
  };

  services.k3s.autoDeployCharts = {
    # Gitea Helm Chart: https://gitea.com/gitea/helm-chart
    gitea = {
      name = "gitea";
      repo = "https://dl.gitea.com/charts/";
      version = "10.6.0";
      hash = "sha256-PLACEHOLDER"; # TODO: Add hash after first deployment
      targetNamespace = "gitea";
      createNamespace = false;
      values = {
        # Gitea configuration
        gitea = {
          admin = {
            username = "admin";
            password = "changeme"; # TODO: Use proper secret management
            email = "admin@example.com";
          };
          config = {
            database = {
              DB_TYPE = "sqlite3";
            };
            session = {
              PROVIDER = "file";
            };
            cache = {
              ADAPTER = "memory";
            };
            queue = {
              TYPE = "level";
            };
            server = {
              DOMAIN = "git.example.com"; # TODO: Update with actual domain
              ROOT_URL = "https://git.example.com"; # TODO: Update with actual domain
            };
          };
        };

        # Persistent storage configuration - Main data volume
        persistence = {
          enabled = true;
          storageClass = "ceph-filesystem";
          size = "10Gi";
          accessModes = ["ReadWriteOnce"];
        };

        # Database configuration - using external PostgreSQL
        postgresql = {
          enabled = false; # Use external PostgreSQL or SQLite for simplicity
        };

        postgresql-ha = {
          enabled = false; # Use external PostgreSQL or SQLite for simplicity
        };

        # Ingress configuration
        ingress = {
          enabled = true;
          className = "nginx";
          hosts = [
            {
              host = "git.example.com"; # TODO: Update with actual domain
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
              hosts = ["git.example.com"]; # TODO: Update with actual domain
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
            port = 22;
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

        # Node selector (example placeholder)
        nodeSelector = {
          "kubernetes.io/hostname" = "ocean"; # Example placeholder node selector
        };
      };
    };
  };
}