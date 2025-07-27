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

  #   programs.gh = {
  #     enable = true;
  #     gitCredentialHelper = {
  #       enable = true;
  #     };
  #   };
  wayland.windowManager.hyprland.settings = {
    # Environment variables
    # https://wiki.hyprland.org/Configuring/Variables/#input
    input = {
      kb_options = "compose:caps,ctrl:nocaps";
    };
  };
  home.packages = with pkgs; [
    bitwarden-desktop
  ];

}
