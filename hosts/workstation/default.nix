{
  inputs,
  outputs,
  modulesPath,
  lib,
  pkgs,
  ...
}@args:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.default
    ./disk-config.nix
    ../common/optional/zfs.luks.root.nix
    ./hardware-configuration.nix
    ../common/global
    ../../modules/users/ncrmro.nix
    ../../modules/users/root.nix
    ../common/optional/tailscale.node.nix
    ../common/optional/eternal-terminal.nix
    # ../common/optional/secureboot.nix # Conflict with keystone
    ../common/optional/ollama.nix
    ../common/optional/nfs-client.nix
    ../common/optional/monitoring-client.nix
    ../common/optional/alloy-client.nix
    ../common/optional/docker-rootless.nix
    ../common/optional/virt-manager.nix
    ../common/optional/agenix.nix
    inputs.keystone.nixosModules.operating-system
    inputs.keystone.nixosModules.desktop
    outputs.nixosModules.bambu-studio
    ./windows11-vm.nix
    ../../modules/nixos/steam.nix
  ];

  keystone.os.services.airplay = {
    enable = true;
    name = "Workstation Speakers";
  };

  # Secure Boot configuration (module provided by keystone)
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  programs.bambu-studio.enable = true;

  programs.zsh.enable = true;
  users.mutableUsers = true;
  users.users.ncrmro.shell = pkgs.zsh;
  users.users.ncrmro.extraGroups = [
    "render"
    "video"
  ];

  # Stalwart mail user password for himalaya
  age.secrets.stalwart-mail-ncrmro-password = {
    file = ../../secrets/stalwart-mail-ncrmro-password.age;
    owner = "ncrmro";
    mode = "0400";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = { inherit inputs outputs; };
  home-manager.users.ncrmro = import ../../home-manager/ncrmro/ncrmro-workstation.nix;

  environment.systemPackages = with pkgs; [
    alsa-utils
    lsof
    amdgpu_top
    lutris
    # llama-cpp from upstream flake with Vulkan support for AMD GPU acceleration
    inputs.llama-cpp.packages.${pkgs.stdenv.hostPlatform.system}.vulkan
  ];

  environment.variables = {
    TERM = "xterm-256color"; # Or your preferred terminal type
  };
  programs.nix-ld.enable = true;

  hardware.keyboard.uhk.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Configure Tailscale node (no tags for client machine)
  services.tailscale.node = {
    enable = true;
  };

  services.openssh.settings.PermitRootLogin = "yes";

  keystone.desktop = {
    enable = true;
    user = "ncrmro";
  };

  services.monitoring-client = {
    enable = true;
    listenAddress = "100.64.0.3";
  };

  services.alloy-client = {
    enable = true;
    extraLabels = {
      environment = "home";
      device_type = "workstation";
    };
  };

  # Disable HDA Intel audio (GPU HDMI + onboard) - keep only USB audio devices
  # This may help with Hyprland crashes caused by snd_hda_intel spurious responses
  boot.blacklistedKernelModules = [ "snd_hda_intel" ];

  # Enable aarch64 emulation for cross-compilation
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Increase inotify limits for file watchers (IDEs, build tools, etc.)
  # Each watch uses ~1KB kernel memory. Rule of thumb: 1M watches per 16GB RAM.
  # 10M watches ≈ 10GB kernel memory - suitable for 32GB+ systems.
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 10485760;
    "fs.inotify.max_user_instances" = 8192;
  };

  # Bridge networking: br0 enslaves enp5s0 so VMs can get LAN IPs directly
  networking.useDHCP = false;
  networking.hostId = "cb1216ed"; # generate with: head -c 8 /etc/machine-id
  networking.hostName = "ncrmro-workstation";

  networking.bridges.br0.interfaces = [ "enp5s0" ];

  networking.interfaces.enp5s0 = { };

  networking.interfaces.br0 = {
    ipv4.addresses = [
      {
        address = "192.168.1.69";
        prefixLength = 24;
      }
    ];
    ipv6.addresses = [
      {
        address = "2600:1702:6250:4c80::69";
        prefixLength = 64;
      }
    ];
  };

  networking.defaultGateway = {
    address = "192.168.1.254";
    #interface = "br0";
  };

  networking.defaultGateway6 = {
    address = "2600:1702:6250:4c80::1";
    #    interface = "br0";
  };
  # needed for remote building I think nix --builders
  nix.settings.trusted-users = [
    "root"
    "ncrmro"
  ];
  networking.nameservers = [
    # Local DNS on ocean (DHCP/DNS host)
    "192.168.1.10"
    "2600:1702:6250:4c80:da5e:d3ff:fe8e:3126"
    # Uncommit if local server goes down
    # "1.1.1.1"
  ];

  system.stateVersion = "25.11";
}
