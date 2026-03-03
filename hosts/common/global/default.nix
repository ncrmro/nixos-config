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

  # Harmonia binary cache on ocean (Tailscale-only)
  keystone.binaryCache = {
    enable = true;
    url = "https://harmonia.ncrmro.com";
    publicKey = "harmonia.ncrmro.com-1:+ch6VQl2xutZ4M6U1uRQdCFb110MloNgRhH0/Dg+ut0=";
  };
  time.timeZone = "America/Chicago";

  environment.systemPackages = with pkgs; [
    home-manager
    lm_sensors
  ];
}
