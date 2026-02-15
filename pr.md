feat(agent-drago): add email trigger systemd timer

Implements the drago-email-trigger spike. Polls drago@ncrmro.com INBOX
every minute via Himalaya and logs new messages to ~/.email-trigger.log.

Reference: spikes/drago-email-trigger in obsidian repo

Files modified:
- home-manager/drago/email-trigger.nix (new)
- hosts/agent-drago/default.nix
- home-manager/common/global/default.nix (lib.mkForce for git config)
- modules/users/drago.nix (added ocean SSH key)

Test results:
- `nix flake check` passed with warnings (no critical errors).

How to test manually:
1. Rebuild agent-drago: `sudo nixos-rebuild switch --flake .#agent-drago`
2. Check timer status: `ssh drago@agent-drago -p 2223 "systemctl --user status email-trigger.timer"`
3. Send test email to drago@ncrmro.com
4. Wait 1 minute and check log: `ssh drago@agent-drago -p 2223 "cat ~/.email-trigger.log"`

Any follow-up items:
- Consider adding unit tests for the systemd timer configuration.
- Evaluate potential for IMAP IDLE instead of polling for future improvements.
