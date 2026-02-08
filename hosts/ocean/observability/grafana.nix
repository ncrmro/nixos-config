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

    # Grafana API token for MCP server
    age.secrets.grafana-api-token = {
      file = ../../../secrets/grafana-api-token.age;
      owner = "root";
      mode = "0400";
    };

    # MCP server for Grafana
    systemd.services.mcp-grafana = {
      description = "MCP server for Grafana";
      wantedBy = [ "multi-user.target" ];
      after = [ "grafana.service" ];
      serviceConfig = {
        Restart = "on-failure";
        DynamicUser = true;
        LoadCredential = "grafana-token:${config.age.secrets.grafana-api-token.path}";
      };
      script = ''
        export GRAFANA_URL="http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}"
        export GRAFANA_SERVICE_ACCOUNT_TOKEN="$(cat $CREDENTIALS_DIRECTORY/grafana-token)"
        exec ${pkgs.mcp-grafana}/bin/mcp-grafana -transport sse -address 127.0.0.1:8090
      '';
    };

    services.nginx.virtualHosts."mcp-grafana.ncrmro.com" = {
      forceSSL = true;
      useACMEHost = "wildcard-ncrmro-com";
      extraConfig = cfg.nginxExtraConfig;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8090";
        proxyWebsockets = true;
        extraConfig = ''
          proxy_buffering off;
          proxy_cache off;
          proxy_read_timeout 86400s;
        '';
      };
    };
  };
}
