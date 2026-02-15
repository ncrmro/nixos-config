{ config, ... }:
let
  adguardDomain = "adguard.mercury.ncrmro.com";
  tailscaleIP = "100.64.0.38";
in
{
  # Cloudflare API token for ACME DNS-01 challenge
  age.secrets.cloudflare-api-token = {
    file = ../../agenix-secrets/secrets/cloudflare-api-token.age;
    owner = "acme";
    group = "acme";
  };

  # ACME DNS-01 challenge with Cloudflare
  security.acme.certs.${adguardDomain} = {
    domain = adguardDomain;
    dnsProvider = "cloudflare";
    environmentFile = config.age.secrets.cloudflare-api-token.path;
    group = "nginx";
    # Use public DNS for zone lookup (local DNS goes through Headscale)
    extraLegoFlags = [ "--dns.resolvers=1.1.1.1:53" ];
  };

  # Nginx reverse proxy with Let's Encrypt (Tailscale only)
  services.nginx.virtualHosts.${adguardDomain} = {
    listenAddresses = [ tailscaleIP ];
    forceSSL = true;
    useACMEHost = adguardDomain;
    locations."/" = {
      proxyPass = "http://127.0.0.1:3000";
      proxyWebsockets = true;
    };
  };
}
