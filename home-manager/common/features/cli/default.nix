{lib,pkgs, ...}: {
  #   imports = [
  #     ./bash.nix
  #     ./bat.nix
  #     ./direnv.nix
  #     ./fish.nix
  #     ./git.nix
  #     ./pnpm.nix
  #     ./shellcolor.nix
  #     ./starship.nix
  #     ./zoxide.nix
  #   ];
  programs.uv.enable = true;
  programs.k9s.enable = true;
  programs.git.lfs.enable = true;
  programs.awscli.enable = true;
  home.packages = with pkgs; [
    devbox
    kubectl
    kubernetes-helm
    railway
    traceroute
    sqlite
    turso-cli
    # Does not support Network Manager
    # impala # TUI for managing wifi
    # bottom # System viewer
    # # unstable.eza # Better ls
    # ripgrep # Better grep
    # # fd # Better find
    # httpie # Better curl
    # # diffsitter # Better diff
    # jq # JSON pretty printer and manipulator
  ];

  # home.packages = with pkgs.unstable; [
  #   eza # better ls, temporary whilst as eza is not on stable yet
  # ]
  programs.zsh = {
    enable = true;
    # enableCompletions = true;
    # autosuggestions.enable = true;
    # syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      "docker comppose" = "docker-compose";
      dc = "docker-compose";
      k = "kubectl";

      # update = "sudo nixos-rebuild switch";
    };
    history.size = 100000;
    zplug.enable = lib.mkForce false;
    oh-my-zsh = { # "ohMyZsh" without Home Manager
      enable = true;
      plugins = [ "git" ];
      theme = "robbyrussell";
    };
  };
}
