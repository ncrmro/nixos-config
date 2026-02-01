{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Himalaya email client configuration for Stalwart on ocean
  xdg.configFile."himalaya/config.toml".text = ''
    [accounts.ncrmro]
    email = "nicholas.romero@ncrmro.com"
    display-name = "Nicholas Romero"
    default = true

    backend.type = "imap"
    backend.host = "mail.ncrmro.com"
    backend.port = 993
    backend.encryption.type = "tls"
    # Login is the Stalwart account name, not the email address
    backend.login = "ncrmro"
    backend.auth.type = "password"
    backend.auth.command = "cat /run/agenix/stalwart-mail-ncrmro-password"

    message.send.backend.type = "smtp"
    message.send.backend.host = "mail.ncrmro.com"
    message.send.backend.port = 465
    message.send.backend.encryption.type = "tls"
    message.send.backend.login = "ncrmro"
    message.send.backend.auth.type = "password"
    message.send.backend.auth.command = "cat /run/agenix/stalwart-mail-ncrmro-password"
  '';
}
