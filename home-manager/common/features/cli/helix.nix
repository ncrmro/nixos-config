{
  pkgs,
  inputs,
  ...
}: let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in {
  home.packages = with pkgs; [
    bash-language-server
    docker-compose-language-service
    yaml-language-server
    dockerfile-language-server-nodejs
    vscode-langservers-extracted
    helm-ls
    ruby-lsp
    solargraph
    # rust-analyzer
  ];

  programs.helix = {
    enable = true;
    package = pkgs-unstable.helix;
    settings = {
      theme = "kinda_nvim";
      editor = {
        line-number = "absolute";
        mouse = true;
        clipboard-provider = "wayland";
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
      };
      keys.normal = {
        ret = ":write";
      };
    };
    languages = with pkgs; {
      language-server = {
        typescript-language-server = {
          command = "${typescript-language-server}/bin/typescript-language-server";
          args = ["--stdio"];
          config = {
            documentFormatting = false;
            tsserver = {
              path = "./node_modules/typescript/lib";
              fallbackPath = "${typescript}/lib/node_modules/typescript/lib";
            };
          };
        };
        bash-language-server = {
          command = "${bash-language-server}/bin/bash-language-server";
          args = ["start"];
        };
        docker-compose-language-service = {
          command = "${docker-compose-language-service}/bin/docker-compose-langserver";
          args = ["--stdio"];
        };
        yaml-language-server = {
          command = "${yaml-language-server}/bin/yaml-language-server";
          args = ["--stdio"];
        };
        dockerfile-language-server = {
          command = "${dockerfile-language-server-nodejs}/bin/docker-langserver";
          args = ["--stdio"];
        };
        vscode-json-language-server = {
          command = "${vscode-langservers-extracted}/bin/vscode-json-language-server";
          args = ["--stdio"];
        };
        vscode-css-language-server = {
          command = "${vscode-langservers-extracted}/bin/vscode-css-language-server";
          args = ["--stdio"];
        };
        vscode-html-language-server = {
          command = "${vscode-langservers-extracted}/bin/vscode-html-language-server";
          args = ["--stdio"];
        };
        helm-ls = {
          command = "${helm-ls}/bin/helm_ls";
          args = ["serve"];
        };
        ruby-lsp = {command = "${ruby-lsp}/bin/ruby-lsp";};
        solargraph = {
          command = "${solargraph}/bin/solargraph";
          args = ["stdio"];
        };
        # rust-analyzer = {
        #   command = "${rust-analyzer}/bin/rust-analyzer";
        # };
      };
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
        }
        {
          name = "bash";
          language-servers = ["bash-language-server"];
        }
        {
          name = "yaml";
          language-servers = ["yaml-language-server"];
        }
        {
          name = "dockerfile";
          language-servers = ["dockerfile-language-server"];
        }
        {
          name = "docker-compose";
          language-servers = ["docker-compose-language-service" "yaml-language-server"];
        }
        {
          name = "json";
          language-servers = ["vscode-json-language-server"];
        }
        {
          name = "json5";
          language-servers = ["vscode-json-language-server"];
        }
        {
          name = "css";
          language-servers = ["vscode-css-language-server"];
        }
        {
          name = "html";
          language-servers = ["vscode-html-language-server"];
        }
        {
          name = "helm";
          language-servers = ["helm-ls"];
        }
        {
          name = "ruby";
          language-servers = ["ruby-lsp" "solargraph"];
        }
        # {
        #   name = "rust";
        #   language-servers = ["rust-analyzer"];
        # }
      ];
    };
  };

  # Copy theme files from the flake input
  xdg.configFile."helix/themes/kinda_nvim.toml".source = "${inputs.kinda-nvim-hx}/kinda_nvim.toml";
  xdg.configFile."helix/themes/kinda_nvim_light.toml".source = "${inputs.kinda-nvim-hx}/kinda_nvim_light.toml";
}
