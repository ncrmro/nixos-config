{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.bambu-studio;
in
{
  options.programs.bambu-studio = {
    enable = lib.mkEnableOption "Bambu Studio 3D printing software";
  };

  # nix-flatpak import and services.flatpak.enable come from keystone desktop module
  config = lib.mkIf cfg.enable {
    services.flatpak.packages = [
      "com.bambulab.BambuStudio"
    ];
    services.flatpak.overrides."com.bambulab.BambuStudio".Environment = {
      GDK_SCALE = "1";
    };
  };
}
