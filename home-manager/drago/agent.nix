{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ../common/agents/base.nix
    ../common/features/cli/himalaya.nix
    inputs.keystone.homeModules.terminal
  ];

  home.username = "drago";
  home.homeDirectory = "/home/drago";

  # Enable keystone terminal with agent identity
  keystone.terminal = {
    enable = true;
    git = {
      userName = "Drago";
      userEmail = "drago@ncrmro.com";
    };
  };

  home.stateVersion = "24.05";
}
