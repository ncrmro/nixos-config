{
  pkgs,
  lib,
  inputs,
  outputs,
  ...
}:
{
  imports = [
    ./openssh.nix
    inputs.keystone.nixosModules.binaryCacheClient
    inputs.keystone.nixosModules.domain
  ];

  keystone.domain = "ncrmro.com";

  # Apply custom overlays
  nixpkgs.overlays = import ../../../overlays { inherit inputs; };
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Attic binary cache on ocean (Tailscale-only)
  keystone.binaryCache = {
    enable = true;
    url = "https://cache.ncrmro.com";
    # TODO: set after creating the cache with atticd-atticadm
    publicKey = null;
  };
  time.timeZone = "America/Chicago";

  environment.systemPackages = with pkgs; [
    home-manager
    lm_sensors
  ];
}
