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
    programs.ghostty = {
      enable = true;
      settings.keybind = [
        "ctrl+shift+w=previous_tab"
        "ctrl+shift+e=new_tab"
        "ctrl+shift+r=next_tab"
        "ctrl+shift+c=close_surface"
        # Unbind Zellij tab shortcuts
        "ctrl+page_up=unbind"
        "ctrl+page_down=unbind"
        "ctrl+tab=unbind"
        # Unbind Ghostty splits - Zellij handles all pane management
        "ctrl+shift+o=unbind"
        "ctrl+alt+up=unbind"
        "ctrl+alt+down=unbind"
        "ctrl+alt+left=unbind"
        "ctrl+alt+right=unbind"
      ];
    };
  };
}
