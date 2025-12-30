{
  inputs,
  config,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    openscad-unstable
    openscad-lsp
  ];
}
