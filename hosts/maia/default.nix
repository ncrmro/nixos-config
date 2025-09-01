# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./disk-config.nix
    ../common/global/zfs.luks.root.nix
    # ./zpool.lake.nix
    ../common/global/openssh.nix
    ../common/global/secureboot.nix
    ../common/optional/tailscale.nix
  ];

  boot.initrd.systemd.emergencyAccess = true;

  environment.systemPackages = [
    pkgs.sbctl
    pkgs.htop
    pkgs.usbutils
  ];

  # Set your time zone.
  time.timeZone = "America/Chicago";

  services.openssh.settings.PermitRootLogin = "yes";

  networking.hostId = "22386ca6"; # generate with: head -c 8 /etc/machine-id
  networking.hostName = "maia"; # Define your hostname.

  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?
}
