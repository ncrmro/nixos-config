{
  inputs,
  outputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    outputs.homeManagerModules.keystone-desktop
  ];

  # Enable desktop
  keystone.desktop.enable = true;
  keystone.desktop.hyprland.enable = true;

  # Override monitor config for VM (single virtual display)
  wayland.windowManager.hyprland.settings = {
    monitor = ["Virtual-1, 1920x1080@60, 0x0, 1"];
    workspace = ["1, monitor:Virtual-1"];
  };

  # Disable fingerprint auth in VM - no biometric hardware
  programs.hyprlock.settings.auth.fingerprint.enabled = lib.mkForce false;

  # Basic git config
  programs.git = {
    enable = true;
    userName = "ncrmro";
    userEmail = "ncrmro@example.com";
  };

  # Home Manager state version
  home.stateVersion = "24.05";
}
