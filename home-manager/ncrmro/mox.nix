{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  # You can import other home-manager modules here
  imports = [
    # inputs.nix-colors.homeManagerModule
    ../common/global
    ../common/features/desktop/common
    # ../common/global/impermanence.nix
    # ../common/features/cli/gh.nix
    # ../common/features/cli/ssh.nix
    # ../common/features/nvim
    # ../common/features/helix
    ../common/features/desktop/hyprland
  ];

  home = {
    username = lib.mkDefault "ncrmro";
  };

  wayland.windowManager.hyprland.settings.env = [
    # "WLR_DRM_DEVICES,/home/${config.home.username}/.config/hypr/card"
    # "AQ_DRM_DEVICES,/home/${config.home.username}/.config/hypr/card"
    # "AQ_DRM_DEVICES,/dev/dri/card1"
    "AQ_TRACE,1"
    "HYPLAND_TRACE,1"
    "XDG_SESSION_TYPE,wayland"
    "MOZ_ENABLE_WAYLAND,1"
  ];

  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.05"; # Please read the comment before changing.
}
