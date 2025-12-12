{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.keystone.desktop;
  themeCfg = config.keystone.desktop.theme;

  # List of theme files to copy from omarchy (excluding ghostty.conf - we generate our own)
  themeFilesToCopy = [
    "hyprland.conf"
    "hyprlock.conf"
    "waybar.css"
    "mako.ini"
    "wofi.css"
    "btop.theme"
    "swayosd.css"
    "walker.css"
    "chromium.theme"
    "icons.theme"
    "preview.png"
  ];

  # Map keystone theme names to correct ghostty theme names
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
    "ethereal" = "Builtin Dark";
    "hackerman" = "Builtin Dark";
    "matte-black" = "Builtin Dark";
    "osaka-jade" = "Builtin Dark";
  };

  # Get list of themes from omarchy
  omarchyThemesPath = "${inputs.omarchy}/themes";

  # Theme directories available in omarchy
  availableThemes = [
    "tokyo-night"
    "kanagawa"
    "catppuccin"
    "catppuccin-latte"
    "ethereal"
    "everforest"
    "flexoki-light"
    "gruvbox"
    "hackerman"
    "matte-black"
    "nord"
    "osaka-jade"
    "ristretto"
    "rose-pine"
  ];

  # Function to create theme files for a single theme
  mkThemeFiles =
    themeName:
    let
      sourceThemePath = "${omarchyThemesPath}/${themeName}";
      destThemePath = "${config.xdg.configHome}/keystone/themes/${themeName}";
      ghosttyTheme = ghosttyThemeMap.${themeName} or "Builtin Dark";
    in
    # Copy individual theme files
    listToAttrs (
      map (
        fileName:
        nameValuePair "${destThemePath}/${fileName}" { source = "${sourceThemePath}/${fileName}"; }
      ) (filter (fileName: pathExists "${sourceThemePath}/${fileName}") themeFilesToCopy)
    )
    # Generate ghostty.conf with correct theme name
    // {
      "${destThemePath}/ghostty.conf".text = "theme = ${ghosttyTheme}\n";
    }
    # Copy backgrounds directory if it exists
    // (
      if pathExists "${sourceThemePath}/backgrounds" then
        {
          "${destThemePath}/backgrounds".source = "${sourceThemePath}/backgrounds";
        }
      else
        { }
    );

  # Theme switch script
  keystoneThemeSwitch = pkgs.writeShellScriptBin "keystone-theme-switch" ''
    THEMES_DIR="${config.xdg.configHome}/keystone/themes"
    CURRENT_LINK="${config.xdg.configHome}/keystone/current"

    if [[ $# -eq 0 ]]; then
      echo "Available themes:"
      for theme in "$THEMES_DIR"/*/; do
        theme_name=$(basename "$theme")
        if [[ -L "$CURRENT_LINK/theme" ]] && [[ "$(readlink -f "$CURRENT_LINK/theme")" == "$(readlink -f "$theme")" ]]; then
          echo "  * $theme_name (active)"
        else
          echo "    $theme_name"
        fi
      done
      echo ""
      echo "Usage: keystone-theme-switch <theme-name>"
      exit 0
    fi

    THEME_NAME="$1"
    THEME_PATH="$THEMES_DIR/$THEME_NAME"

    if [[ ! -d "$THEME_PATH" ]]; then
      echo "Error: Theme '$THEME_NAME' not found in $THEMES_DIR"
      exit 1
    fi

    # Create current directory if it doesn't exist
    mkdir -p "$CURRENT_LINK"

    # Update theme symlink
    ln -sfn "$THEME_PATH" "$CURRENT_LINK/theme"

    # Set background if available
    if [[ -d "$THEME_PATH/backgrounds" ]]; then
      # Use first background if not specifically set
      FIRST_BG=$(ls "$THEME_PATH/backgrounds/" | head -1)
      if [[ -n "$FIRST_BG" ]]; then
        ln -sfn "$THEME_PATH/backgrounds/$FIRST_BG" "$CURRENT_LINK/background"
      fi
    fi

    echo "Switched to theme: $THEME_NAME"

    # Restart hyprpaper to pick up new background
    ${pkgs.systemd}/bin/systemctl --user restart hyprpaper.service 2>/dev/null || true

    # Reload components
    ${pkgs.systemd}/bin/systemctl --user restart waybar.service 2>/dev/null || true
    ${pkgs.procps}/bin/pkill -SIGUSR2 ghostty 2>/dev/null || true
    ${pkgs.systemd}/bin/systemctl --user restart mako.service 2>/dev/null || true
    ${pkgs.systemd}/bin/systemctl --user restart walker.service 2>/dev/null || true
    ${pkgs.libnotify}/bin/notify-send "Theme Changed" "Switched to $THEME_NAME theme" -t 3000
  '';
in
{
  options.keystone.desktop.theme = {
    name = mkOption {
      type = types.str;
      default = "tokyo-night";
      description = "Active theme name";
    };
  };

  config = mkIf cfg.enable {
    # Deploy all theme files from omarchy
    # Also deploy omarchy default mako core.ini since theme mako.ini files include it
    home.file = mkMerge (map mkThemeFiles availableThemes) // {
      ".local/share/omarchy/default/mako/core.ini".source = "${inputs.omarchy}/default/mako/core.ini";
    };

    # Theme switching script
    home.packages = [
      keystoneThemeSwitch
    ];

    # Create activation script to setup symlinks
    home.activation.keystoneThemeSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      KEYSTONE_DIR="${config.xdg.configHome}/keystone"
      CURRENT_DIR="$KEYSTONE_DIR/current"
      THEME_DIR="$KEYSTONE_DIR/themes/${themeCfg.name}"

      # Create directories
      mkdir -p "$CURRENT_DIR"

      # Create theme symlink if not exists or pointing to wrong theme
      if [[ ! -L "$CURRENT_DIR/theme" ]] || [[ "$(readlink "$CURRENT_DIR/theme")" != "$THEME_DIR" ]]; then
        ln -sfn "$THEME_DIR" "$CURRENT_DIR/theme"
        echo "Keystone: Set theme to ${themeCfg.name}"
      fi

      # Create default background symlink if not exists and theme has backgrounds
      if [[ ! -L "$CURRENT_DIR/background" ]] && [[ -d "$THEME_DIR/backgrounds" ]]; then
        FIRST_BG=$(ls "$THEME_DIR/backgrounds/" 2>/dev/null | head -1)
        if [[ -n "$FIRST_BG" ]]; then
          ln -sfn "$THEME_DIR/backgrounds/$FIRST_BG" "$CURRENT_DIR/background"
          echo "Keystone: Set default background from ${themeCfg.name} theme"
        fi
      fi
    '';
  };
}
