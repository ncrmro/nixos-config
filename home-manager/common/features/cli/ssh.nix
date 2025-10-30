{
  lib,
  pkgs,
  ...
}: {
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "unsup-laptop.local" = {
        setEnv = {
          TERM = "xterm-256color";
        };
      };
    };
  };
}
