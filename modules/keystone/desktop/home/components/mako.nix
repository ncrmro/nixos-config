{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.keystone.desktop;
in {
  config = mkIf cfg.enable {
    # Mako configuration - use symlink to theme file
    # This allows dynamic theme switching without rebuilding
    xdg.configFile."mako/config".source = config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/keystone/current/theme/mako.ini";

    # Enable mako service
    services.mako.enable = mkDefault true;
  };
}
