# The "dotfiles" home-manager module.
#
# Division of labour (see ~/repos/ncrmro/dotfiles/README.md):
#   - Nix provisions DEPENDENCIES (packages, LSP servers, grammars, tools) onto PATH.
#   - The ncrmro/dotfiles repo owns editable CONFIG as plain files, referencing
#     binaries by bare name and symlinked into $HOME with GNU stow.
#
# This module (1) installs the per-tool dependency manifest for the enabled
# packages and (2) restows those packages from the dotfiles repo on activation.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dotfiles;

  # Per-tool dependency manifest. Adding a tool here is the convention for
  # "managing dependencies like helix extensions via nix": list what the plain
  # config expects to find on PATH. Keep in sync with the stow package's config.
  toolDeps = {
    git = with pkgs; [
      git
      git-lfs
    ];
    ssh = [ ];
    # Helix language servers (mirrors keystone modules/terminal/editor.nix).
    # The plain languages.toml references these by bare name.
    helix = with pkgs; [
      helix
      marksman
      harper
      bash-language-server
      yaml-language-server
      dockerfile-language-server
      docker-compose-language-service
      vscode-langservers-extracted
      helm-ls
      typescript-language-server
      prettier
      nixfmt-rfc-style
    ];
    zellij = with pkgs; [ zellij ];
    # Hyprland ecosystem tools the plain config / keybinds call by bare name.
    hyprland = with pkgs; [
      waybar
      mako
      wl-clipboard
      grim
      slurp
      brightnessctl
      playerctl
    ];
  };

  unknown = lib.subtractLists (lib.attrNames toolDeps) cfg.packages;
in
{
  options.dotfiles = {
    enable = lib.mkEnableOption "stow-managed plain-text dotfiles (nix provisions deps only)";

    repoPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/repos/ncrmro/dotfiles";
      description = "Path to the working checkout of the ncrmro/dotfiles repo.";
    };

    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Stow packages (tool names) to link and provision deps for. Modules may
        append to this list (e.g. the desktop feature adds "hyprland").
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = unknown == [ ];
        message = "dotfiles.packages has entries with no toolDeps manifest: ${toString unknown}";
      }
    ];

    home.packages = lib.concatMap (p: toolDeps.${p} or [ ]) cfg.packages;

    # Restow on every activation. Guarded so a missing checkout warns instead of
    # failing the whole rebuild (the repo is a manual clone, like agenix-secrets).
    home.activation.stowDotfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -d "${cfg.repoPath}/packages" ]; then
        run ${pkgs.stow}/bin/stow \
          --dir "${cfg.repoPath}/packages" \
          --target "${config.home.homeDirectory}" \
          --no-folding \
          --restow ${lib.escapeShellArgs cfg.packages}
      else
        warnEcho "dotfiles: ${cfg.repoPath}/packages not found — skipping stow. Clone ncrmro/dotfiles there."
      fi
    '';
  };
}
