{ ... }:
{
  services.k3s.manifests = {
    adguard-namespace = {
      enable = true;
      target = "adguard-namespace.yaml";
      content = {
        apiVersion = "v1";
        kind = "Namespace";
        metadata = {
          name = "adguard";
        };
      };
    };

    adguard-service = {
      enable = true;
      target = "adguard-service.yaml";
      content = {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "adguard-home";
          namespace = "adguard";
        };
        spec = {
          type = "ExternalName";
          externalName = "ocean.mercury"; # ocean host IP
          ports = [
            {
              port = 3030;
              targetPort = 3030;
              protocol = "TCP";
            }
          ];
        };
      };
    };

    adguard-ingress = {
      enable = true;
      target = "adguard-ingress.yaml";
      content = {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "adguard-home";
          namespace = "adguard";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
          };
        };
        spec = {
          tls = [
            {
              hosts = [ "adguard.home.ncrmro.com" ];
            }
          ];
          rules = [
            {
              host = "adguard.home.ncrmro.com";
              http = {
                paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend = {
                      service = {
                        name = "adguard-home";
                        port = {
                          number = 3030;
                        };
                      };
                    };
                  }
                ];
              };
            }
          ];
        };
      };
    };
  };
}
