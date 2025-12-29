# Custom overlays for overriding packages
{ inputs, ... }:
[
  # Keystone overlay (provides pkgs.keystone)
  inputs.keystone.overlays.default

  # Use ghostty from the official flake (1.2.3+ with SIGUSR2 config reload support)
  (final: prev: {
    ghostty = inputs.ghostty.packages.${prev.system}.default;
  })

  # Use yazi from the official flake
  (final: prev: {
    yazi = inputs.yazi.packages.${prev.system}.default;
  })
]
