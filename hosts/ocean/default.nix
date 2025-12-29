{
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
    # ../common/optional/secureboot.nix
    ../common/optional/agenix.nix
    ./adguard-home.nix
    ../common/optional/servarr.nix
    ../common/optional/home-assistant.nix
    ./k3s.nix
    ./k3s-storage-classes.nix
    ./nfs.nix
    ../common/optional/smb-backup-shares.nix
    ./nginx.nix
    ../common/kubernetes/default.nix
    ./vms.nix
    ../../modules/users/ncrmro.nix
    ../../modules/users/root.nix
    inputs.keystone.nixosModules.operating-system
  ];

  keystone.os.enable = true;
  keystone.os.storage.enable = false;
  keystone.os.mail.enable = true;


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

  boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;
  boot.kernel.sysctl."fs.inotify.max_user_instances" = 512;

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
