# ncrmro personal HM settings: mail, calendar, contacts, timer, yubikey, git,
# hyprland rules, and packages. Structural imports (terminal, desktop, cli, etc.)
# are provided by modules/keystone/desktop.nix via the NixOS module system.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    nixfmt
    keystone.google-chrome
    zig
    gh
    gh-dash
    nodejs
    # devcontainer # broken in nixpkgs unstable (node-gyp offline build)
    obsidian
    signal-desktop
  ];

  keystone.terminal.ageYubikey = {
    enable = true;
    identities = [
      {
        serial = "36854515";
        identity = "AGE-PLUGIN-YUBIKEY-17DDRYQ5ZFMHALWQJTKHAV";
      } # yubi-black
      {
        serial = "36862273";
        identity = "AGE-PLUGIN-YUBIKEY-1G9UNYQ5ZJKDT4CQZ8927Z";
      } # yubi-green
    ];
    secretsFlakeInput = "agenix-secrets";
  };

  # Personal exec-once + windowrules now live in a plain, hot-reloadable file in
  # ncrmro/dotfiles, sourced LAST so it appends to (not replaces) keystone's
  # generated config. Edit that file and `hyprctl reload` — no nix rebuild.
  # Using extraConfig (raw append) preserves keystone's exec-once list; sourcing
  # a plain file has the same additive semantics as inlining the text here.
  wayland.windowManager.hyprland.extraConfig = ''
    source = ${config.dotfiles.repoPath}/packages/hyprland/.config/hypr/hyprland.conf
  '';
  programs.fastfetch.enable = true;

  home.sessionVariables = {
    IMMICH_URL = "https://photos.ncrmro.com";
    # Keep user-editable DeepWork jobs visible to MCP servers generated from
    # home.sessionVariables, not just interactive zsh shells.
    DEEPWORK_ADDITIONAL_JOBS_FOLDERS = lib.mkForce (
      lib.concatStringsSep ":" [
        "$HOME/repos/ncrmro/ks-config/deepwork/jobs"
        "$HOME/repos/Unsupervisedcom/deepwork/library/jobs"
        "$HOME/repos/ncrmro/keystone/.deepwork/jobs"
        "$HOME/repos/ncrmro/keystone/.deepwork/jobs-internal"
      ]
    );
  };

  programs.zsh.initExtra = ''
    if [ -f /run/agenix/ncrmro-immich-api-key ]; then
      export IMMICH_API_KEY="$(tr -d '\n' < /run/agenix/ncrmro-immich-api-key)"
    fi
  '';

  programs.git.settings = {
    credential.helper = "store";
    includeIf."gitdir:~/code/unsupervised/" = {
      path = "~/code/unsupervised/.gitconfig";
    };
  };

  keystone.terminal.mail = {
    enable = true;
    accountName = "ncrmro";
    email = "nicholas.romero@ncrmro.com";
    displayName = "Nicholas Romero";
    login = "ncrmro";
    host = "mail.ncrmro.com";
    passwordCommand = "cat /run/agenix/stalwart-mail-ncrmro-password";
  };

  keystone.notes = {
    enable = true;
    repo = "ssh://forgejo@git.ncrmro.com:2222/ncrmro/notes.git";
    sync.enable = true;
  };

  keystone.terminal.aiExtensions.enable = true;
  keystone.terminal.calendar.enable = true;
  keystone.terminal.contacts.enable = true;
  keystone.terminal.timer.enable = true;
}
