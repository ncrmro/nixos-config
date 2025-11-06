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
  nix.settings.experimental-features = ["nix-command" "flakes"];
  time.timeZone = "America/Chicago";

  environment.systemPackages = with pkgs; [
    home-manager
    lm_sensors
  ];
}
