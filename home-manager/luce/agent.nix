{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ../common/agents/base.nix
    inputs.keystone.homeModules.terminal
  ];

  home.username = "luce";
  home.homeDirectory = "/home/luce";

  # Enable keystone terminal with agent identity
  keystone.terminal = {
    enable = true;
    git = {
      userName = "Luce";
      userEmail = "luce@ncrmro.com";
    };
  };

  home.stateVersion = "24.05";
}
