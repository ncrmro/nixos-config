{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../common/global
    ../common/features/cli
    ../common/features/desktop
  ];

  wayland.windowManager.hyprland.settings = {
    # Environment variables
    # https://wiki.hyprland.org/Configuring/Variables/#input
    monitor = [
      "DP-7, 3840x2160@60.00Hz, 0x0, 1"
      "eDP-1, 2256x1504@60.00Hz, 3840x500, 1"
    ];
  };
}
