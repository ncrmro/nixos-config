# Custom overlays for overriding packages
{ inputs, ... }:
[
  # Keystone overlay (provides pkgs.keystone)
  (final: prev: {
    keystone = {
      zesh = final.callPackage (inputs.keystone + "/packages/zesh") { };
      himalaya = inputs.keystone.inputs.himalaya.packages.${final.stdenv.hostPlatform.system}.default;
      google-chrome =
        inputs.keystone.inputs.browser-previews.packages.${final.stdenv.hostPlatform.system}.google-chrome;
      # Coding agents from keystone's llm-agents input
      claude-code =
        inputs.keystone.inputs.llm-agents.packages.${final.stdenv.hostPlatform.system}.claude-code;
      gemini-cli =
        inputs.keystone.inputs.llm-agents.packages.${final.stdenv.hostPlatform.system}.gemini-cli;
    };
  })

  # Use ghostty from the official flake (1.2.3+ with SIGUSR2 config reload support)
  (final: prev: {
    ghostty = inputs.ghostty.packages.${prev.stdenv.hostPlatform.system}.default;
  })

  # Use yazi from the official flake
  (final: prev: {
    yazi = inputs.yazi.packages.${prev.stdenv.hostPlatform.system}.default;
  })

  # Local packages
  (final: prev: import ../packages/default.nix { pkgs = final; })
]
