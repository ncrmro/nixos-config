{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Himalaya email client configuration for Stalwart
  # Requires: luce user created in Stalwart admin (https://mail.ncrmro.com:8080)
  xdg.configFile."himalaya/config.toml".text = ''
    [accounts.luce]
    email = "luce@ncrmro.com"
    display-name = "Luce"
    default = true

    backend.type = "imap"
    backend.host = "mail.ncrmro.com"
    backend.port = 993
    backend.encryption.type = "tls"
    backend.login = "luce"
    backend.auth.type = "password"
    backend.auth.command = "cat /run/agenix/stalwart-mail-luce-password"

    message.send.backend.type = "smtp"
    message.send.backend.host = "mail.ncrmro.com"
    message.send.backend.port = 465
    message.send.backend.encryption.type = "tls"
    message.send.backend.login = "luce"
    message.send.backend.auth.type = "password"
    message.send.backend.auth.command = "cat /run/agenix/stalwart-mail-luce-password"
  '';

  home.packages = [ pkgs.himalaya ];
}
