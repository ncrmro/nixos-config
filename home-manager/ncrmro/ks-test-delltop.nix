{ ... }:
{
  imports = [
    ../common/features/desktop/digital_audio_workstation.nix
  ];

  programs.zsh.initContent = ''
    # NixOS rebuild helper with --boot support for boot-critical changes.
    update() {
      local cmd="switch"
      if [[ "$1" == "--boot" ]]; then
        cmd="boot"
        shift
      fi
      sudo nixos-rebuild "$cmd" --flake ~/repos/ncrmro/ks-config#ks-test-delltop "$@"
      if [[ "$cmd" == "boot" ]]; then
        echo "Reboot required to apply changes."
      fi
    }
  '';
}
