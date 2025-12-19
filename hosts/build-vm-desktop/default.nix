{
  inputs,
  outputs,
  modulesPath,
  lib,
  pkgs,
  ...
}:
{
  # Fast VM for testing Keystone desktop configuration
  # Uses nixos-rebuild build-vm for rapid iteration without encryption/secure boot
  #
  # Build with: ./bin/build-vm desktop
  # Or manually: nixos-rebuild build-vm --flake .#build-vm-desktop
  #
  # The VM:
  # - Mounts host Nix store via 9P (read-only, fast)
  # - Creates persistent qcow2 disk at ./build-vm-desktop.qcow2
  # - Much faster than full deployment for testing desktop configs

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../common/global
    ../../modules/users/ncrmro.nix
    inputs.keystone.nixosModules.keystoneDesktop
  ];

  # System identity
  networking.hostName = "build-vm-desktop";
  networking.hostId = "00000000";

  # Simple boot configuration for VM
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Root filesystem (required for NixOS VM)
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # Enable Keystone desktop
  keystone.desktop = {
    enable = true;
    user = "ncrmro";
  };

  # Auto-login to Hyprland for faster testing
  services.greetd.settings.default_session = {
    command = "uwsm start -S -F Hyprland";
    user = "ncrmro";
  };

  # Enable SSH for remote access
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  # Basic networking with DHCP
  networking.useDHCP = lib.mkDefault true;

  # Enable serial console for VM debugging
  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=tty0"
  ];

  # Make users mutable for easy testing
  users.mutableUsers = true;

  # Simple passwords for testing
  users.users.ncrmro.initialPassword = "test";
  users.users.root.initialPassword = "root";

  # Allow sudo without password (testing only)
  security.sudo.wheelNeedsPassword = false;

  # Nix settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "ncrmro"
    ];
  };

  # Enable zsh for the user
  programs.zsh.enable = true;
  users.users.ncrmro.shell = pkgs.zsh;

  # Basic packages for testing
  environment.systemPackages = with pkgs; [
    curl
    git
    htop
  ];

  # Configure home-manager for test user
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = {
    inherit inputs outputs;
  };
  home-manager.users.ncrmro = import ../../home-manager/ncrmro/build-vm-desktop.nix;

  system.stateVersion = "25.05";
}
