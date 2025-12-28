{
  inputs,
  config,
  pkgs,
  ...
}:
{
  home.packages = [
    # OpenSCAD from unstable channel for latest features
    (import inputs.nixpkgs-unstable {
      inherit (pkgs) system;
      config.allowUnfree = true;
    }).openscad-unstable

    # OpenSCAD Language Server Protocol
    (import inputs.nixpkgs-unstable {
      inherit (pkgs) system;
      config.allowUnfree = true;
    }).openscad-lsp
  ];
}
