{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.alloy-client;
in
{
  options.services.alloy-client = {
    enable = lib.mkEnableOption "Grafana Alloy log and metrics shipping client";

    lokiEndpoint = lib.mkOption {
      type = lib.types.str;
      default = "https://loki.ncrmro.com/loki/api/v1/push";
      description = "Loki endpoint URL for log shipping";
    };

    prometheusEndpoint = lib.mkOption {
      type = lib.types.str;
      default = "http://100.64.0.6:9090/api/v1/write";
      description = "Prometheus remote_write endpoint URL";
    };

    enableMetrics = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable metrics collection and shipping to Prometheus";
    };

    enableZfsExporter = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ZFS exporter metrics collection";
    };

    hostLabel = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "Host label to attach to logs and metrics";
    };

    extraLabels = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Additional static labels to attach to logs and metrics";
      example = {
        environment = "production";
        datacenter = "home";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.alloy = {
      enable = true;

      # Allow Alloy to access system resources
      # extraFlags = [
      #   "--server.http.listen-addr=127.0.0.1:12345"
      #   "--stability.level=generally-available"
      # ];
    };

    # Reduce shutdown timeout from default 1m30s to 10s
    systemd.services.alloy.serviceConfig.TimeoutStopSec = 10;

    # Enable ZFS exporter when requested
    services.prometheus.exporters.zfs = lib.mkIf cfg.enableZfsExporter {
      enable = true;
      port = 9134;
    };

    # Create Alloy configuration
    environment.etc."alloy/config.alloy".text =
      let
        allLabels = {
          host = cfg.hostLabel;
        }
        // cfg.extraLabels;
        labelsList = lib.mapAttrsToList (k: v: "            ${k} = \"${v}\"") allLabels;
        labelsStr = lib.concatStringsSep ",\n" labelsList + ",";
        staticLabels = ''
                  stage.static_labels {
                    values = {
          ${labelsStr}
                    }
                  }'';
      in
      ''
        // System journal logs collection
        loki.source.journal "system_logs" {
          format_as_json = true
          forward_to     = [loki.process.system.receiver]
          labels         = {
            job = "systemd-journal",
            host = "${cfg.hostLabel}",
          }
        }

        // Process system logs
        loki.process "system" {
          forward_to = [loki.write.default.receiver]

          ${staticLabels}

          // Extract log level from journal priority
          stage.json {
            expressions = {
              priority = "PRIORITY",
              unit = "_SYSTEMD_UNIT",
              message = "MESSAGE",
            }
          }

          // Map journal priority to log level
          stage.template {
            source = "priority"
            template = "{{ if eq . \"0\" }}emergency{{ else if eq . \"1\" }}alert{{ else if eq . \"2\" }}critical{{ else if eq . \"3\" }}error{{ else if eq . \"4\" }}warning{{ else if eq . \"5\" }}notice{{ else if eq . \"6\" }}info{{ else }}debug{{ end }}"
          }

          stage.labels {
            values = {
              level = "priority",
              unit = "unit",
            }
          }

          // Use MESSAGE as the log line content
          stage.output {
            source = "message"
          }
        }

        // Write to remote Loki
        loki.write "default" {
          endpoint {
            url = "${cfg.lokiEndpoint}"

            // Optional: Add authentication if needed
            // basic_auth {
            //   username = "user"
            //   password = "pass"
            // }
          }

          // Batch configuration for efficiency
          external_labels = {
            cluster = "nixos-home",
          }
        }
      ''
      + lib.optionalString cfg.enableMetrics ''

        // ============================================
        // Metrics Collection (Prometheus remote_write)
        // ============================================

        // Scrape local node_exporter
        prometheus.scrape "node" {
          targets = [{ __address__ = "127.0.0.1:9100" }]
          scrape_interval = "15s"
          job_name = "node"
          forward_to = [prometheus.relabel.instance.receiver]
        }
      ''
      + lib.optionalString (cfg.enableMetrics && cfg.enableZfsExporter) ''

        // Scrape local zfs_exporter
        prometheus.scrape "zfs" {
          targets = [{ __address__ = "127.0.0.1:9134" }]
          scrape_interval = "15s"
          job_name = "zfs"
          forward_to = [prometheus.relabel.instance.receiver]
        }
      ''
      + lib.optionalString cfg.enableMetrics ''

        // Relabel instance to hostname instead of IP:port
        prometheus.relabel "instance" {
          rule {
            target_label = "instance"
            replacement  = "${cfg.hostLabel}"
          }
          forward_to = [prometheus.remote_write.central.receiver]
        }

        // Ship metrics to central Prometheus
        prometheus.remote_write "central" {
          endpoint {
            url = "${cfg.prometheusEndpoint}"
          }
          external_labels = {
            host = "${cfg.hostLabel}",
            cluster = "nixos-home",
          }
        }
      '';
  };
}
