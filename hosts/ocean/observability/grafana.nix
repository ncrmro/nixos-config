{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.observability.grafana;
in
{
  options.my.observability.grafana = {
    enable = lib.mkEnableOption "Grafana dashboard service";
    nginxExtraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra configuration for the Nginx virtual host";
    };
  };

  config = lib.mkIf cfg.enable {
    services.grafana = {
      enable = true;
      settings = {
        server = {
          domain = "grafana.ncrmro.com";
          http_port = 3002;
          http_addr = "127.0.0.1";
          root_url = "https://grafana.ncrmro.com/";
        };
      };

      provision.enable = true;

      provision.dashboards.settings.providers = [
        {
          name = "nixos-dashboards";
          options.path = pkgs.linkFarm "grafana-dashboards" [
            {
              name = "node-exporter-full.json";
              path = pkgs.fetchurl {
                url = "https://grafana.com/api/dashboards/1860/revisions/37/download";
                hash = "sha256-1DE1aaanRHHeCOMWDGdOS1wBXxOF84UXAjJzT5Ek6mM=";
              };
            }
          ];
        }
      ];

      provision.datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
        }
        {
          name = "Loki";
          type = "loki";
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
        }
      ];
    };

    services.nginx.virtualHosts."grafana.ncrmro.com" = {
      forceSSL = true;
      useACMEHost = "wildcard-ncrmro-com";
      extraConfig = cfg.nginxExtraConfig;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
        proxyWebsockets = true;
      };
    };
  };
}
