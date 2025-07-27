{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {

  programs.chromium.extensions = [
    { id = "nngceckbapebfimnlniiiahkandclblb"; } # bitwarden
    { id = "nkbihfbeogaeaoehlefnkodbefgpgknn"; } # metamask
    { id = "einnioafmpimabjcddiinlhmijaionap"; } # wander wallet 
  ];
  wayland.windowManager.hyprland.settings = {
    # Environment variables
    # https://wiki.hyprland.org/Configuring/Variables/#input
    input = {
      kb_options = "compose:caps,ctrl:nocaps";
    };
  };
  home.packages = with pkgs; [
    bitwarden-desktop
    code-cursor
  ];

}
