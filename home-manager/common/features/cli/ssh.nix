{
  lib,
  pkgs,
  ...
}: {
  # YubiKey FIDO2 SSH key (non-resident, ecdsa-sk for firmware 5.1.2)
  # The "private key" is just a handle - useless without the physical YubiKey
  home.file.".ssh/id_ecdsa_sk_yubi5" = {
    source = ../../keys/id_ecdsa_sk_yubi5;
  };

  home.file.".ssh/id_ecdsa_sk_yubi5.pub" = {
    source = ../../keys/id_ecdsa_sk_yubi5.pub;
  };

  programs.ssh = {
    enable = true;
    # Disable deprecated default config
    enableDefaultConfig = false;
    matchBlocks = {
      # Default identity for all hosts
      "*" = {
        identityFile = "~/.ssh/id_ecdsa_sk_yubi5";
      };
      "unsup-laptop.local" = {
        setEnv = {
          TERM = "xterm-256color";
        };
      };
      "unsup-air.local" = {
        setEnv = {
          TERM = "xterm-256color";
        };
      };
    };
  };
}
