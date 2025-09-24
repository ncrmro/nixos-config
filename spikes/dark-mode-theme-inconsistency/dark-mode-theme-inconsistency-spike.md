# Dark Mode Theme Inconsistency Investigation

## Problem Statement
Some system components think it's in dark mode while others think it's in light mode. GTK apps (like Chrome) correctly show dark mode, but other applications may not.

## Current State Analysis

### What's Working
- GTK theme is correctly set to dark mode: `GTK_THEME=Adwaita:dark`
- Chrome respects GTK theme and displays in dark mode ✓
- GTK3/GTK4 config files are properly set to `Adwaita:dark`

### What's Broken
- **XDG Desktop Portal** is reporting light mode: `color-scheme: 0` (should be `1` for dark)
- **GNOME/dconf color-scheme** is set to `'default'` (should be `'prefer-dark'`)
- **Qt applications** using Kvantum theme but no dark variant configured

### Environment Variables Found
```bash
GTK_THEME=Adwaita:dark                    # ✓ Correct
QT_STYLE_OVERRIDE=kvantum                 # Partial - needs dark theme
HYPRCURSOR_THEME=Adwaita                  # ✓ OK
XCURSOR_THEME=Adwaita                     # ✓ OK
```

### GSetting Values
```bash
org.gnome.desktop.interface gtk-theme: 'Adwaita:dark'    # ✓ Correct
org.gnome.desktop.interface color-scheme: 'default'      # ❌ Should be 'prefer-dark'
```

### XDG Portal Status
```bash
color-scheme: uint32 0   # ❌ Should be 1 for dark mode
```

## Root Cause
The **omarchy-nix** configuration at `/home/ncrmro/code/omarchy/omarchy-nix/modules/home-manager/default.nix:59-68` sets the GTK theme but is **missing crucial dconf settings** that inform the desktop portal and other applications about the preferred color scheme.

## Technical Details

### Current Configuration (Incomplete)
```nix
gtk = {
  enable = true;
  theme = {
    name = if config.omarchy.theme == "generated_light"
           then "Adwaita"
           else "Adwaita:dark";
    package = pkgs.gnome-themes-extra;
  };
};
```

### Missing Configuration
The configuration lacks:
1. **dconf color-scheme preference** - tells portal services about dark mode preference
2. **GTK application dark theme preference** - forces GTK apps to prefer dark themes
3. **Qt theme consistency** - ensures Qt apps follow the same theme

## Proposed Solution

Add the following to `/home/ncrmro/code/omarchy/omarchy-nix/modules/home-manager/default.nix`:

```nix
gtk = {
  enable = true;
  theme = {
    name = if config.omarchy.theme == "generated_light"
           then "Adwaita" 
           else "Adwaita:dark";
    package = pkgs.gnome-themes-extra;
  };
  # Force GTK applications to prefer dark theme
  gtk3.extraConfig = {
    gtk-application-prefer-dark-theme = true;
  };
  gtk4.extraConfig = {
    gtk-application-prefer-dark-theme = true;
  };
};

# Set consistent dark theme across all toolkits
dconf.settings = {
  "org/gnome/desktop/interface" = {
    color-scheme = if config.omarchy.theme == "generated_light"
                   then "default"
                   else "prefer-dark";
    gtk-theme = if config.omarchy.theme == "generated_light"
                then "Adwaita"
                else "Adwaita:dark";
  };
};
```

## Expected Results After Fix
- XDG desktop portal will report `color-scheme: 1` (dark mode)
- All applications will consistently respect dark mode preference
- Qt applications will follow the dark theme
- Chrome and other browsers will maintain dark mode consistency

## Testing Steps
1. Apply the configuration changes
2. Rebuild Home Manager: `home-manager switch --flake .#ncrmro@<hostname>`
3. Restart session or run: `systemctl --user restart xdg-desktop-portal`
4. Verify with: `dbus-send --session --print-reply --dest=org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop org.freedesktop.portal.Settings.Read string:'org.freedesktop.appearance' string:'color-scheme'`
5. Should return `uint32 1` for dark mode

## Alternative Approaches
If the above doesn't work, consider:
1. Adding explicit Qt theming configuration
2. Setting environment variables in the session
3. Configuring xdg-desktop-portal-gtk explicitly

## Files Involved
- `/home/ncrmro/code/omarchy/omarchy-nix/modules/home-manager/default.nix` - Main theme configuration
- `/home/ncrmro/code/omarchy/omarchy-nix/modules/themes.nix` - Theme definitions
- System environment variables and dconf settings