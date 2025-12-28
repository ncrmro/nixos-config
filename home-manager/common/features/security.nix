{
  config,
  lib,
  pkgs,
  ...
}:
{
  # GNOME Keyring integration for Home Manager
  # Provides comprehensive credential management integration

  options = {
    programs.gnome-keyring-integration = {
      enable = lib.mkEnableOption "GNOME Keyring integration with SSH, Docker, and password managers";

      ssh = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable SSH agent integration with GNOME Keyring";
        };
      };

      docker = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Docker credential helper integration";
        };
      };

      passwordManagers = {
        onePassword = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Install and configure 1Password CLI";
        };

        bitwarden = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Install and configure Bitwarden CLI";
        };
      };
    };
  };

  config = lib.mkIf config.programs.gnome-keyring-integration.enable {
    # Enable GNOME Keyring service with all components
    services.gnome-keyring = {
      enable = true;
      components = [
        "pkcs11"
        "secrets"
        "ssh"
      ];
    };

    # Install core keyring tools
    home.packages =
      with pkgs;
      [
        libsecret # For secret-tool CLI
      ]
      ++ lib.optionals config.programs.gnome-keyring-integration.passwordManagers.onePassword [
        _1password
        _1password-cli
      ]
      ++ lib.optionals config.programs.gnome-keyring-integration.passwordManagers.bitwarden [
        bitwarden-cli
      ]
      ++ lib.optionals config.programs.gnome-keyring-integration.docker [
        docker-credential-helpers
      ];

    # SSH integration
    programs.ssh = lib.mkIf config.programs.gnome-keyring-integration.ssh.enable {
      enable = true;
      addKeysToAgent = "yes";
      extraConfig = ''
        AddKeysToAgent yes
        IdentitiesOnly yes

        # Uncomment to use 1Password SSH agent instead of gnome-keyring
        # Host *
        #   IdentityAgent ~/.1password/agent.sock
      '';
    };

    # Set SSH_AUTH_SOCK to use GNOME Keyring SSH agent
    home.sessionVariables = lib.mkIf config.programs.gnome-keyring-integration.ssh.enable {
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
    };

    # Docker credential helper configuration
    xdg.configFile."docker/config.json" =
      lib.mkIf config.programs.gnome-keyring-integration.docker.enable
        {
          text = builtins.toJSON {
            credsStore = "secretservice";
            credHelpers = {
              "gcr.io" = "secretservice";
              "us-docker.pkg.dev" = "secretservice";
              "europe-docker.pkg.dev" = "secretservice";
              "asia-docker.pkg.dev" = "secretservice";
              "ghcr.io" = "secretservice";
              "docker.io" = "secretservice";
              "registry-1.docker.io" = "secretservice";
            };
          };
        };

    # Bitwarden session management service
    systemd.user.services.bitwarden-session-restore =
      lib.mkIf config.programs.gnome-keyring-integration.passwordManagers.bitwarden
        {
          Unit = {
            Description = "Restore Bitwarden session from GNOME Keyring";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "bw-session-restore" ''
              # Check if Bitwarden session exists in keyring
              BW_SESSION=$(${pkgs.libsecret}/bin/secret-tool lookup service "bitwarden" session "main" 2>/dev/null || true)

              if [ -n "$BW_SESSION" ]; then
                # Verify session is still valid
                if ${pkgs.bitwarden-cli}/bin/bw unlock --check --session "$BW_SESSION" &>/dev/null; then
                  echo "Bitwarden session restored from keyring"
                  # Export session for user environment
                  echo "export BW_SESSION='$BW_SESSION'" > "$HOME/.bitwarden-session"
                else
                  echo "Bitwarden session expired, removing from keyring"
                  ${pkgs.libsecret}/bin/secret-tool clear service "bitwarden" session "main" 2>/dev/null || true
                  rm -f "$HOME/.bitwarden-session"
                fi
              else
                echo "No Bitwarden session found in keyring"
                rm -f "$HOME/.bitwarden-session"
              fi
            '';
            RemainAfterExit = true;
          };
          Install.WantedBy = [ "default.target" ];
        };

    # 1Password session management service
    systemd.user.services.onepassword-session-restore =
      lib.mkIf config.programs.gnome-keyring-integration.passwordManagers.onePassword
        {
          Unit = {
            Description = "Restore 1Password session from GNOME Keyring";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "op-session-restore" ''
              # Check if 1Password session exists in keyring
              OP_SESSION=$(${pkgs.libsecret}/bin/secret-tool lookup service "1password" account "default" 2>/dev/null || true)

              if [ -n "$OP_SESSION" ]; then
                # Verify session is still valid by trying to list items
                if ${pkgs._1password-cli}/bin/op item list --session="$OP_SESSION" &>/dev/null; then
                  echo "1Password session restored from keyring"
                  # Export session for user environment
                  echo "export OP_SESSION_default='$OP_SESSION'" > "$HOME/.onepassword-session"
                else
                  echo "1Password session expired, removing from keyring"
                  ${pkgs.libsecret}/bin/secret-tool clear service "1password" account "default" 2>/dev/null || true
                  rm -f "$HOME/.onepassword-session"
                fi
              else
                echo "No 1Password session found in keyring"
                rm -f "$HOME/.onepassword-session"
              fi
            '';
            RemainAfterExit = true;
          };
          Install.WantedBy = [ "default.target" ];
        };

    # Helper scripts for session management
    home.packages =
      lib.mkIf
        (
          config.programs.gnome-keyring-integration.passwordManagers.bitwarden
          || config.programs.gnome-keyring-integration.passwordManagers.onePassword
        )
        [
          # Bitwarden session helper
          (lib.mkIf config.programs.gnome-keyring-integration.passwordManagers.bitwarden (
            pkgs.writeShellScriptBin "bw-keyring-login" ''
              echo "Logging into Bitwarden and storing session in GNOME Keyring..."

              # Login to Bitwarden
              ${pkgs.bitwarden-cli}/bin/bw login

              # Get session token
              BW_SESSION=$(${pkgs.bitwarden-cli}/bin/bw unlock --raw)

              if [ -n "$BW_SESSION" ]; then
                # Store in GNOME Keyring
                echo -n "$BW_SESSION" | ${pkgs.libsecret}/bin/secret-tool store --label="Bitwarden Session" service "bitwarden" session "main"
                echo "Session stored in GNOME Keyring"

                # Export for current shell
                export BW_SESSION="$BW_SESSION"
                echo "Session exported to current shell"
              else
                echo "Failed to get Bitwarden session"
                exit 1
              fi
            ''
          ))

          # 1Password session helper
          (lib.mkIf config.programs.gnome-keyring-integration.passwordManagers.onePassword (
            pkgs.writeShellScriptBin "op-keyring-login" ''
              echo "Logging into 1Password and storing session in GNOME Keyring..."

              # Login to 1Password (assumes account is already configured)
              OP_SESSION=$(${pkgs._1password-cli}/bin/op signin --account default --raw)

              if [ -n "$OP_SESSION" ]; then
                # Store in GNOME Keyring
                echo -n "$OP_SESSION" | ${pkgs.libsecret}/bin/secret-tool store --label="1Password Session" service "1password" account "default"
                echo "Session stored in GNOME Keyring"

                # Export for current shell
                export OP_SESSION_default="$OP_SESSION"
                echo "Session exported to current shell"
              else
                echo "Failed to get 1Password session"
                exit 1
              fi
            ''
          ))

          # Generic keyring management helper
          (pkgs.writeShellScriptBin "keyring-status" ''
            echo "=== GNOME Keyring Status ==="

            echo "SSH Agent:"
            echo "  SSH_AUTH_SOCK: $SSH_AUTH_SOCK"
            if command -v ssh-add >/dev/null 2>&1; then
              echo "  Loaded keys:"
              ssh-add -l 2>/dev/null || echo "    No keys loaded or agent not running"
            fi

            echo ""
            echo "Stored secrets:"
            ${pkgs.libsecret}/bin/secret-tool search --all 2>/dev/null | head -20 || echo "  No secrets found or keyring locked"

            echo ""
            echo "Docker credential helper:"
            if [ -f "$HOME/.docker/config.json" ]; then
              echo "  Configured: $(grep -q secretservice "$HOME/.docker/config.json" && echo "Yes" || echo "No")"
            else
              echo "  Config file: Not found"
            fi
          '')
        ];

    # Add shell integration for session restoration
    programs.zsh.initContent =
      lib.mkIf
        (
          config.programs.gnome-keyring-integration.passwordManagers.bitwarden
          || config.programs.gnome-keyring-integration.passwordManagers.onePassword
        )
        ''
          # Load password manager sessions from keyring if available
          ${lib.optionalString config.programs.gnome-keyring-integration.passwordManagers.bitwarden ''
            if [ -f "$HOME/.bitwarden-session" ]; then
              source "$HOME/.bitwarden-session"
            fi
          ''}
          ${lib.optionalString config.programs.gnome-keyring-integration.passwordManagers.onePassword ''
            if [ -f "$HOME/.onepassword-session" ]; then
              source "$HOME/.onepassword-session"
            fi
          ''}
        '';

    programs.bash.initExtra =
      lib.mkIf
        (
          config.programs.gnome-keyring-integration.passwordManagers.bitwarden
          || config.programs.gnome-keyring-integration.passwordManagers.onePassword
        )
        ''
          # Load password manager sessions from keyring if available
          ${lib.optionalString config.programs.gnome-keyring-integration.passwordManagers.bitwarden ''
            if [ -f "$HOME/.bitwarden-session" ]; then
              source "$HOME/.bitwarden-session"
            fi
          ''}
          ${lib.optionalString config.programs.gnome-keyring-integration.passwordManagers.onePassword ''
            if [ -f "$HOME/.onepassword-session" ]; then
              source "$HOME/.onepassword-session"
            fi
          ''}
        '';
  };
}
