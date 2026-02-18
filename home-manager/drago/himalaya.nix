{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.himalaya-stalwart = {
    enable = true;
    accountName = "drago";
    email = "drago@ncrmro.com";
    displayName = "Drago";
    login = "drago";
    passwordCommand = "cat /run/agenix/stalwart-mail-drago-password";
  };
}
