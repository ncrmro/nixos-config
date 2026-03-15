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

      # Enable remote write receiver for Alloy push-based metrics
      extraFlags = [ "--web.enable-remote-write-receiver" ];

      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9100;
        };
      };

      # Ocean's node exporter is already scraped by Alloy (with host/cluster labels)
      # via remote-write. Only scrape non-Alloy targets here to avoid duplicate series
      # that cause alert evaluation errors (duplicate empty-label frames).
      scrapeConfigs = [
        {
          job_name = "iot";
          static_configs = [
            {
              targets = [ "192.168.1.140:80" ];
              labels = {
                instance = "seed-incubator";
                environment = "home";
                location = "garage";
                device_type = "plant-seed-incubator";
                plants = "dill,arugula";
              };
            }
            {
              targets = [ "192.168.1.145:80" ];
              labels = {
                instance = "plant-monitor";
                environment = "home";
                device_type = "plant-monitor";
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
