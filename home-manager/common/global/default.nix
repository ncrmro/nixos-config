{
  inputs,
  lib,
  pkgs,
  config,
  outputs,
  ...
}: {
  imports = [
    ../features/cli
  ];
  # ++ (builtins.attrValues outputs.homeManagerModules);

  home = {
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = "24.05";
    sessionPath = ["$HOME/.local/bin"];
  };
  programs = {
    home-manager.enable = true;
    git.enable = true;
  };
}
