{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.keystone.desktop;
  themeCfg = config.keystone.desktop.theme;

  # Map keystone theme names to Ghostty built-in theme names
  ghosttyThemeMap = {
    "tokyo-night" = "tokyonight";
    "kanagawa" = "Kanagawa Wave";
    "catppuccin" = "catppuccin-mocha";
    "catppuccin-latte" = "catppuccin-latte";
    "everforest" = "Everforest Dark - Hard";
    "gruvbox" = "GruvboxDark";
    "nord" = "nord";
    "rose-pine" = "rose-pine";
    "flexoki-light" = "flexoki-light";
    "ristretto" = "Monokai Pro Ristretto";
    # These use custom colors in omarchy, fallback to a similar theme
    "ethereal" = null; # custom colors
    "hackerman" = null; # custom colors
    "matte-black" = null; # custom colors
    "osaka-jade" = null; # custom colors
  };

  # Get the Ghostty theme name, or null if using custom colors
  ghosttyTheme = ghosttyThemeMap.${themeCfg.name} or null;
in {
  config = mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      settings =
        {
          # Window settings
          window-padding-x = 14;
          window-padding-y = 14;
          background-opacity = 0.95;
          window-decoration = "none";
          confirm-close-surface = false;
          resize-overlay = "never";

          # Font settings
          font-family = "JetBrainsMono Nerd Font";
          font-style = "Regular";
          font-size = 12;

          # Cursor settings
          cursor-style = "block";
          cursor-style-blink = false;

          # Mouse settings
          mouse-scroll-multiplier = 0.95;

          # Keybindings
          keybind = [
            # Clipboard
            "shift+insert=paste_from_clipboard"
            "control+insert=copy_to_clipboard"
            # Tab navigation
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
        }
        # Use built-in theme if available, otherwise load custom colors from omarchy
        // (
          if ghosttyTheme != null
          then {theme = ghosttyTheme;}
          else {config-file = "${config.xdg.configHome}/keystone/current/theme/ghostty.conf";}
        );
    };
  };
}
