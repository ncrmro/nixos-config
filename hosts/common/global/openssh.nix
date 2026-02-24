{ lib, ... }:
let
  keys = import ../../../modules/users/keys.nix;
in
{
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = lib.mkDefault "no";
  };
  users.users."root".openssh.authorizedKeys.keys = keys.root;
}
