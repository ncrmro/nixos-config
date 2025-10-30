{
  lib,
  pkgs,
  inputs,
  ...
}: let
  zesh = pkgs.callPackage ../../../../packages/zesh {};
in {
  imports = [
    ./helix.nix
    ./playwright.nix
    ./ssh.nix
    ../keybindings.nix
  ];
  # UV - Fast Python package installer and resolver written in Rust
  # https://github.com/astral-sh/uv
  programs.uv.enable = true;

  # K9s - Kubernetes CLI and TUI to manage your clusters
  # https://k9scli.io/
  programs.k9s.enable = true;

  # Git LFS - Git extension for versioning large files
  # https://git-lfs.com/
  programs.git.lfs.enable = true;

  # AWS CLI - Official Amazon AWS command-line interface
  # https://aws.amazon.com/cli/
  programs.awscli.enable = true;

  home.packages = with pkgs; [
    # Devbox - Instant, portable, and predictable development environments
    # https://www.jetify.com/devbox
    devbox

    # Kubectl - Kubernetes command-line tool
    # https://kubernetes.io/docs/reference/kubectl/
    kubectl

    # Helm - The package manager for Kubernetes
    # https://helm.sh/
    kubernetes-helm

    # LogCLI - Grafana Loki's command-line tool for querying logs
    # https://grafana.com/docs/loki/latest/tools/logcli/
    # no package in nixos atm
    #logcli

    # Lazygit - Simple terminal UI for git commands
    # https://github.com/jesseduffield/lazygit
    lazygit

    # Lazydocker - Simple terminal UI for docker and docker-compose
    # https://github.com/jesseduffield/lazydocker
    lazydocker

    # Railway CLI - Command line interface for Railway.app
    # https://railway.app/
    railway

    # traceroute # Does not work on macOS

    # SQLite - Self-contained SQL database engine
    # https://www.sqlite.org/
    sqlite

    # Turso CLI - CLI for Turso distributed SQLite database
    # https://turso.tech/
    turso-cli

    # htop - Interactive process viewer
    # https://htop.dev/
    htop

    # Corepack - Package manager manager for Node.js
    # https://nodejs.org/api/corepack.html
    corepack

    # FNM - Fast Node Manager - Fast and simple Node.js version manager
    # https://github.com/Schniz/fnm
    fnm

    # Zip - Compression and file packaging utility
    zip

    # Unzip - Extraction utility for .zip archives
    unzip

    # Node.js - JavaScript runtime built on Chrome's V8 engine
    # https://nodejs.org/
    nodejs_24

    # Devenv - Fast, declarative, reproducible dev environments
    # https://devenv.sh/
    devenv

    # Kind - Kubernetes IN Docker - local Kubernetes cluster
    # https://kind.sigs.k8s.io/
    kind

    # Ruby - Dynamic, open source programming language
    # https://www.ruby-lang.org/
    ruby

    # Rustup - The Rust toolchain installer
    # https://rustup.rs/
    rustup

    # Python 3.12 - High-level programming language
    # https://www.python.org/
    python312Full
    python312Packages.pip

    # Chart Testing - Tool for testing Helm charts
    # https://github.com/helm/chart-testing
    chart-testing

    asdf-vm

    # Does not support Network Manager
    # impala # TUI for managing wifi

    # Bottom - Graphical process/system monitor
    # https://github.com/ClementTsang/bottom
    bottom

    # Eza - Modern replacement for ls with colors and git integration
    # https://github.com/eza-community/eza
    eza

    # Ripgrep - Fast search tool that recursively searches directories
    # https://github.com/BurntSushi/ripgrep
    ripgrep

    # Tree - Recursive directory listing program
    # https://gitlab.com/OldManProgrammer/unix-tree
    tree

    # jq - Command-line JSON processor
    # https://jqlang.github.io/jq/
    jq

    # yq - Command-line YAML/XML/TOML processor (jq wrapper)
    # https://github.com/mikefarah/yq
    yq

    # SOPS - Simple and flexible tool for managing secrets
    # https://github.com/getsops/sops
    sops

    # GNU Stow - Symlink farm manager for installing software
    # https://www.gnu.org/software/stow/
    stow

    # PostgreSQL - Powerful open source relational database
    # https://www.postgresql.org/
    postgresql

    # # fd # Better find
    # httpie # Better curl
    # # diffsitter # Better diff

    # Marksman - Language server for Markdown
    # https://github.com/artempyanykh/marksman
    marksman

    # Yarn - Fast, reliable, and secure dependency management
    # https://yarnpkg.com/
    yarn

    # network tools

    # Dig - DNS lookup utility
    # https://www.isc.org/bind/
    dig

    # Nmap - Network exploration tool and security scanner
    # https://nmap.org/
    nmap

    # Socat - Multipurpose relay for bidirectional data transfer
    # https://www.dest-unreach.org/socat/
    socat

    # secret management

    # Agenix - Age-encrypted secrets for NixOS
    # https://github.com/ryantm/agenix
    inputs.agenix.packages.${pkgs.system}.default

    # OpenSSL - Cryptography and SSL/TLS toolkit
    # https://www.openssl.org/
    openssl

    # (import inputs.nixpkgs-unstable {
    #   inherit (pkgs) system;
    #   config.allowUnfree = true;
    # }).sbom-tool

    # Claude Code - AI-powered CLI assistant from Anthropic
    # https://claude.com/claude-code
    (import inputs.nixpkgs-unstable {
      inherit (pkgs) system;
      config.allowUnfree = true;
    }).claude-code

    # GitHub Copilot CLI - AI pair programmer in your terminal
    # https://githubnext.com/projects/copilot-cli
    (import inputs.nixpkgs-unstable {
      inherit (pkgs) system;
      config.allowUnfree = true;
    }).github-copilot-cli

    # Session management
    zesh # Zellij session manager with zoxide integration
  ];

  # Direnv - Load directory-specific environment variables automatically
  # Automatically loads .envrc files when entering directories
  # Supports dotenv (.env) files for environment variable management
  # https://direnv.net/
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    config = {global = {load_dotenv = true;};};
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

  # Zellij - A terminal multiplexer with layouts, panes, and tabs
  # Modern alternative to tmux/screen with built-in session management
  # https://zellij.dev/
  programs.zellij = {
    enable = true;
    enableZshIntegration = false;
    settings = {
      theme = "tokyo-night-dark";
      startup_tips = false;
    };
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
      # Session management
      zs = "zesh connect";
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
