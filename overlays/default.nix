# Custom overlays for overriding packages
{inputs, ...}: [
  # Override claude-code with latest version
  (final: prev: {
    claude-code = prev.callPackage ../pkgs/claude-code {};
  })
]
