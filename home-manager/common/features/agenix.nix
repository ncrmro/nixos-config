{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.agenix.homeManagerModules.default
  ];

  # Install agenix CLI for home-manager user
  home.packages = [
    inputs.agenix.packages.x86_64-linux.default
  ];
}
