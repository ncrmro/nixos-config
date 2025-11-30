{
  config,
  lib,
  ...
}:
with lib; {
  imports = [
    ./shell.nix
    ./editor.nix
    ./ai.nix
  ];

  options.keystone.terminal = {
    enable = mkEnableOption "Keystone Terminal - Core terminal tools and configuration";
  };
}
