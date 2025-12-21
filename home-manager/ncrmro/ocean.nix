{
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.keystone.homeModules.terminal
  ];

  home = {
    username = lib.mkDefault "ncrmro";
    homeDirectory = "/home/ncrmro";
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
