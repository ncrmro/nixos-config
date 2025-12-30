{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.github-mcp-server
  ];
}
