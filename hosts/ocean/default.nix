{
  config,
  inputs,
  outputs,
  pkgs,
  ...
}:
{
  imports = [
    ../common/optional/home-manager-base.nix
    ./hardware-configuration.nix
    ./disk-config.nix
    ../common/optional/zfs.luks.root.nix
    ./zpool.ocean.noblock.nix
    ./zfs.users.nix
    ./zfs.local-replication.nix
    ../common/global
    ../common/optional/tailscale.node.nix

    ../common/optional/agenix.nix
    ./adguard-home.nix
    ../common/optional/servarr.nix
    ../common/optional/home-assistant.nix
    ./nfs.nix
    ../common/optional/smb-backup-shares.nix
    ./nginx.nix
    ./vaultwarden.nix
    ./rsshub.nix
    ./miniflux.nix
    ./observability
    ../common/optional/alloy-client.nix
    ./immich.nix
    ../../modules/keystone.nix
    ../../modules/keystone.server.nix
    ../common/optional/podman.nix
    ./vms.nix
  ];

  # Enable Mesa/OpenGL drivers for EGL headless rendering
  hardware.graphics.enable = true;

  my.observability = {
    prometheus = {
      enable = true;
      nginxExtraConfig = ''
        allow 100.64.0.0/10;
        allow fd7a:115c:a1e0::/48;
        deny all;
      '';
    };
    loki = {
      enable = true;
      nginxExtraConfig = ''
        allow 100.64.0.0/10;
        allow fd7a:115c:a1e0::/48;
        deny all;
      '';
    };
    grafana = {
      enable = true;
      nginxExtraConfig = ''
        allow 100.64.0.0/10;
        allow fd7a:115c:a1e0::/48;
        deny all;
      '';
      smtp = {
        enable = true;
        host = "mail.ncrmro.com:587";
        from = "grafana@ncrmro.com";
        user = "grafana";
        passwordFile = config.age.secrets.grafana-smtp-password.path;
      };
    };
  };

  # Grafana SMTP password for alerting
  age.secrets.grafana-smtp-password = {
    file = "${inputs.agenix-secrets}/secrets/grafana-smtp-password.age";
    owner = "grafana";
    group = "grafana";
    mode = "0400";
  };

  services.alloy-client = {
    enable = true;
    lokiEndpoint = "http://127.0.0.1:3100/loki/api/v1/push";
    prometheusEndpoint = "http://127.0.0.1:9090/api/v1/write";
    enableZfsExporter = true;
    extraLabels = {
      environment = "home";
      device_type = "server";
    };
  };

  keystone.os.mail = {
    enable = true;
    # Allow Tailscale IPs (agent VMs, phones, etc) - prevents fail2ban blocking
    allowedIps = [
      "100.64.0.0/10" # Tailscale IPv4 CGNAT
      "fd7a:115c:a1e0::/48" # Tailscale IPv6
    ];
  };

  # Give stalwart-mail access to ACME certs
  users.users.stalwart-mail.extraGroups = [ "nginx" ];

  # Stalwart admin password (SHA-512 hash, not plaintext).
  # fallback-admin.secret expects a $6$ hash. Generate with: mkpasswd -m sha-512
  age.secrets.stalwart-admin-password = {
    file = "${inputs.agenix-secrets}/secrets/stalwart-admin-password.age";
    owner = "stalwart-mail";
    group = "stalwart-mail";
    mode = "0400";
  };

  # Stalwart mail user password for himalaya
  age.secrets.stalwart-mail-ncrmro-password = {
    file = "${inputs.agenix-secrets}/secrets/stalwart-mail-ncrmro-password.age";
    owner = "ncrmro";
    mode = "0400";
  };

  # Configure Stalwart TLS and admin auth
  services.stalwart-mail = {
    settings = {
      certificate.default = {
        cert = "%{file:/var/lib/acme/wildcard-ncrmro-com/fullchain.pem}%";
        private-key = "%{file:/var/lib/acme/wildcard-ncrmro-com/key.pem}%";
        default = true;
      };
      authentication.fallback-admin = {
        user = "admin";
        secret = "%{file:/run/agenix/stalwart-admin-password}%";
      };
    };
  };

  # Restart stalwart after ACME cert renewal so it picks up the new cert
  security.acme.certs."wildcard-ncrmro-com".reloadServices = [ "stalwart.service" ];
  # Tailscale IP for auto-DNS record generation (used by keystone dns.nix)
  keystone.server.tailscaleIP = "100.64.0.6";

  # Keystone server ACME (wildcard cert via Cloudflare DNS-01)
  keystone.server.acme = {
    enable = true;
    extraDomainNames = [ "*.home.ncrmro.com" ];
  };

  # Cloudflare API token for ACME DNS-01 challenge
  age.secrets.cloudflare-api-token = {
    file = "${inputs.agenix-secrets}/secrets/cloudflare-api-token.age";
    owner = "acme";
    group = "acme";
  };

  # Host-specific server services (enable is in modules/keystone.server.nix)
  keystone.server.services.attic.enable = true;

  # Attic server token signing key
  age.secrets.attic-server-token-key = {
    file = "${inputs.agenix-secrets}/secrets/attic-server-token-key.age";
  };

  keystone.os.gitServer = {
    enable = true;
    domain = "git.ncrmro.com";
    httpPort = 3001;
    ssh = {
      openFirewall = true;
      tailscaleOnly = true;
    };
  };

  # Override ROOT_URL to use HTTPS through Nginx
  services.forgejo.settings.server.ROOT_URL = "https://git.ncrmro.com/";

  # Per-host home-manager config: terminal-only, rebuild target, mail
  home-manager.users.ncrmro = import ../../home-manager/ncrmro/ocean.nix;

  environment.variables = {
    TERM = "xterm-256color"; # Or your preferred terminal type
  };

  services.tailscale.node = {
    enable = true;
  };

  # Configure SMB backup shares
  services.smb-backup-shares = {
    enable = true;
    backupsRoot = "ocean/backups";
    timeMachinePasswordFile = "${inputs.agenix-secrets}/secrets/samba-timemachine-password.age";
    timeMachineQuota = "2T";
    windowsBackupQuota = "1T";
  };

  services.openssh.settings.PermitRootLogin = "yes";

  networking.hostId = "89cbac5f"; # generate with: head -c 8 /etc/machine-id
  networking.hostName = "ocean";

  networking.interfaces.enp4s0 = {
    ipv4.addresses = [
      {
        address = "192.168.1.10";
        prefixLength = 24;
      }
    ];
  };

  networking.defaultGateway = {
    address = "192.168.1.254";
    interface = "enp4s0";
  };

  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  nix.settings.trusted-users = [
    "root"
    "ncrmro"
  ];

  boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;
  boot.kernel.sysctl."fs.inotify.max_user_instances" = 512;
  # Increase the maximum number of IGMP multicast group memberships.
  # This addresses Avahi mDNS discovery issues where 'IP_ADD_MEMBERSHIP failed'
  # due to exhaustion of multicast group slots, common in environments with
  # many virtual network interfaces (e.g., K3s containers).
  boot.kernel.sysctl."net.ipv4.igmp_max_memberships" = 1000;

  environment.systemPackages = [
    pkgs.sbctl
    pkgs.htop
    pkgs.usbutils
    pkgs.bottom
    pkgs.btop
    pkgs.dig
    pkgs.passt # For libvirt user session VMs with passt networking backend
  ];

  system.stateVersion = "25.11";
}
