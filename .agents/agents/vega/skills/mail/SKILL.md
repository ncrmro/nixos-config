---
name: mail
description: Process Vega's JMAP INBOX with xin, reply in-thread, and move completed messages to Processed.
allowed-tools: Bash(xin:*), Bash(jq:*)
---

# Vega mail

Use the `xin` JMAP CLI with credentials supplied through `XIN_BASE_URL`,
`XIN_BASIC_USER`, and `XIN_BASIC_PASS`. Parse its stable JSON output; do not use
plain output. `$LINK_MAIL_PROCESSED` names the completed-mail mailbox and
defaults to `Processed`.

There is no local reply state. A message is pending exactly while it remains in
INBOX, so always reply first and move it second.

Repeat until INBOX is empty:

1. List pending messages:

   ```bash
   xin messages search "in:inbox" --max 200 | jq -r '.data.items[].emailId'
   ```

2. Read one message:

   ```bash
   xin get <emailId> --format full
   ```

3. Compose a genuine, useful reply and preserve the thread:

   ```bash
   xin reply <emailId> --text "…reply…"
   ```

   Confirm the returned JSON has `"ok": true`. If it does not, leave the
   original in INBOX and report the failure.

4. Mark the original complete:

   ```bash
   xin batch modify <emailId> --remove inbox --add "$LINK_MAIL_PROCESSED"
   ```

Do not delete mail, move an unreplied message, expose credentials, or configure
accounts. Use `xin <command> --help` when command discovery is needed.
