{config, ...}: let
  k8sIngressHttps = "127.0.0.1:8443";
  # Allow/deny config for Tailscale-only services
  tailscaleOnly = ''
    allow 100.64.0.0/10;
    deny all;
  '';
in {
  age.secrets.cloudflare-api-token = {
    file = ../../secrets/cloudflare-api-token.age;
    owner = "acme";
    group = "acme";
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "admin@ncrmro.com";
  };

  security.acme.certs."wildcard-ncrmro-com" = {
    domain = "*.ncrmro.com";
    extraDomainNames = ["*.home.ncrmro.com" "ncrmro.com"];
    dnsProvider = "cloudflare";
    environmentFile = config.age.secrets.cloudflare-api-token.path;
    group = "nginx";
    extraLegoFlags = ["--dns.resolvers=1.1.1.1:53"];
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
  };

  networking.firewall.allowedTCPPorts = [80 443];

  # Jellyfin - PUBLIC (no access restriction)
  services.nginx.virtualHosts."jellyfin.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    locations."/" = {
      proxyPass = "http://127.0.0.1:8096";
      proxyWebsockets = true;
    };
  };

  # Radarr - Tailscale only
  services.nginx.virtualHosts."radarr.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "http://127.0.0.1:7878";
      proxyWebsockets = true;
    };
  };

  # Sonarr - Tailscale only
  services.nginx.virtualHosts."sonarr.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8989";
      proxyWebsockets = true;
    };
  };

  # Prowlarr - Tailscale only
  services.nginx.virtualHosts."prowlarr.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "http://127.0.0.1:9696";
      proxyWebsockets = true;
    };
  };

  # Bazarr - Tailscale only
  services.nginx.virtualHosts."bazarr.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "http://127.0.0.1:6767";
      proxyWebsockets = true;
    };
  };

  # Lidarr - Tailscale only
  services.nginx.virtualHosts."lidarr.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8686";
      proxyWebsockets = true;
    };
  };

  # Readarr - Tailscale only
  services.nginx.virtualHosts."readarr.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8787";
      proxyWebsockets = true;
    };
  };

  # Jellyseerr - Tailscale only
  services.nginx.virtualHosts."jellyseerr.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "http://127.0.0.1:5055";
      proxyWebsockets = true;
    };
  };

  # Transmission - Tailscale only
  services.nginx.virtualHosts."transmission.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "http://127.0.0.1:9091";
      proxyWebsockets = true;
    };
  };

  # SABnzbd - Tailscale only
  services.nginx.virtualHosts."sabnzbd.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
      proxyWebsockets = true;
    };
  };

  # Home Assistant - Tailscale only
  services.nginx.virtualHosts."home.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8123";
      proxyWebsockets = true;
    };
  };

  # AdGuard Home - Tailscale only
  services.nginx.virtualHosts."adguard.home.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "http://127.0.0.1:3030";
      proxyWebsockets = true;
    };
  };

  # K8s services - forward to ingress-nginx (Tailscale only)
  services.nginx.virtualHosts."vaultwarden.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "https://${k8sIngressHttps}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_ssl_server_name on;
        proxy_set_header Host $host;
      '';
    };
  };

  services.nginx.virtualHosts."git.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "https://${k8sIngressHttps}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_ssl_server_name on;
        proxy_set_header Host $host;
      '';
    };
  };

  services.nginx.virtualHosts."grafana.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "https://${k8sIngressHttps}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_ssl_server_name on;
        proxy_set_header Host $host;
      '';
    };
  };

  services.nginx.virtualHosts."prometheus.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "https://${k8sIngressHttps}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_ssl_server_name on;
        proxy_set_header Host $host;
      '';
    };
  };

  services.nginx.virtualHosts."loki.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "https://${k8sIngressHttps}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_ssl_server_name on;
        proxy_set_header Host $host;
      '';
    };
  };

  services.nginx.virtualHosts."longhorn.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "https://${k8sIngressHttps}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_ssl_server_name on;
        proxy_set_header Host $host;
      '';
    };
  };
}
