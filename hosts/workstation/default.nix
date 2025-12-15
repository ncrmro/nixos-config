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
    ../common/optional/ssh-mosh.nix
    ../common/optional/secureboot.nix
    ../common/optional/ollama.nix
    ../common/optional/nfs-client.nix
    ../common/optional/monitoring-client.nix
    ../common/optional/alloy-client.nix
    ../common/optional/docker-rootless.nix
    ../common/optional/virt-manager.nix
    ../common/optional/shairport-sync.nix
    outputs.nixosModules.keystone-desktop
    outputs.nixosModules.bambu-studio
    ./windows11-vm.nix
    ../../modules/nixos/steam.nix
  ];

  programs.bambu-studio.enable = true;

  programs.zsh.enable = true;
  users.mutableUsers = true;
  users.users.ncrmro.shell = pkgs.zsh;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = { inherit inputs outputs; };
  home-manager.users.ncrmro = import ../../home-manager/ncrmro/ncrmro-workstation.nix;

  environment.systemPackages = with pkgs; [
    alsa-utils
    lsof
    amdgpu_top
    # llama-cpp from upstream flake with Vulkan support for AMD GPU acceleration
    inputs.llama-cpp.packages.${pkgs.system}.vulkan
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

  # Static networking on enp5s0 (router: 192.168.1.254 / 2600:1702:6250:4c80::1, DHCP server at 192.168.1.10)
  networking.useDHCP = false;
  networking.hostId = "cb1216ed"; # generate with: head -c 8 /etc/machine-id
  networking.hostName = "ncrmro-workstation";

  networking.interfaces.enp5s0 = {
    # Keep the existing static IPv4 address
    ipv4.addresses = [
      {
        address = "192.168.1.69";
        prefixLength = 24;
      }
    ];
    # Static IPv6 within router-advertised prefix 2600:1702:6250:4c80::/64
    # Alternative: Remove this block to use SLAAC (auto-configured from router advertisements)
    ipv6.addresses = [
      {
        address = "2600:1702:6250:4c80::69";
        prefixLength = 64;
      }
    ];
  };

  networking.defaultGateway = {
    address = "192.168.1.254";
    interface = "enp5s0";
  };

  networking.defaultGateway6 = {
    address = "2600:1702:6250:4c80::1";
    interface = "enp5s0";
  };

  networking.nameservers = [
    # Local DNS on ocean (DHCP/DNS host)
    "192.168.1.10"
    "2600:1702:6250:4c80:da5e:d3ff:fe8e:3126"
    # Uncommit if local server goes down
    # "1.1.1.1"
  ];

  system.stateVersion = "25.11";
}
