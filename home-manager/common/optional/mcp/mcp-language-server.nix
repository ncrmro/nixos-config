{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  mcp-language-server = pkgs.callPackage ../../../../packages/mcp-language-server { };
in
{
  home.packages = [
    mcp-language-server
    pkgs.nodePackages.typescript-language-server
  ];
}
