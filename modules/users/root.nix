{ pkgs, ... }:
let
  keys = import ./keys.nix;
in
{
  users.users."root".openssh.authorizedKeys.keys = keys.root;
}
