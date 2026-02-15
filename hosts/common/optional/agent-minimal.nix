# Minimal NixOS configuration for Agent VMs
# Fast-building base image - add full config via nixos-rebuild after boot
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # SSH Server only - no desktop
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # Persist SSH host keys
  services.openssh.hostKeys = [
    {
      path = "/var/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];

  # Basic networking
  networking.useDHCP = true;
  networking.firewall.enable = true;

  # Nix with Flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Minimal packages
  environment.systemPackages = with pkgs; [
    vim
    curl
    git
  ];

  # Sudo
  security.sudo.wheelNeedsPassword = false;

  # Timezone/locale
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # Boot for qcow2
  boot.loader.grub.device = "/dev/vda";
  boot.loader.timeout = 0;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };
}
