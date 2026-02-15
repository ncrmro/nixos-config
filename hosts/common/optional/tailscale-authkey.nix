# Tailscale with headscale pre-auth key from agenix
# This module configures automatic Tailscale authentication on boot using
# a pre-auth key stored as an agenix secret. Designed for agent VMs that
# need to join the tailnet without manual intervention.
#
# Usage in agent config:
#   services.tailscale.authkey = {
#     enable = true;
#     secretFile = config.age.secrets.headscale-authkey.path;
#     tags = [ "tag:agent" ];
#   };
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.tailscale.authkey;
in
{
  options.services.tailscale.authkey = {
    enable = mkEnableOption "Tailscale with agenix authkey";

    secretFile = mkOption {
      type = types.path;
      description = "Path to agenix secret containing the headscale pre-auth key";
    };

    loginServer = mkOption {
      type = types.str;
      default = "https://mercury.ncrmro.com";
      description = "Headscale login server URL";
    };

    tags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "ACL tags for this node (e.g., tag:agent)";
    };

    acceptRoutes = mkOption {
      type = types.bool;
      default = true;
      description = "Accept advertised routes from other nodes";
    };
  };

  config = mkIf cfg.enable {
    # Enable the base tailscale service
    services.tailscale.enable = true;

    # Oneshot service to authenticate on first boot
    systemd.services.tailscale-autoconnect = {
      description = "Automatic Tailscale login with headscale authkey";
      after = [
        "network-online.target"
        "tailscaled.service"
      ];
      wants = [
        "network-online.target"
        "tailscaled.service"
      ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script =
        let
          tagsFlag = optionalString (cfg.tags != [ ]) "--advertise-tags=${concatStringsSep "," cfg.tags}";
          acceptRoutesFlag = optionalString cfg.acceptRoutes "--accept-routes";
        in
        ''
          # Wait for tailscaled to be ready
          sleep 2

          # Check if already authenticated
          status="$(${pkgs.tailscale}/bin/tailscale status -json | ${pkgs.jq}/bin/jq -r .BackendState)"
          if [ "$status" = "Running" ]; then
            echo "Tailscale already connected"
            exit 0
          fi

          # Read authkey from agenix secret
          if [ ! -f "${cfg.secretFile}" ]; then
            echo "Authkey secret file not found: ${cfg.secretFile}"
            echo "This is expected on first boot before secrets are deployed."
            echo "Run nixos-rebuild after adding VM host key to secrets.nix"
            exit 0
          fi

          AUTHKEY=$(cat "${cfg.secretFile}")

          if [ -z "$AUTHKEY" ]; then
            echo "Authkey is empty"
            exit 1
          fi

          # Connect to headscale
          echo "Connecting to headscale at ${cfg.loginServer}..."
          ${pkgs.tailscale}/bin/tailscale up \
            --login-server=${cfg.loginServer} \
            --authkey="$AUTHKEY" \
            ${tagsFlag} \
            ${acceptRoutesFlag}

          echo "Tailscale connected successfully"
        '';
    };
  };
}
