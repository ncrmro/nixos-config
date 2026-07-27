# Cheetah3 installs distribution metadata as `ct3`, while the nixpkgs
# derivation pname is `cheetah3`. Python 3.14's metadata check therefore asks
# for a distribution name that does not exist even though the Cheetah import
# check passes. Keep the import/runtime checks and skip only that name check.
final: prev: {
  pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
    (pyfinal: pyprev: {
      cheetah3 = pyprev.cheetah3.overridePythonAttrs (_: {
        dontCheckPythonMetadata = true;
      });
    })
  ];
}
