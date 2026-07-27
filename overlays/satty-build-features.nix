# The pinned satty 0.20.0 source no longer declares the `ci-release` Cargo
# feature still requested by this nixpkgs revision. Build the same source with
# its default features instead.
final: prev: {
  satty = prev.satty.overrideAttrs (_: {
    buildFeatures = [ ];
    cargoBuildFeatures = [ ];
    cargoCheckFeatures = [ ];
  });
}
