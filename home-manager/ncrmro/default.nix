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

  #   programs.git = {
  #     enable = true;
  #     # userName = "Henry Sipp";
  #     # userEmail = "henry.sipp@hey.com";
  #     extraConfig = {
  #       credential.helper = "store";
  #     };
  #   };

  #   programs.gh = {
  #     enable = true;
  #     gitCredentialHelper = {
  #       enable = true;
  #     };
  #   };
}
