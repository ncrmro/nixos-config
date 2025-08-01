{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../common/global
    ../common/features/cli
    ../common/features/desktop
    inputs.nix-index-database.homeModules.nix-index
  ];

  wayland.windowManager.hyprland.settings = {
    # Environment variables
    # https://wiki.hyprland.org/Configuring/Variables/#input
    monitor = [
      "desc:LG Electronics LG Ultra HD 0x00044217, 3840x2160@60.00Hz, 0x0, 1"
      "desc:BOE 0x0BCA, 2256x1504@60.00Hz, 3840x500, 1"
    ];
    workspace = [
      "1, monitor:desc:LG Electronics LG Ultra HD 0x00044217, persistent:true"
      "2, monitor:desc:LG Electronics LG Ultra HD 0x00044217, persistent:true"
      "3, monitor:desc:LG Electronics LG Ultra HD 0x00044217, persistent:true"
      "4, monitor:desc:LG Electronics LG Ultra HD 0x00044217, persistent:true"
      "5, monitor:desc:LG Electronics LG Ultra HD 0x00044217, persistent:true"
      "6, monitor:desc:BOE 0x0BCA, persistent:true, default:true"
    ];
  };
  home.packages = with pkgs; [
    google-chrome
  ];
  programs.git.extraConfig = {
      credential.helper = "store";
      push.autoSetupRemote = true;
      gpg.format = "ssh";
      commit.gpgsign = true;
      user.signingkey = "~/.ssh/id_ed25519";
      includeIf."gitdir:~/code/unsupervised/" = {
        path = "~/code/unsupervised/.gitconfig";
      };
  };
}
