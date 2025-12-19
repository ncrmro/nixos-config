{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  # Common macOS development toolkit
  # Shared by all macOS home-manager configurations
  imports = [
    inputs.keystone.homeModules.keystoneTerminal
    ./cli
    ./cli/git.nix
    ./cli/ssh.nix
    ../optional/mcp/github-mcp.nix
    ../optional/mcp/kubernetes.nix
    ../optional/mcp/playwright.nix
  ];

  # Enable terminal configuration (zsh, starship, zoxide, zellij)
  keystone.terminal.enable = true;

  programs.home-manager.enable = true;

  # Enable experimental Nix features on macOS
  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
