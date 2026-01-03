{
  lib,
  inputs,
  ...
}:
{
  imports = [
    ../common/global
    inputs.keystone.homeModules.terminal
  ];

  home = {
    username = lib.mkDefault "ncrmro";
    homeDirectory = "/home/ncrmro";
    stateVersion = "25.05";
    packages = [
    ];
  };

  keystone.terminal = {
    enable = true;
    git = {
      userName = "Nicholas Romero";
      userEmail = "ncrmro@gmail.com";
    };
  };

  programs.home-manager.enable = true;

  programs.zsh = {
    shellAliases = {
      update = "sudo nixos-rebuild switch --flake ~/nixos-config#ocean";
    };
  };
}
