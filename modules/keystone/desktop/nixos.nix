{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.keystone.desktop;
in {
  options.keystone.desktop = {
    enable = mkEnableOption "Keystone Desktop - Core desktop packages and utilities";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gpu-screen-recorder
    ];
  };
}
