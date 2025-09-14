{config, ...}: let
  domain = "mercury.ncrmro.com";
in {
  # Configure ACME for SSL certificates
  security.acme = {
    acceptTerms = true;
    defaults.email = "ncrmro@gmail.com"; # Replace with your email
  };

  # Enable nginx for reverse proxy
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
  };

  # Open firewall ports for HTTP/HTTPS and headscale
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [80 443 8080];
  };
  services = {
    headscale = {
      enable = true;
      address = "0.0.0.0";
      port = 8080;
      settings = {
        logtail.enabled = false;
        server_url = "https://${domain}";
        dns = {
          base_domain = "mercury";
          magic_dns = true;
          nameservers = {
            global = ["1.1.1.1" "1.0.0.1"];
          };
          override_local_dns = true;
          extra_records = [
            {
              name = "grafana.ncrmro.com";
              type = "A";
              value = "100.64.0.6";
            }
            {
              name = "vaultwarden.ncrmro.com";
              type = "A";
              value = "100.64.0.6";
            }
            {
              name = "loki.ncrmro.com";
              type = "A";
              value = "100.64.0.6";
            }
            {
              name = "adguard.home.ncrmro.com";
              type = "A";
              value = "100.64.0.6";
            }
          ];
        };
      };
    };

    nginx.virtualHosts.${domain} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://localhost:${toString config.services.headscale.port}";
        proxyWebsockets = true;
      };
    };
  };

  environment.systemPackages = [config.services.headscale.package];
}
