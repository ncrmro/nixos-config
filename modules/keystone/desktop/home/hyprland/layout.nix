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
      general = {
        layout = mkDefault "dwindle";
      };

      dwindle = mkDefault {
        pseudotile = true;
        preserve_split = true;
        force_split = 2;
      };

      master = mkDefault {
        new_status = "master";
      };

      windowrule = mkDefault [
        # Suppress maximize events
        "suppressevent maximize, class:.*"

        # Force chromium into a tile to deal with --app bug
        "tile, class:^(chromium)$"

        # Settings management
        "float, class:^(org.pulseaudio.pavucontrol|blueberry.py)$"

        # Float Steam, fullscreen RetroArch
        "float, class:^(steam)$"
        "fullscreen, class:^(com.libretro.RetroArch)$"

        # Slight transparency
        "opacity 0.97 0.9, class:.*"
        # Full opacity for video content
        "opacity 1 1, class:^(chromium|google-chrome|google-chrome-unstable)$, title:.*Youtube.*"
        "opacity 1 0.97, class:^(chromium|google-chrome|google-chrome-unstable)$"
        "opacity 0.97 0.9, initialClass:^(chrome-.*-Default)$"
        "opacity 1 1, initialClass:^(chrome-youtube.*-Default)$"
        "opacity 1 1, class:^(zoom|vlc|org.kde.kdenlive|com.obsproject.Studio)$"
        "opacity 1 1, class:^(com.libretro.RetroArch|steam)$"

        # Fix some dragging issues with XWayland
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"

        # Float in the middle for clipse clipboard manager
        "float, class:(clipse)"
        "size 622 652, class:(clipse)"
        "stayfocused, class:(clipse)"
      ];

      layerrule = mkDefault [
        "blur,wofi"
        "blur,waybar"
      ];
    };
  };
}
