{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.keystone.terminal;
  claude-code = pkgs.callPackage ./claude-code {};
in {
  config = mkIf cfg.enable {
    home.packages = [
      # Claude Code - AI-powered CLI assistant from Anthropic
      # https://claude.com/claude-code
      claude-code
    ];
  };
}
