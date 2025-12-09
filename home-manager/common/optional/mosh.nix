{
  pkgs,
  config,
  lib,
  ...
}: {
  # Mosh - Mobile shell, remote terminal with UDP roaming support
  # https://mosh.org/
  # Provides both client and server capabilities for roaming terminal sessions
  home.packages = with pkgs; [
    mosh
  ];

  # Ensure nix-profile bin is in PATH for SSH sessions
  # This makes mosh-server available when SSH remotely invokes it
  home.sessionVariables.PATH = "${config.home.profileDirectory}/bin:$PATH";

  # Also ensure it's in the shell initialization for interactive shells
  programs.zsh.initContent = lib.mkIf config.programs.zsh.enable ''
    export PATH="${config.home.profileDirectory}/bin:$PATH"
  '';

  programs.bash.initExtra = lib.mkIf config.programs.bash.enable ''
    export PATH="${config.home.profileDirectory}/bin:$PATH"
  '';
}
