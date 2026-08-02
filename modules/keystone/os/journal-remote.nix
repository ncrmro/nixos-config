# TODO(upstream-keystone): modules/os/journal-remote.nix — remove the obsolete
# services.journald.remote.listen definition for current NixOS, and retain the
# explicit socket reset before binding the nginx backend to localhost.
#
# This is a complete holding copy because a removed NixOS option cannot be
# undone with a later module definition; the owning upstream module must be
# disabled and replaced as a unit.
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.keystone.os.journalRemote;
  osCfg = config.keystone.os;
  hostname = config.networking.hostName;
  domain = config.keystone.domain;

  journalRemoteHosts = filterAttrs (_: h: h.journalRemote or false) config.keystone.hosts;
  journalRemoteHostNames = attrNames journalRemoteHosts;
  derivedServerHost =
    if journalRemoteHostNames != [ ] then
      (builtins.getAttr (builtins.head journalRemoteHostNames) journalRemoteHosts).hostname
    else
      null;

  effectiveServerHost = if cfg.serverHost != null then cfg.serverHost else derivedServerHost;

  derivedServerUrl =
    if effectiveServerHost != null then
      if domain != null then
        "https://journal.${domain}:443"
      else
        "http://${effectiveServerHost}:${toString cfg.server.port}"
    else
      null;

  effectiveServerUrl =
    if cfg.upload.serverUrl != null then cfg.upload.serverUrl else derivedServerUrl;

  isServer = effectiveServerHost == hostname;
  shouldUpload = !isServer && cfg.upload.enable && effectiveServerUrl != null;
  useNginxProxy = domain != null;
in
{
  options.keystone.os.journalRemote = {
    serverHost = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Hostname of the journal-remote server. Auto-derived from keystone.hosts
        (the host with journalRemote = true). Override only for non-standard setups.
        When null and no host has journalRemote = true, journal forwarding is disabled.
      '';
      example = "ocean";
    };

    server = {
      enable = mkEnableOption "centralized journal collection (systemd-journal-remote receiver)";

      port = mkOption {
        type = types.port;
        default = 19532;
        description = "Listen port for systemd-journal-remote.";
      };
    };

    upload = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Forward this host's journal to the fleet's journal-remote server.
          Set to false to opt out (e.g. for ephemeral VMs or test boxes).
          Has no effect if no serverHost is configured.
        '';
      };

      serverUrl = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          URL of the journal-remote server. Auto-derived from serverHost
          when null. Override for non-standard setups.
        '';
      };
    };
  };

  config = mkIf osCfg.enable (mkMerge [
    (mkIf isServer {
      keystone.os.journalRemote.server.enable = mkDefault true;
    })

    {
      assertions = [
        {
          assertion = length journalRemoteHostNames <= 1;
          message = ''
            keystone.hosts: multiple hosts have journalRemote = true: ${concatStringsSep ", " journalRemoteHostNames}.
            Exactly one host should be the journal-remote server.
          '';
        }
      ];

      warnings = optional (cfg.server.enable && effectiveServerHost == null) ''
        keystone.os.journalRemote: server.enable is true but no serverHost is configured
        and no host in keystone.hosts has journalRemote = true. Clients won't auto-discover
        this server. Set journalRemote = true on this host's entry in keystone.hosts.
      '';
    }

    (mkIf isServer {
      services.journald.remote = {
        enable = true;
        port = cfg.server.port;
      };
    })

    (mkIf (isServer && useNginxProxy) {
      systemd.sockets.systemd-journal-remote.listenStreams = mkForce [
        ""
        "127.0.0.1:${toString cfg.server.port}"
      ];
    })

    (mkIf (isServer && !useNginxProxy) {
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ cfg.server.port ];
    })

    (mkIf shouldUpload {
      services.journald.upload = {
        enable = true;
        settings.Upload = {
          URL = effectiveServerUrl;
        }
        // optionalAttrs useNginxProxy {
          ServerCertificateFile = "-";
          ServerKeyFile = "-";
          TrustedCertificateFile = "/etc/ssl/certs/ca-bundle.crt";
        };
      };

      systemd.services.systemd-journal-upload = {
        serviceConfig = {
          SuccessExitStatus = [ 1 ];
          RestartSec = mkForce "5min";
        };

        # Keep an unhealthy observability uploader from making
        # switch-to-configuration reject an otherwise valid system switch.
        restartIfChanged = mkDefault false;
      };
    })
  ]);
}
