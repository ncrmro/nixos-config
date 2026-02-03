{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "64000";
    };
  };
}
