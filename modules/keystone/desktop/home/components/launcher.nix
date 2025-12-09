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
    # Wofi as the application launcher
    programs.wofi = {
      enable = mkDefault true;
      settings = {
        show = "drun";
        width = 600;
        height = 400;
        term = "ghostty";
        prompt = "Search...";
        allow_images = true;
        image_size = 24;
        insensitive = true;
      };
      style = ''
        @import "${config.xdg.configHome}/keystone/current/theme/wofi.css";
      '';
    };

    # Walker package available but not as a home-manager program module
    home.packages = with pkgs; [
      walker
    ];

    # Walker configuration file
    xdg.configFile."walker/config.toml".text = mkDefault ''
      force_keyboard_focus = true
      selection_wrap = true
      theme = "keystone"
      additional_theme_location = "${config.xdg.configHome}/keystone/current/theme/walker/"
      hide_action_hints = true

      [placeholders]
      "default" = { input = " Search...", list = "No Results" }

      [keybinds]
      quick_activate = []

      [providers]
      max_results = 256
      default = [
        "desktopapplications",
        "websearch",
      ]

      [[providers.prefixes]]
      prefix = "/"
      provider = "providerlist"

      [[providers.prefixes]]
      prefix = "."
      provider = "files"

      [[providers.prefixes]]
      prefix = ":"
      provider = "symbols"

      [[providers.prefixes]]
      prefix = "="
      provider = "calc"

      [[providers.prefixes]]
      prefix = "@"
      provider = "websearch"

      [[providers.prefixes]]
      prefix = "$"
      provider = "clipboard"
    '';
  };
}
