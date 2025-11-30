{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.keystone.desktop;
in {
  imports = [
    ./hyprland.nix
  ];

  options.keystone.desktop = {
    enable = mkEnableOption "Keystone Desktop - Core desktop packages and utilities for Home Manager";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Core utilities
    ];
  };
}
