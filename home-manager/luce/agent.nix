{ pkgs, ... }:

{
  imports = [ ../common/agents/base.nix ];

  home.username = "luce";
  home.homeDirectory = "/home/luce";

  # Override git identity for luce
  programs.git.userName = "Luce";
  programs.git.userEmail = "luce@ncrmro.com";

  home.stateVersion = "24.05";
}
