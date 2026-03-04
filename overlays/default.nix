# Custom overlays for overriding packages
{ inputs, ... }:
[
  # Keystone overlay (provides pkgs.keystone with ghostty, yazi, claude-code, etc.)
  inputs.keystone.overlays.default

  # Local packages
  (final: prev: import ../packages/default.nix { pkgs = final; })
]
