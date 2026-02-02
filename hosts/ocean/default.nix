{
  config,
  inputs,
  outputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.default
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
    ./k3s.nix
    ./k3s-storage-classes.nix
    ./nfs.nix
    ../common/optional/smb-backup-shares.nix
    ./nginx.nix
    ./vaultwarden.nix
    ./rsshub.nix
    ../common/kubernetes/default.nix
    ./vms.nix
    ../../modules/users/ncrmro.nix
    ../../modules/users/root.nix
    inputs.keystone.nixosModules.operating-system
  ];

  keystone.os.enable = true;
  keystone.os.storage.enable = false;
  keystone.os.ssh.enable = false;
  keystone.os.mail.enable = true;

  # Give stalwart-mail access to ACME certs
  users.users.stalwart-mail.extraGroups = [ "nginx" ];

  # Stalwart admin password (SHA-512 hash, not plaintext).
  # fallback-admin.secret expects a $6$ hash. Generate with: mkpasswd -m sha-512
  age.secrets.stalwart-admin-password = {
    file = ../../secrets/stalwart-admin-password.age;
    owner = "root";
    mode = "0400";
  };

  # Configure Stalwart TLS and admin auth
  services.stalwart-mail = {
    credentials = {
      admin_password = config.age.secrets.stalwart-admin-password.path;
    };
    settings = {
      certificate.default = {
        cert = "%{file:/var/lib/acme/wildcard-ncrmro-com/fullchain.pem}%";
        private-key = "%{file:/var/lib/acme/wildcard-ncrmro-com/key.pem}%";
        default = true;
      };
      authentication.fallback-admin = {
        user = "admin";
        secret = "%{file:/run/credentials/stalwart-mail.service/admin_password}%";
      };
    };
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

  # Home Manager configuration
  programs.zsh.enable = true;
  users.users.ncrmro.shell = pkgs.zsh;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = { inherit inputs outputs; };
  home-manager.users.ncrmro = import ../../home-manager/ncrmro/ocean.nix;

  environment.variables = {
    TERM = "xterm-256color"; # Or your preferred terminal type
  };

  # Configure Tailscale node with Kubernetes tags
  services.tailscale.node = {
    enable = true;
    tags = [
      "tag:k8s-cluster"
      "tag:k8s-master"
    ];
  };

  # Configure SMB backup shares
  services.smb-backup-shares = {
    enable = true;
    backupsRoot = "ocean/backups";
    timeMachinePasswordFile = ../../secrets/samba-timemachine-password.age;
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
  ];

  system.stateVersion = "25.11";
}
