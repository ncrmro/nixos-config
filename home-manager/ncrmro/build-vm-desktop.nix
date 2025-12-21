{
  inputs,
  outputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  # Minimal home-manager config for VM desktop testing
  # Based on base.nix but simplified for faster iteration

  imports = [
    inputs.keystone.homeModules.desktop
    ../common/global
    ../common/features/cli
    ../common/features/desktop
  ];

  # Keystone desktop
  keystone.desktop.enable = true;
  keystone.desktop.hyprland.enable = true;

  # Simple monitor config for VM (single virtual display)
  wayland.windowManager.hyprland.settings = {
    monitor = [ ",preferred,auto,1" ];
  };

  # Git config for testing
  programs.git = {
    userName = "Test User";
    userEmail = "test@build-vm-desktop";
  };

  programs.fastfetch.enable = true;
}
