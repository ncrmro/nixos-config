{pkgs}: {
  mcp-language-server = pkgs.callPackage ./mcp-language-server {};
  zesh = pkgs.callPackage ./zesh {};
}
