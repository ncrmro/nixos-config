{
  lib,
  pkgs,
  ...
}:
{
  programs.ssh = {
    enable = true;
    # Disable deprecated default config
    enableDefaultConfig = false;
    matchBlocks = {
      "unsup-laptop.local" = {
        setEnv = {
          TERM = "xterm-256color";
        };
      };
      "unsup-air.local" = {
        setEnv = {
          TERM = "xterm-256color";
        };
      };
    };
  };
}
