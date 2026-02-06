{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.observability.loki;
in
{
  options.my.observability.loki = {
    enable = lib.mkEnableOption "Loki log aggregation service";
    nginxExtraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra configuration for the Nginx virtual host";
    };
  };

  config = lib.mkIf cfg.enable {
    services.loki = {
      enable = true;
      configuration = {
        server.http_listen_port = 3100;
        auth_enabled = false;

        common = {
          ring = {
            instance_addr = "127.0.0.1";
            kvstore.store = "inmemory";
          };
          replication_factor = 1;
          path_prefix = "/var/lib/loki";
        };

        schema_config = {
          configs = [
            {
              from = "2024-04-01";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };

        storage_config = {
          filesystem = {
            directory = "/var/lib/loki/chunks";
          };
        };

        compactor = {
          working_directory = "/var/lib/loki/compactor";
          delete_request_store = "filesystem";
        };

        limits_config = {
          retention_period = "90d";
        };
      };
    };

    services.nginx.virtualHosts."loki.ncrmro.com" = {
      forceSSL = true;
      useACMEHost = "wildcard-ncrmro-com";
      extraConfig = cfg.nginxExtraConfig;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
        proxyWebsockets = true;
      };
    };
  };
}
