{ lib, ... }:
let
  keys = import ../../modules/users/keys.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    ./k3s.nix
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "catalyst-primary";
  networking.domain = "";
  networking.hosts = {
    "127.0.0.1" = [
      "primary.catalyst.ncrmro.com"
      "cr.primary.catalyst.ncrmro.com"
    ];
  };
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = keys.root;
  system.stateVersion = "25.05";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
