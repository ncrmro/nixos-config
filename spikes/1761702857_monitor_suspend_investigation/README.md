# Monitor Suspend Investigation

**Date**: 2025-10-28
**Status**: Root Cause Identified
**Host**: ncrmro-workstation (Hyprland on Wayland)

## Problem Statement

The monitor is not suspending after the configured idle timeout. This investigation identifies why hypridle fails to trigger DPMS off despite detecting idle events.

## Investigation Summary

### Environment Details

- **Display Server**: Wayland (Hyprland)
- **Idle Manager**: hypridle (version 0.1.6)
- **Session Type**: User session on seat0 with TTY1
- **Monitors**: 2x LG Ultra HD 4K displays (DP-2 and DP-3)
- **Current Configuration**:
  - Lock after 300s (5 minutes) of idle
  - DPMS off after 330s (5.5 minutes) of idle

### Root Cause: Chrome Wake Locks

**Primary Issue**: Google Chrome is constantly acquiring and releasing "Blink Wake Lock" through D-Bus, which creates inhibitor locks that prevent hypridle from suspending the display.

#### Evidence from hypridle logs:

```
[LOG] ScreenSaver inhibit: true dbus message from google-chrome
[LOG] Inhibit locks: 1
[LOG] Cookie 1569 sent
[LOG] Ignoring from onIdled(), inhibit locks: 1
```

The logs show:
1. Chrome requests a wake lock via D-Bus ScreenSaver interface
2. hypridle increments inhibit lock counter to 1
3. When idle timeout triggers, hypridle **ignores** it due to active inhibitor
4. Chrome periodically releases and re-acquires wake locks

### Configuration Analysis

#### hypridle Configuration (`~/.config/hypr/hypridle.conf`)

```nix
general {
  after_sleep_cmd=hyprctl dispatch dpms on
  before_sleep_cmd=loginctl lock-session
  lock_cmd=pidof hyprlock || hyprlock
}

listener {
  on-timeout=loginctl lock-session
  timeout=300
}

listener {
  on-resume=hyprctl dispatch dpms on && brightnessctl -r
  on-timeout=hyprctl dispatch dpms off
  timeout=330
}
```

**Configuration is correct** - the issue is not with hypridle settings but with external wake lock requests.

#### systemd-logind Configuration

```
KillUserProcesses=no
HandleLidSwitch=suspend
HandlePowerKey=poweroff
HandleSuspendKey=suspend
```

**logind configuration is also correct** - only shows "delay" mode inhibitors (NetworkManager and hypridle itself).

### Current System State

#### Active Inhibitor Locks:
```
WHO            UID  USER   PID  COMM           WHAT  WHY
NetworkManager 0    root   1420 NetworkManager sleep NetworkManager needs to turn off networks (delay)
hypridle       1000 ncrmro 4035 hypridle       sleep Hypridle wants to delay sleep (delay)
```

**Note**: These are "delay" mode inhibitors and should not block DPMS. The actual blocking comes from Chrome's ScreenSaver D-Bus inhibit requests.

## Root Causes Identified

1. **Chrome Wake Locks** (Primary): Google Chrome tabs or extensions are using the Web Wake Lock API, causing Chrome to request ScreenSaver inhibits via D-Bus
2. **Possible Chrome Extensions**: Browser extensions (like video players, productivity tools, or presentation tools) may be holding wake locks
3. **Open Media Tabs**: Tabs with video players (YouTube, streaming services) can hold wake locks even when paused

## Potential Solutions

### Solution 1: Identify and Close Wake Lock Sources in Chrome

**Action**: Navigate to `chrome://media-internals/` in Chrome to see which tabs are holding wake locks

**Steps**:
1. Open Chrome
2. Visit `chrome://media-internals/`
3. Look for "Wake Lock" entries
4. Close or disable tabs/extensions causing wake locks

**Pros**: Immediate fix without configuration changes
**Cons**: Requires manual intervention; issue may return

### Solution 2: Configure hypridle to Ignore D-Bus Inhibits

**Action**: Add `ignore_dbus_inhibit = true` to hypridle general configuration

```nix
general {
  ignore_dbus_inhibit = true;
  after_sleep_cmd = "hyprctl dispatch dpms on";
  before_sleep_cmd = "loginctl lock-session";
  lock_cmd = "pidof hyprlock || hyprlock";
}
```

**Pros**: Forces display suspend regardless of wake locks
**Cons**: Will ignore legitimate wake locks (e.g., during video playback)

### Solution 3: Browser Extension to Control Wake Locks

**Action**: Install a browser extension like "Disable HTML5 Autoplay" or "Tab Suspender" that prevents unwanted wake locks

**Pros**: Provides fine-grained control over wake lock behavior
**Cons**: Requires additional extension management

### Solution 4: Upgrade hypridle/hyprlock

**Action**: Ensure running the latest versions of hypridle and hyprlock (GitHub issue #74 was fixed in newer versions)

Current version: hypridle 0.1.6

**Pros**: May fix underlying bugs with wake lock handling
**Cons**: Potential breaking changes with newer versions

### Solution 5: Use Chrome Flags to Disable Wake Locks

**Action**: Launch Chrome with flags to disable wake lock API:
```
chrome --disable-features=WakeLock
```

**Pros**: System-wide solution for Chrome-related wake locks
**Cons**: May break legitimate functionality in web apps

## Recommendations

### Immediate Action (Recommended)

1. **Check Chrome tabs** using `chrome://media-internals/` to identify active wake lock holders
2. Close unnecessary tabs or disable problematic extensions
3. Consider using a tab suspender extension to automatically suspend idle tabs

### Short-term Solution

Add `ignore_dbus_inhibit = false` (explicit) to the hypridle config and create a script to selectively allow/deny wake locks based on specific applications:

```nix
# In home-manager hypridle configuration
services.hypridle.settings.general.ignore_dbus_inhibit = false;
```

This is actually the default behavior, but making it explicit helps document the intention.

### Long-term Solution

1. **Audit Chrome extensions** - Identify which extensions are using wake locks unnecessarily
2. **Configure Chrome startup flags** - Add `--disable-features=WakeLock` to Chrome launcher if wake locks are not needed
3. **Monitor hypridle logs** - Set up periodic checking of wake lock sources:
   ```bash
   systemctl --user status hypridle.service | grep "inhibit: true"
   ```

## Testing Plan

1. Check current wake lock holders:
   ```bash
   systemctl --user status hypridle.service | grep -A 2 "inhibit: true"
   ```

2. Open `chrome://media-internals/` in Chrome and check "Wake Lock" section

3. Close all Chrome windows and verify if DPMS activates after timeout

4. If issue persists without Chrome, check other Electron apps (1Password, VS Code, etc.)

## Related Issues

- [NixOS Discourse: Hypridle ignoring system idle inhibit](https://discourse.nixos.org/t/hypridle-ignoring-system-idle-inhibit/63125)
- [GitHub Issue #74: inhibit locks < 0](https://github.com/hyprwm/hypridle/issues/74) - Fixed in newer versions
- Web Wake Lock API: https://developer.mozilla.org/en-US/docs/Web/API/Screen_Wake_Lock_API

## Next Steps

- [x] Open `chrome://media-internals/` to identify wake lock sources
- [x] **Identified: Claude.ai is the primary wake lock source**
- [ ] Implement Solution 2: Add `ignore_dbus_inhibit = true` to hypridle config
- [ ] Rebuild home-manager configuration
- [ ] Test display suspend with Claude tab open
- [ ] Monitor hypridle logs to confirm idle events are no longer ignored

## Claude-Specific Solution

**See**: `claude-wake-lock-solution.md` for detailed instructions on disabling wake locks for Claude.

**Quick Fix**: Add `ignore_dbus_inhibit = true` to your hypridle configuration in:
```
~/code/omarchy/omarchy-nix/modules/home-manager/hypridle.nix
```
