{ config, lib, pkgs, ... }:

{
  systemd.user.services.email-trigger = {
    Unit = {
      Description = "Email trigger service that checks for new messages";
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "check-email" ''
        #!/usr/bin/env bash
        set -euo pipefail

        LOG_FILE="$HOME/.email-trigger.log"
        touch "$LOG_FILE"

        NEW_MESSAGES=$(${pkgs.himalaya}/bin/himalaya list -a drago@ncrmro.com 2>&1 || echo "")

        if [ -n "$NEW_MESSAGES" ]; then
          echo "[$(date -Iseconds)] New messages detected:" >> "$LOG_FILE"
          echo "$NEW_MESSAGES" >> "$LOG_FILE"
          echo "---" >> "$LOG_FILE"
        else
          echo "[$(date -Iseconds)] No new messages" >> "$LOG_FILE"
        fi
      '';
    };
  };

  systemd.user.timers.email-trigger = {
    Unit = {
      Description = "Timer for email trigger service";
    };
    Timer = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
      Unit = "email-trigger.service";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
