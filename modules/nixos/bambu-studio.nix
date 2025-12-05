{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.programs.bambu-studio;
in {
  imports = [inputs.nix-flatpak.nixosModules.nix-flatpak];

  options.programs.bambu-studio = {
    enable = lib.mkEnableOption "Bambu Studio 3D printing software";
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;
    services.flatpak.packages = [
      "com.bambulab.BambuStudio"
    ];
  };
}
