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
      "desc:LG Electronics LG Ultra HD 0x00044217, 3840x2160@60.00Hz, 0x0, 1"
      "desc:BOE 0x0BCA, 2256x1504@60.00Hz, 3840x500, 1"
    ];
    workspace = "1,monitor:desc:LG Electronics LG Ultra HD 0x00044217,default=true";
  };
}
