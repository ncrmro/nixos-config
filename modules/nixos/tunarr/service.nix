{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.tunarr;
in {
  options.services.tunarr = {
    enable = mkEnableOption "Tunarr - Create a classic TV experience using your own media";

    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix {};
      defaultText = literalExpression "pkgs.tunarr";
      description = "The Tunarr package to use.";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/tunarr";
      description = "The directory where Tunarr stores its data files.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open ports in the firewall for the Tunarr web interface.";
    };

    port = mkOption {
      type = types.port;
      default = 8000;
      description = "Port on which Tunarr will listen.";
    };

    user = mkOption {
      type = types.str;
      default = "tunarr";
      description = "User account under which Tunarr runs.";
    };

    group = mkOption {
      type = types.str;
      default = "tunarr";
      description = "Group under which Tunarr runs.";
    };

    extraGroups = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["media" "video"];
      description = "Additional groups for the Tunarr user (useful for accessing media files).";
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.settings."10-tunarr".${cfg.dataDir}.d = {
      inherit (cfg) user group;
      mode = "0700";
    };

    systemd.services.tunarr = {
      description = "Tunarr";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];

      environment = {
        TUNARR_BIND_ADDR = "0.0.0.0";
        TUNARR_PORT = toString cfg.port;
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/tunarr";
        WorkingDirectory = cfg.dataDir;
        Restart = "on-failure";
        RestartSec = "5s";

        # Hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [cfg.dataDir];
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [cfg.port];
    };

    users.users = mkIf (cfg.user == "tunarr") {
      tunarr = {
        isSystemUser = true;
        group = cfg.group;
        extraGroups = cfg.extraGroups;
        home = cfg.dataDir;
      };
    };

    users.groups = mkIf (cfg.group == "tunarr") {
      tunarr = {};
    };
  };
}
