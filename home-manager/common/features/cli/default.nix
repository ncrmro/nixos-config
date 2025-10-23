{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [./helix.nix ./playwright.nix];
  programs.uv.enable = true;
  programs.k9s.enable = true;
  programs.git.lfs.enable = true;
  programs.awscli.enable = true;
  home.packages = with pkgs; [
    devbox
    kubectl
    kubernetes-helm
    lazygit # TUI for git
    lazydocker # TUI for docker
    railway
    # traceroute # Does not work on macOS
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
    # (import inputs.nixpkgs-unstable {
    #   inherit (pkgs) system;
    #   config.allowUnfree = true;
    # }).sbom-tool
    (import inputs.nixpkgs-unstable {
      inherit (pkgs) system;
      config.allowUnfree = true;
    }).claude-code
    (import inputs.nixpkgs-unstable {
      inherit (pkgs) system;
      config.allowUnfree = true;
    }).github-copilot-cli
  ];

  # Direnv - Load directory-specific environment variables automatically
  # Automatically loads .envrc files when entering directories
  # Supports dotenv (.env) files for environment variable management
  # https://direnv.net/
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    config = {
      global = {
        load_dotenv = true;
      };
    };
  };

  # Starship - A minimal, blazing-fast, and infinitely customizable prompt for any shell
  # Shows git status, language versions, execution time, and more in your terminal prompt
  # https://starship.rs/
  programs.starship.enable = true;

  # Zoxide - A smarter cd command that learns your navigation patterns
  # Tracks your most used directories and lets you jump to them with 'z <partial-name>'
  # Example: 'z proj' jumps to ~/code/projects, 'zi' for interactive selection
  # https://github.com/ajeetdsouza/zoxide
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

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
      lg = "lazygit";
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
  };
}
