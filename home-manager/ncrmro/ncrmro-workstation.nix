{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./base.nix
    ../common/features/desktop/obs.nix
  ];

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "desc:LG Electronics LG Ultra HD 0x00044217, 3840x2160@60.00Hz, 0x0, 1"
      "desc:LG Electronics LG Ultra HD 0x000063ED, 3840x2160@60.00Hz, auto-center-left, 1, transform, 1"
    ];
    workspace = [
      "1, monitor:desc:LG Electronics LG Ultra HD 0x000063ED, persistent:true"
      "2, monitor:desc:LG Electronics LG Ultra HD 0x00044217, persistent:true"
      "3, monitor:desc:LG Electronics LG Ultra HD 0x00044217, persistent:true"
      "4, monitor:desc:LG Electronics LG Ultra HD 0x00044217, persistent:true"
      "5, monitor:desc:LG Electronics LG Ultra HD 0x00044217, persistent:true"
      "6, monitor:desc:LG Electronics LG Ultra HD 0x00044217, persistent:true"
      "7, monitor:desc:LG Electronics LG Ultra HD 0x00044217, persistent:true"
      "8, monitor:desc:LG Electronics LG Ultra HD 0x00044217, persistent:true"
      "9, monitor:desc:LG Electronics LG Ultra HD 0x00044217, persistent:true"
    ];
  };

  programs.zsh = {
    shellAliases = {
      update = "sudo nixos-rebuild switch --flake ~/nixos-config#ncrmro-workstation";
    };
  };
}
