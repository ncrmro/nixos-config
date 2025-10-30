# Disabling Wake Lock for Claude in Chrome

**Issue**: Claude.ai (and other Chrome tabs) are using the Screen Wake Lock API, which prevents the monitor from suspending via hypridle.

## Problem Summary

Chrome's Screen Wake Lock API is automatically granted without user permission prompts. Claude.ai uses this API (likely to prevent interruption during long-running tasks), which causes Chrome to send D-Bus ScreenSaver inhibit requests that block hypridle from turning off the display.

## Why This Happens

1. Claude may be using wake locks to prevent screen timeout during:
   - Long code generation tasks
   - Active conversations
   - File processing operations
2. Chrome has **no built-in per-site permission UI** for wake lock API
3. Wake locks are granted automatically without user consent

## Solutions (Ranked by Ease)

### Solution 1: Close Claude Tab When Not Actively Using ✅ EASIEST

**Action**: Simply close the Claude browser tab when you're done with active work

**Pros**:
- Immediate effect
- No configuration needed
- Zero risk

**Cons**:
- Requires manual tab management
- Loses conversation context if not saved

**Implementation**: Just close the tab!

---

### Solution 2: Use hypridle's `ignore_dbus_inhibit` Option ⚡ RECOMMENDED

**Action**: Configure hypridle to ignore all D-Bus inhibitor requests, including Chrome's wake locks

**Implementation**:

Edit the hypridle configuration in your omarchy-nix config:

```nix
# In /home/ncrmro/code/omarchy/omarchy-nix/modules/home-manager/hypridle.nix
{...}: {
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        ignore_dbus_inhibit = true;  # Add this line
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 330;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on && brightnessctl -r";
        }
      ];
    };
  };
}
```

**Apply changes**:
```bash
# Rebuild home-manager configuration
home-manager switch --flake ~/code/omarchy/omarchy-nix#ncrmro@ncrmro-workstation

# Or if using omarchy rebuild script
~/code/omarchy/omarchy/bin/omarchy-refresh-hypridle
```

**Pros**:
- Permanent solution
- Works system-wide for all applications
- Display will always suspend after timeout
- Declared in your NixOS config

**Cons**:
- Will also ignore **legitimate** wake locks (e.g., during video playback)
- You might experience screen suspend during YouTube videos or presentations

---

### Solution 3: Browser Extension to Block Wake Lock API 🔧 TECHNICAL

**Action**: Install or create a browser extension that overrides the Wake Lock API

**Option A**: Use an existing extension (if available)
- Search Chrome Web Store for "wake lock blocker" or similar
- As of 2025, there may not be a mainstream extension for this

**Option B**: Create a custom userscript/extension

Create a simple Chrome extension manifest:

```json
{
  "manifest_version": 3,
  "name": "Wake Lock Blocker",
  "version": "1.0",
  "permissions": [],
  "content_scripts": [
    {
      "matches": ["https://claude.ai/*"],
      "js": ["block-wake-lock.js"],
      "run_at": "document_start"
    }
  ]
}
```

Create `block-wake-lock.js`:
```javascript
// Override navigator.wakeLock to return a no-op implementation
if ('wakeLock' in navigator) {
  Object.defineProperty(navigator, 'wakeLock', {
    get: () => ({
      request: () => Promise.reject(new DOMException('Wake Lock blocked by extension', 'NotAllowedError'))
    })
  });
}
```

**Pros**:
- Surgical solution - only affects specific sites
- Doesn't impact legitimate wake lock usage elsewhere

**Cons**:
- Requires maintaining custom extension
- Needs manual installation
- May break if Claude's implementation changes

---

### Solution 4: Launch Chrome with Wake Lock Disabled 🚀 GLOBAL

**Action**: Add Chrome launch flag to disable wake lock API entirely

**NixOS Implementation**:

If you're managing Chrome through your NixOS config, add:

```nix
programs.google-chrome = {
  enable = true;
  commandLineArgs = [
    "--disable-features=WakeLock"
  ];
};
```

**Or create a wrapper script**:

```bash
#!/usr/bin/env bash
# ~/bin/chrome-no-wakelock
exec google-chrome-stable --disable-features=WakeLock "$@"
```

**Pros**:
- System-wide solution for Chrome
- Simple flag-based approach

**Cons**:
- Disables wake lock for **all websites** in Chrome
- May break functionality in web apps that legitimately need wake lock
- Affects all Chrome instances

---

### Solution 5: Use a Different Browser for Claude 🌐 ALTERNATIVE

**Action**: Open Claude in a different browser (Firefox, Chromium without flags, etc.) and close it when done

**Pros**:
- Isolates the wake lock issue
- Keeps your main Chrome clean

**Cons**:
- Requires managing multiple browsers
- Still need to close the tab/browser when done

---

## Recommended Approach

For your use case, I recommend **Solution 2** (hypridle's `ignore_dbus_inhibit = true`) because:

1. ✅ It's declarative and lives in your NixOS config
2. ✅ Works system-wide, solving the issue permanently
3. ✅ Simple one-line configuration change
4. ✅ Easy to revert if needed

**Trade-off**: You won't be able to keep videos playing without screen suspend, but based on your usage pattern (development workstation), this is likely acceptable.

### Implementation Steps for Solution 2

1. Edit the hypridle module:
   ```bash
   cd ~/code/omarchy/omarchy-nix
   # Edit modules/home-manager/hypridle.nix
   # Add: ignore_dbus_inhibit = true
   ```

2. Rebuild:
   ```bash
   home-manager switch --flake .#ncrmro@ncrmro-workstation
   ```

3. Restart hypridle:
   ```bash
   systemctl --user restart hypridle.service
   ```

4. Test by leaving Claude tab open and waiting for timeout

---

## Testing the Solution

After implementing any solution, verify it works:

```bash
# Monitor hypridle logs in real-time
journalctl --user -u hypridle.service -f

# Check if inhibitors are being ignored
# You should see idle timeouts trigger even with Chrome wake locks
```

Expected behavior after fix:
- Display will lock after 5 minutes (300s)
- Display will turn off after 5.5 minutes (330s)
- Even with Claude tab open

---

## Monitoring Wake Locks (Post-Fix)

To verify Claude is still requesting wake locks but they're being ignored:

```bash
# Check recent wake lock activity
journalctl --user -u hypridle.service --since "10 minutes ago" | grep "inhibit"

# You should still see Chrome wake lock requests
# But hypridle will no longer ignore idle events
```

---

## Alternative: Selective Ignore (Advanced)

If you want to ignore wake locks only from specific applications while respecting others, you would need to:

1. Patch hypridle to support application allowlists
2. Configure it to ignore Chrome but respect mpv/VLC

This is not currently supported by hypridle and would require custom development.

---

## References

- [hypridle Configuration Docs](https://wiki.hyprland.org/Hypr-Ecosystem/hypridle/)
- [Screen Wake Lock API - MDN](https://developer.mozilla.org/en-US/docs/Web/API/Screen_Wake_Lock_API)
- [Hyprland Idle Management](https://wiki.hyprland.org/)
