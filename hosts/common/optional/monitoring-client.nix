{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.monitoring-client;
in {
  options.services.monitoring-client = {
    enable = lib.mkEnableOption "monitoring client with Prometheus exporters";

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "IP address to listen on (use Tailscale IP for remote access)";
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.node = {
      enable = true;
      listenAddress = cfg.listenAddress;
    };

    # Ensure node exporter waits for tailscale to be ready
    systemd.services.prometheus-node-exporter = {
      after = ["tailscaled.service"];
      wants = ["tailscaled.service"];
    };
  };
}
