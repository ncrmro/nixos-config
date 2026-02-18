{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.himalaya-stalwart;
in {
  options.programs.himalaya-stalwart = {
    enable = mkEnableOption "Himalaya email client for Stalwart";

    accountName = mkOption {
      type = types.str;
      description = "Account name in Himalaya config";
    };

    email = mkOption {
      type = types.str;
      description = "Email address";
    };

    displayName = mkOption {
      type = types.str;
      description = "Display name for sent emails";
    };

    login = mkOption {
      type = types.str;
      description = "Stalwart account login name";
    };

    passwordCommand = mkOption {
      type = types.str;
      description = "Command to retrieve the password";
    };

    host = mkOption {
      type = types.str;
      default = "mail.ncrmro.com";
      description = "Mail server hostname";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [pkgs.himalaya];

    xdg.configFile."himalaya/config.toml".text = ''
      [accounts.${cfg.accountName}]
      email = "${cfg.email}"
      display-name = "${cfg.displayName}"
      default = true

      backend.type = "imap"
      backend.host = "${cfg.host}"
      backend.port = 993
      backend.encryption.type = "tls"
      backend.login = "${cfg.login}"
      backend.auth.type = "password"
      backend.auth.command = "${cfg.passwordCommand}"

      message.send.backend.type = "smtp"
      message.send.backend.host = "${cfg.host}"
      message.send.backend.port = 465
      message.send.backend.encryption.type = "tls"
      message.send.backend.login = "${cfg.login}"
      message.send.backend.auth.type = "password"
      message.send.backend.auth.command = "${cfg.passwordCommand}"

      # Stalwart folder names (differ from Himalaya defaults)
      folder.sent = "Sent Items"
      folder.drafts = "Drafts"
      folder.trash = "Deleted Items"
    '';
  };
}
