{
  pkgs,
  config,
  lib,
  ...
}: let
  # Pin to specific nixpkgs revision for playwright
  playwrightPkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/979daf34c8cacebcd917d540070b52a3c2b9b16e.tar.gz";
    sha256 = "0b0j3m8i2amwzi374am7s3kkhf3dxrvqwgr1lk8csr1v7fw9z85q";
  }) {inherit (pkgs) system;};
in {
  home.packages = with playwrightPkgs; [
    playwright-driver.browsers
  ];

  home.sessionVariables = {
    PLAYWRIGHT_BROWSERS_PATH = "${playwrightPkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
  };
}
