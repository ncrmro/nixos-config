{
  config,
  lib,
  pkgs,
  ...
}: {
  services.ollama = {
    enable = true;
    acceleration = "rocm";
  };
}
