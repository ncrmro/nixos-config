{ config, ... }:
let domain = "mercury.ncrmro.com";
in {
  # Configure ACME for SSL certificates
  security.acme = {
    acceptTerms = true;
    defaults.email = "ncrmro@gmail.com";  # Replace with your email
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
    allowedTCPPorts = [ 80 443 8080 ];
  };
  services = {
    headscale = {
      enable = true;
      address = "0.0.0.0";
      port = 8080;
      settings = { 
        logtail.enabled = false;
        server_url = "https://${domain}";
        dns.base_domain = "mercury";

      };
    };

    nginx.virtualHosts.${domain} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass =
          "http://localhost:${toString config.services.headscale.port}";
        proxyWebsockets = true;
      };
    };
  };

  environment.systemPackages = [ config.services.headscale.package ];
}
