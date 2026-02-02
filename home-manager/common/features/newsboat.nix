{ ... }:
{
  programs.newsboat = {
    enable = true;
    extraConfig = ''
      auto-reload yes
      reload-time 30
      show-read-feeds no
      show-read-articles no
    '';
  };
}
