{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.observability.prometheus;
in
{
  options.my.observability.prometheus = {
    enable = lib.mkEnableOption "Prometheus monitoring service";
    nginxExtraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra configuration for the Nginx virtual host";
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      port = 9090;
      retentionTime = "90d";
      checkConfig = "syntax-only";

      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9100;
        };
      };

      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = [
                "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
              ];
              labels = {
                instance = config.networking.hostName;
                environment = "home";
              };
            }
            # Migrated targets from K8s config
            {
              targets = [ "100.64.0.3:9100" ];
              labels = {
                instance = "ncrmro-workstation";
                environment = "home";
              };
            }
            {
              targets = [ "100.64.0.1:9100" ];
              labels = {
                instance = "ncrmro-laptop";
                environment = "home";
              };
            }
          ];
        }
      ];
    };

    services.nginx.virtualHosts."prometheus.ncrmro.com" = {
      forceSSL = true;
      useACMEHost = "wildcard-ncrmro-com";
      extraConfig = cfg.nginxExtraConfig;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.prometheus.port}";
        proxyWebsockets = true;
      };
    };
  };
}
