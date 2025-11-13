{pkgs, ...}: {
  # Mosh - Mobile shell, remote terminal with UDP roaming support
  # https://mosh.org/
  # Provides both client and server capabilities for roaming terminal sessions
  home.packages = with pkgs; [
    mosh
  ];
}
