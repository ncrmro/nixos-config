# Hyprland App Groups Spike

A shell script for automatically opening applications in specified Hyprland workspaces with group management.

## Features

- Launch multiple applications to specific workspaces
- Group applications for organized workflows
- Autostart support for groups on session start
- Window class detection for precise timing
- Dry-run mode for testing configurations
- Configurable delays between launches

## Installation

1. Copy the script to a location in your PATH:
```bash
cp hyprland-app-groups.sh ~/.local/bin/
chmod +x ~/.local/bin/hyprland-app-groups.sh
```

2. Copy the example configuration:
```bash
mkdir -p ~/.config
cp hyprland-app-groups.conf ~/.config/
```

3. Edit the configuration to match your applications and preferences.

## Usage

### Launch a specific group
```bash
hyprland-app-groups.sh launch development
```

### Launch all autostart groups
```bash
hyprland-app-groups.sh start
```

### List configured groups
```bash
hyprland-app-groups.sh list
```

### Dry run to see what would be executed
```bash
hyprland-app-groups.sh --dry-run launch development
```

### Use custom config file
```bash
hyprland-app-groups.sh --config ~/custom.conf launch media
```

## Configuration Format

The configuration file uses an INI-like format with pipe-separated values:

```
[group_name]
autostart = true|false
workspace | command | window_class | delay
```

- **workspace**: Hyprland workspace number (1-10) or special workspace name
- **command**: Shell command to launch the application
- **window_class**: (Optional) Window class to wait for before continuing
- **delay**: (Optional) Seconds to wait after launching (default: 0.5)

### Finding Window Classes

To find the window class of an application:
```bash
hyprctl clients | grep class
```

## Integration with Hyprland

### Manual Launch
Add keybindings to your Hyprland config:
```
bind = $mainMod SHIFT, D, exec, hyprland-app-groups.sh launch development
bind = $mainMod SHIFT, C, exec, hyprland-app-groups.sh launch communication
```

### Autostart on Session
Add to your Hyprland config:
```
exec-once = hyprland-app-groups.sh start
```

## Example Workflows

### Development Setup
Launches terminal, browser, code editor, and system monitor across workspaces 1-4.

### Communication Hub
Opens Slack and Discord on workspace 5, email client on workspace 6.

### Media Station
Sets up Spotify and audio controls on workspace 7, OBS on workspace 8.

### Productivity Suite
Opens note-taking apps on workspace 9, calendar on workspace 10.

## Tips

- Use `--verbose` flag for debugging launch issues
- Window class matching ensures apps are fully loaded before continuing
- Adjust delays based on your system's performance
- Special workspaces can be used for persistent monitoring tools
- Commands support shell features like environment variables and pipes

## NixOS Integration

To integrate with NixOS, you could:

1. Package the script as a Nix derivation
2. Add configuration through Home Manager
3. Create a NixOS module for system-wide configuration

Example Home Manager module structure:
```nix
programs.hyprland-app-groups = {
  enable = true;
  groups = {
    development = {
      autostart = true;
      apps = [
        { workspace = 1; command = "kitty"; class = "kitty"; }
        { workspace = 2; command = "firefox"; class = "firefox"; }
      ];
    };
  };
};
```