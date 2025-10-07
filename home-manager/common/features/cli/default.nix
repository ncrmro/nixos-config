{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./playwright.nix
    #     ./bash.nix
    #     ./bat.nix
    #     ./direnv.nix
    #     ./fish.nix
    #     ./git.nix
    #     ./pnpm.nix
    #     ./shellcolor.nix
    #     ./starship.nix
    #     ./zoxide.nix
  ];
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
    htop
    corepack
    fnm
    zip
    unzip
    nodejs_24
    devenv
    kind
    ruby
    rustup
    python312Full
    python312Packages.pip
    chart-testing
    # Does not support Network Manager
    # impala # TUI for managing wifi
    bottom # System viewer
    eza # Better ls
    ripgrep # Better grep
    tree # Directory tree visualization
    jq
    yq
    sops
    stow
    postgresql
    # # fd # Better find
    # httpie # Better curl
    # # diffsitter # Better diff
    # jq # JSON pretty printer and manipulator
    marksman
    yarn

    # network tools
    dig
    nmap

    # secret management
    inputs.agenix.packages.${pkgs.system}.default

    openssl
    (import inputs.nixpkgs-unstable {
      inherit (pkgs) system;
      config.allowUnfree = true;
    }).sbom-tool
    (import inputs.nixpkgs-unstable {
      inherit (pkgs) system;
      config.allowUnfree = true;
    }).claude-code
  ];
  programs.zsh = {
    enable = true;
    # enableCompletions = true;
    # autosuggestions.enable = true;
    # syntaxHighlighting.enable = true;

    shellAliases = {
      # Better unix commands
      l = "eza -1l";
      ls = "eza -1l";
      grep = "rg";
      # Local Development
      g = "git";
      lzg = "lazygit";
      "docker comppose" = "docker-compose";
      dc = "docker-compose";
      k = "kubectl";
    };
    history.size = 100000;
    zplug.enable = lib.mkForce false;
    oh-my-zsh = {
      # "ohMyZsh" without Home Manager
      enable = true;
      plugins = ["git"];
      theme = "robbyrussell";
    };
  };

  programs.git.aliases = {
    s = "switch";
    f = "fetch";
    p = "pull";
    rff = "reset --force";
    r = "rebase";
    #      rsdm = "git checkout orgin/main --"
  };
}
