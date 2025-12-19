{
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.keystone.homeModules.keystoneTerminal
  ];

  # Enable terminal configuration (zsh, starship, zoxide, zellij)
  keystone.terminal.enable = true;

  home = {
    username = lib.mkDefault "ncrmro";
    homeDirectory = "/home/ncrmro";
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
