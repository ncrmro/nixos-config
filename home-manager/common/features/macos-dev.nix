{
  lib,
  pkgs,
  self,
  ...
}: {
  # Common macOS development toolkit
  # Shared by all macOS home-manager configurations
  imports = [
    self.homeManagerModules.keystone-terminal
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
      experimental-features = ["nix-command" "flakes"];
    };
  };
}
