# Custom overlays for overriding packages
{ inputs, ... }:
[
  # Keystone overlay (provides pkgs.keystone with ghostty, yazi, claude-code, etc.)
  inputs.keystone.overlays.default

  # Local packages
  (final: prev: import ../packages/default.nix { pkgs = final; })

  # Pinned nixpkgs bug: Cheetah3 publishes metadata under the `ct3` name.
  (import ./cheetah3-metadata.nix)

  # keystone-bound overlay holding area (see modules/keystone/AGENTS.md):
  # skip weasyprint's macOS-flaky pixel tests so it builds on aarch64-darwin.
  (import ./keystone/weasyprint-darwin-tests.nix)

  # TODO(upstream-keystone): ks TCP reachability probe (milestone 8830b560).
  (import ./keystone/ks-tcp-probe.nix)
]
