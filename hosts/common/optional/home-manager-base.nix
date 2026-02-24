{
  inputs,
  outputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.default
    ../../../modules/users/ncrmro.nix
    ../../../modules/users/root.nix
  ];

  programs.zsh.enable = true;
  users.users.ncrmro.shell = pkgs.zsh;
  users.mutableUsers = true;

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.extraSpecialArgs = { inherit inputs outputs; };
}
