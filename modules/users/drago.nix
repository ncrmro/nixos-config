{ config, pkgs, ... }:
let
  keys = import ./keys.nix;
in
{
  programs.zsh.enable = true;

  users.users.drago = {
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
