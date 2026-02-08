{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Himalaya email client configuration for Stalwart
  # Requires: drago user created in Stalwart admin (https://mail.ncrmro.com:8080)
  xdg.configFile."himalaya/config.toml".text = ''
    [accounts.drago]
    email = "drago@ncrmro.com"
    display-name = "Drago"
    default = true

    backend.type = "imap"
    backend.host = "mail.ncrmro.com"
    backend.port = 993
    backend.encryption.type = "tls"
    backend.login = "drago"
    backend.auth.type = "password"
    backend.auth.command = "cat /run/agenix/stalwart-mail-drago-password"

    message.send.backend.type = "smtp"
    message.send.backend.host = "mail.ncrmro.com"
    message.send.backend.port = 465
    message.send.backend.encryption.type = "tls"
    message.send.backend.login = "drago"
    message.send.backend.auth.type = "password"
    message.send.backend.auth.command = "cat /run/agenix/stalwart-mail-drago-password"
  '';

  home.packages = [ pkgs.himalaya ];
}
