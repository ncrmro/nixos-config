{
  pkgs,
  lib,
  inputs,
  outputs,
  ...
}: {
  imports = [
    ./openssh.nix
  ];

  # Apply custom overlays
  nixpkgs.overlays = import ../../../overlays {inherit inputs;};
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = ["nix-command" "flakes"];
  time.timeZone = "America/Chicago";

  environment.systemPackages = with pkgs; [
    home-manager
    lm_sensors
  ];
}
