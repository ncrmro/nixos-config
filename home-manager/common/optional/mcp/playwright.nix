{ config, lib, pkgs, ... }:

{
  home.packages = [
    pkgs.playwright-mcp
  ];
}