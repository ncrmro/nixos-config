{ config, pkgs, ... }:
let
  keys = import ./keys.nix;
in
{
  programs.zsh.enable = true;

  users.users.luce = {
    isNormalUser = true;
    description = "Autonomous Agent";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    initialPassword = "password"; # For testing, change later
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = keys.ncrmro;
  };
}
