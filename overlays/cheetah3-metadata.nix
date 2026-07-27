# Cheetah3 3.4.0.post5 imports successfully, but the Python 3.14 metadata hook
# cannot resolve its distribution name after installation. Disable only that
# new false-positive phase; the package's Cheetah import check still runs.
final: prev: {
  pythonPackagesExtensions = (prev.pythonPackagesExtensions or [ ]) ++ [
    (pyfinal: pyprev: {
      cheetah3 = pyprev.cheetah3.overridePythonAttrs (_: {
        dontCheckPythonMetadata = true;
      });
    })
  ];
}
