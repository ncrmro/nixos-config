{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan; # Vulkan variant for AMD GPU
  };
}
