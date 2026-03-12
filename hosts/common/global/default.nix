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
    inputs.keystone.nixosModules.mail
  ];

  keystone.domain = "ncrmro.com";
  keystone.mail.host = "ocean";

  # Apply custom overlays
  nixpkgs.overlays = import ../../../overlays { inherit inputs; };
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Attic binary cache on ocean (Tailscale-only)
  # URL auto-derived from keystone.domain → https://cache.ncrmro.com
  keystone.binaryCache = {
    enable = true;
    # TODO: standardize keystone repo location (e.g. ~/.keystone) so
    # atticd-init can auto-update this value instead of manual copy-paste
    publicKey = "main:H852yjGdbbRIOQcnKm3uZOpZWRFmQoQ5p4I7VDz7kAI=";
  };
  time.timeZone = "America/Chicago";

  environment.systemPackages = with pkgs; [
    home-manager
    lm_sensors
  ];
}
