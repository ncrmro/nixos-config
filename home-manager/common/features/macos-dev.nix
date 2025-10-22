{
  lib,
  pkgs,
  ...
}: {
  # Common macOS development toolkit
  # Shared by all macOS home-manager configurations
  imports = [
    ./cli
    ./cli/git.nix
    ./cli/ssh.nix
    ../optional/mcp/github-mcp.nix
    ../optional/mcp/kubernetes.nix
    ../optional/mcp/playwright.nix
  ];

  programs.home-manager.enable = true;
}
