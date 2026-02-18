{ pkgs, ... }:

{
  imports = [
    ../common/agents/base.nix
    ../common/features/cli/himalaya.nix
  ];

  home.username = "drago";
  home.homeDirectory = "/home/drago";

  # Override git identity for drago
  programs.git.userName = "Drago";
  programs.git.userEmail = "drago@ncrmro.com";

  home.stateVersion = "24.05";
}
