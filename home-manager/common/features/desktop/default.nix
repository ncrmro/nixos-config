{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
{
  # Add Flatpak exports to XDG_DATA_DIRS for application launcher
  home.sessionVariables = {
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:/var/lib/flatpak/exports/share";
  };

  # Hypridle configuration - ignore D-Bus inhibit locks from Chrome/Claude
  services.hypridle.settings.general.ignore_dbus_inhibit = true;

  # xdg-desktop-portal-hyprland config - auto-allow restore tokens for screen sharing
  xdg.configFile."hypr/xdph.conf".text = ''
    screencopy {
      allow_token_by_default = true
    }
  '';

  programs.chromium.enable = true;
  programs.chromium.extensions = [
    { id = "nngceckbapebfimnlniiiahkandclblb"; } # bitwarden
    { id = "nkbihfbeogaeaoehlefnkodbefgpgknn"; } # metamask
    { id = "einnioafmpimabjcddiinlhmijaionap"; } # wander wallet
  ];
  programs.vscode = {
    enable = true;
    package =
      (import inputs.nixpkgs-unstable {
        inherit (pkgs) system;
        config.allowUnfree = true;
      }).vscode;
  };
  wayland.windowManager.hyprland.settings = {
    # Environment variables
    # https://wiki.hyprland.org/Configuring/Variables/#input
    input = {
      # maps caps lock to ctrl
      kb_options = "compose:caps,ctrl:nocaps,altwin:swap_alt_win";
      # sensitivity for mouse/trackpack (default: 0)
      sensitivity = 0.35;
    };
  };
  home.packages = with pkgs; [
    bitwarden-desktop
    code-cursor
    zoom-us
    postman
    telegram-desktop
    discord-ptb
    papers
    (import inputs.nixpkgs-unstable {
      inherit (pkgs) system;
      config.allowUnfree = true;
    }).uhk-agent
  ];
}
