{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.keystone.desktop.hyprland;
in {
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      exec-once = mkDefault [
        "hyprlock"
        "uwsm app -- hyprsunset"
        "systemctl --user start hyprpolkitagent"
        "wl-clip-persist --clipboard regular & uwsm app -- clipse -listen"
      ];

      exec = mkDefault [
        "pkill -SIGUSR2 waybar || uwsm app -- waybar"
      ];
    };
  };
}
