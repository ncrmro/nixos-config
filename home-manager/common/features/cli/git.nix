{
  lib,
  pkgs,
  ...
}:
{
  programs.git = {
    enable = true;
    userName = "Nicholas Romero";
    userEmail = "ncrmro@gmail.com";
    extraConfig = {
      credential.helper = "store";
      push.autoSetupRemote = true;
      gpg.format = "ssh";
      commit.gpgsign = true;
      user.signingkey = "~/.ssh/id_ed25519";
      lfs.enable = true;
      alias = {
        b = "branch";
        p = "pull";
        co = "checkout";
        c = "commit";
        ci = "commit -a";
        a = "add";
        st = "status -sb";
      };
    };
  };
}
