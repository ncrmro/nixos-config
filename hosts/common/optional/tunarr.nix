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

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/tunarr";
      description = "Directory where Tunarr will store its configuration and data";
    };

    port = mkOption {
      type = types.port;
      default = 8000;
      description = "Port on which Tunarr will listen";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open the firewall for Tunarr on the tailscale interface";
    };

    imageTag = mkOption {
      type = types.str;
      default = "latest";
      description = "Docker image tag to use (latest, edge, or specific version)";
    };

    timezone = mkOption {
      type = types.str;
      default = config.time.timeZone or "UTC";
      description = "Timezone for the container";
    };

    logLevel = mkOption {
      type = types.enum ["debug" "info" "warn" "error"];
      default = "info";
      description = "Log level for Tunarr";
    };

    user = mkOption {
      type = types.str;
      default = "tunarr";
      description = "User account under which Tunarr runs";
    };

    group = mkOption {
      type = types.str;
      default = "tunarr";
      description = "Group under which Tunarr runs";
    };

    extraGroups = mkOption {
      type = types.listOf types.str;
      default = [];
      example = ["media" "video"];
      description = "Additional groups for the Tunarr user (useful for accessing media files or hardware encoding)";
    };
  };

  config = mkIf cfg.enable {
    # Create user and group
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      extraGroups = cfg.extraGroups;
      home = cfg.dataDir;
      createHome = true;
      homeMode = "750";
    };

    users.groups.${cfg.group} = {};

    # Ensure data directory exists with correct permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
    ];

    # Enable Docker if not already enabled
    virtualisation.docker.enable = mkDefault true;

    # Configure Tunarr container
    virtualisation.oci-containers = {
      backend = "docker";
      containers.tunarr = {
        image = "chrisbenincasa/tunarr:${cfg.imageTag}";
        autoStart = true;

        ports = [
          "${toString cfg.port}:8000"
        ];

        volumes = [
          "${cfg.dataDir}:/config/tunarr"
        ];

        environment = {
          TZ = cfg.timezone;
          LOG_LEVEL = cfg.logLevel;
          PUID = toString config.users.users.${cfg.user}.uid;
          PGID = toString config.users.groups.${cfg.group}.gid;
        };

        extraOptions = [
          "--network=host"
          # If the user is in the video group (for hardware encoding), add device access
        ] ++ (
          if builtins.elem "video" cfg.extraGroups
          then ["--device=/dev/dri:/dev/dri"]
          else []
        );
      };
    };

    # Open firewall on tailscale interface if requested
    networking.firewall.interfaces.tailscale0 = mkIf cfg.openFirewall {
      allowedTCPPorts = [cfg.port];
    };
  };
}
