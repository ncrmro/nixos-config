{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    inputs.omarchy-nix.homeManagerModules.default
  ];

  home.username = "ncrmro";
  home.homeDirectory = "/home/ncrmro";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  programs.ssh = {
    enable = true;
    # extraConfig = ''
    #   Host *
    #     IdentityAgent ~/.1password/agent.sock
    # '';
  };

  programs.git = {
    enable = true;
    userName = "Nicholas Romero";
    userEmail = "ncrmro@gmail.com";
    extraConfig = {
      credential.helper = "store";
      push.autoSetupRemote = true;
      gpg.format = "ssh";
      commit.gpgsign = true;
      user.signingkey = "~/.ssh/id_ed25519";
      lfs.enable = true;
      alias = {
        b = "branch";
        p = "pull";
        co = "checkout";
        c = "commit";
        ci = "commit -a";
        a = "add";
        st = "status -sb";
      };
    };
  };
}
