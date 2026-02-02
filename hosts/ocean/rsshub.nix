{ pkgs, ... }:
let
  tailscaleOnly = ''
    allow 100.64.0.0/10;
    allow fd7a:115c:a1e0::/48;
    deny all;
  '';
in
{
  systemd.services.rsshub = {
    description = "RSSHub";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      NODE_ENV = "production";
      PORT = "1200";
    };
    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      StateDirectory = "rsshub";
      ExecStart = "${pkgs.rsshub}/bin/rsshub";
      Restart = "on-failure";
    };
  };

  services.nginx.virtualHosts."rsshub.ncrmro.com" = {
    forceSSL = true;
    useACMEHost = "wildcard-ncrmro-com";
    extraConfig = tailscaleOnly;
    locations."/" = {
      proxyPass = "http://127.0.0.1:1200";
      proxyWebsockets = true;
    };
  };
}
