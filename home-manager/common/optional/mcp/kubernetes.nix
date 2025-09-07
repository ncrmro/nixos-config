{ config, lib, pkgs, ... }:

{
  home.packages = [
    pkgs.mcp-k8s-go
  ];
}