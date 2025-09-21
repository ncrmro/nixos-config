{...}: {
  services.k3s.manifests = {
    servarr-namespace = {
      enable = true;
      target = "servarr-namespace.yaml";
      content = {
        apiVersion = "v1";
        kind = "Namespace";
        metadata = {
          name = "servarr";
        };
      };
    };

    # Jellyfin Service and Ingress
    jellyfin-service = {
      enable = true;
      target = "jellyfin-service.yaml";
      content = {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "jellyfin";
          namespace = "servarr";
        };
        spec = {
          type = "ExternalName";
          externalName = "ocean.mercury";
          ports = [
            {
              port = 8096;
              targetPort = 8096;
              protocol = "TCP";
            }
          ];
        };
      };
    };

    jellyfin-ingress = {
      enable = true;
      target = "jellyfin-ingress.yaml";
      content = {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "jellyfin";
          namespace = "servarr";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
          };
        };
        spec = {
          tls = [
            {
              hosts = ["jellyfin.ncrmro.com"];
            }
          ];
          rules = [
            {
              host = "jellyfin.ncrmro.com";
              http = {
                paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend = {
                      service = {
                        name = "jellyfin";
                        port = {
                          number = 8096;
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

    # Radarr Service and Ingress
    radarr-service = {
      enable = true;
      target = "radarr-service.yaml";
      content = {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "radarr";
          namespace = "servarr";
        };
        spec = {
          type = "ExternalName";
          externalName = "ocean.mercury";
          ports = [
            {
              port = 7878;
              targetPort = 7878;
              protocol = "TCP";
            }
          ];
        };
      };
    };

    radarr-ingress = {
      enable = true;
      target = "radarr-ingress.yaml";
      content = {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "radarr";
          namespace = "servarr";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
          };
        };
        spec = {
          tls = [
            {
              hosts = ["radarr.ncrmro.com"];
            }
          ];
          rules = [
            {
              host = "radarr.ncrmro.com";
              http = {
                paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend = {
                      service = {
                        name = "radarr";
                        port = {
                          number = 7878;
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

    # Sonarr Service and Ingress
    sonarr-service = {
      enable = true;
      target = "sonarr-service.yaml";
      content = {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "sonarr";
          namespace = "servarr";
        };
        spec = {
          type = "ExternalName";
          externalName = "ocean.mercury";
          ports = [
            {
              port = 8989;
              targetPort = 8989;
              protocol = "TCP";
            }
          ];
        };
      };
    };

    sonarr-ingress = {
      enable = true;
      target = "sonarr-ingress.yaml";
      content = {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "sonarr";
          namespace = "servarr";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
          };
        };
        spec = {
          tls = [
            {
              hosts = ["sonarr.ncrmro.com"];
            }
          ];
          rules = [
            {
              host = "sonarr.ncrmro.com";
              http = {
                paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend = {
                      service = {
                        name = "sonarr";
                        port = {
                          number = 8989;
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

    # Prowlarr Service and Ingress
    prowlarr-service = {
      enable = true;
      target = "prowlarr-service.yaml";
      content = {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "prowlarr";
          namespace = "servarr";
        };
        spec = {
          type = "ExternalName";
          externalName = "ocean.mercury";
          ports = [
            {
              port = 9696;
              targetPort = 9696;
              protocol = "TCP";
            }
          ];
        };
      };
    };

    prowlarr-ingress = {
      enable = true;
      target = "prowlarr-ingress.yaml";
      content = {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "prowlarr";
          namespace = "servarr";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
          };
        };
        spec = {
          tls = [
            {
              hosts = ["prowlarr.ncrmro.com"];
            }
          ];
          rules = [
            {
              host = "prowlarr.ncrmro.com";
              http = {
                paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend = {
                      service = {
                        name = "prowlarr";
                        port = {
                          number = 9696;
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

    # Bazarr Service and Ingress
    bazarr-service = {
      enable = true;
      target = "bazarr-service.yaml";
      content = {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "bazarr";
          namespace = "servarr";
        };
        spec = {
          type = "ExternalName";
          externalName = "ocean.mercury";
          ports = [
            {
              port = 6767;
              targetPort = 6767;
              protocol = "TCP";
            }
          ];
        };
      };
    };

    bazarr-ingress = {
      enable = true;
      target = "bazarr-ingress.yaml";
      content = {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "bazarr";
          namespace = "servarr";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
          };
        };
        spec = {
          tls = [
            {
              hosts = ["bazarr.ncrmro.com"];
            }
          ];
          rules = [
            {
              host = "bazarr.ncrmro.com";
              http = {
                paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend = {
                      service = {
                        name = "bazarr";
                        port = {
                          number = 6767;
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

    # Lidarr Service and Ingress
    lidarr-service = {
      enable = true;
      target = "lidarr-service.yaml";
      content = {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "lidarr";
          namespace = "servarr";
        };
        spec = {
          type = "ExternalName";
          externalName = "ocean.mercury";
          ports = [
            {
              port = 8686;
              targetPort = 8686;
              protocol = "TCP";
            }
          ];
        };
      };
    };

    lidarr-ingress = {
      enable = true;
      target = "lidarr-ingress.yaml";
      content = {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "lidarr";
          namespace = "servarr";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
          };
        };
        spec = {
          tls = [
            {
              hosts = ["lidarr.ncrmro.com"];
            }
          ];
          rules = [
            {
              host = "lidarr.ncrmro.com";
              http = {
                paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend = {
                      service = {
                        name = "lidarr";
                        port = {
                          number = 8686;
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

    # Readarr Service and Ingress
    readarr-service = {
      enable = true;
      target = "readarr-service.yaml";
      content = {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "readarr";
          namespace = "servarr";
        };
        spec = {
          type = "ExternalName";
          externalName = "ocean.mercury";
          ports = [
            {
              port = 8787;
              targetPort = 8787;
              protocol = "TCP";
            }
          ];
        };
      };
    };

    readarr-ingress = {
      enable = true;
      target = "readarr-ingress.yaml";
      content = {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "readarr";
          namespace = "servarr";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
          };
        };
        spec = {
          tls = [
            {
              hosts = ["readarr.ncrmro.com"];
            }
          ];
          rules = [
            {
              host = "readarr.ncrmro.com";
              http = {
                paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend = {
                      service = {
                        name = "readarr";
                        port = {
                          number = 8787;
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

    # Jellyseerr Service and Ingress
    jellyseerr-service = {
      enable = true;
      target = "jellyseerr-service.yaml";
      content = {
        apiVersion = "v1";
        kind = "Service";
        metadata = {
          name = "jellyseerr";
          namespace = "servarr";
        };
        spec = {
          type = "ExternalName";
          externalName = "ocean.mercury";
          ports = [
            {
              port = 5055;
              targetPort = 5055;
              protocol = "TCP";
            }
          ];
        };
      };
    };

    jellyseerr-ingress = {
      enable = true;
      target = "jellyseerr-ingress.yaml";
      content = {
        apiVersion = "networking.k8s.io/v1";
        kind = "Ingress";
        metadata = {
          name = "jellyseerr";
          namespace = "servarr";
          annotations = {
            "kubernetes.io/ingress.class" = "nginx";
          };
        };
        spec = {
          tls = [
            {
              hosts = ["jellyseerr.ncrmro.com"];
            }
          ];
          rules = [
            {
              host = "jellyseerr.ncrmro.com";
              http = {
                paths = [
                  {
                    path = "/";
                    pathType = "Prefix";
                    backend = {
                      service = {
                        name = "jellyseerr";
                        port = {
                          number = 5055;
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
