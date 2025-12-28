{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.tailscale.node;
in
{
  options.services.tailscale.node = {
    enable = mkEnableOption "Tailscale node configuration";

    tags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of tags to advertise for this Tailscale node";
      example = [
        "tag:k8s-cluster"
        "tag:k8s-master"
      ];
    };

    loginServer = mkOption {
      type = types.str;
      default = "https://mercury.ncrmro.com";
      description = "Headscale login server URL";
    };

    useRoutingFeatures = mkOption {
      type = types.str;
      default = "client";
      description = "Routing features to enable";
    };
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = cfg.useRoutingFeatures;

      extraUpFlags = [
        "--login-server=${cfg.loginServer}"
      ]
      ++ optionals (cfg.tags != [ ]) [
        "--advertise-tags=${concatStringsSep "," cfg.tags}"
      ];
    };

    # Install the tailscale package
    environment.systemPackages = with pkgs; [
      tailscale
    ];

    # Open firewall for Tailscale
    networking.firewall = {
      checkReversePath = "loose";
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };
}
