{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./base.nix
  ];

  wayland.windowManager.hyprland.settings = {
    monitor = [
      "desc:BOE 0x0BCA, 2256x1504@60.00Hz, auto, 1"
    ];
  };

  programs.zsh = {
    shellAliases = {
      update = "sudo nixos-rebuild switch --flake ~/nixos-config#ncrmro-laptop";
    };
  };
}
