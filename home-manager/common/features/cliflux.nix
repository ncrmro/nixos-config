{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.cliflux ];

  # Symlink agenix-managed config (contains API key) at activation time
  # Can't use xdg.configFile.source with /run paths in pure evaluation mode
  home.activation.linkClifluxConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/cliflux"
    ln -sf /run/agenix/cliflux-config "$HOME/.config/cliflux/config.toml"
  '';
}
