{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {

  programs.chromium.enable = true;
  programs.chromium.extensions = [
    { id = "nngceckbapebfimnlniiiahkandclblb"; } # bitwarden
    { id = "nkbihfbeogaeaoehlefnkodbefgpgknn"; } # metamask
    { id = "einnioafmpimabjcddiinlhmijaionap"; } # wander wallet 
  ];
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
  ];
}
