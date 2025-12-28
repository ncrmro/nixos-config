{ ... }:
{
  services.k3s.manifests = {
    home-assistant-namespace = {
      enable = true;
      target = "home-assistant-namespace.yaml";
      content = {
        apiVersion = "v1";
        kind = "Namespace";
        metadata = {
          name = "home-assistant";
        };
      };
    };

    # Home Assistant Service and Ingress
    # NOTE: When changing the domain, also update the DNS record in:
    # - /modules/nixos/headscale/default.nix (extra_records section)
    home-assistant-service = {
      enable = true;
      target = "home-assistant-service.yaml";
      content = {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "home-assistant";
          namespace = "home-assistant";
        };
        spec = {
          type = "ExternalName";
          externalName = "ocean.mercury";
          ports = [
            {
              port = 8123;
              targetPort = 8123;
              protocol = "TCP";
            }
          ];
        };
      };
    };

    home-assistant-ingress = {
      enable = true;
      target = "home-assistant-ingress.yaml";
      content = {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "home-assistant";
          namespace = "home-assistant";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
          };
        };
        spec = {
          tls = [
            {
              hosts = [ "home.ncrmro.com" ];
            }
          ];
          rules = [
            {
              host = "home.ncrmro.com";
              http = {
                paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend = {
                      service = {
                        name = "home-assistant";
                        port = {
                          number = 8123;
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
