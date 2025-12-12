{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.keystone.desktop;
  hyprlandPkg = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

  # Screen recording script
  keystoneScreenrecord = pkgs.writeShellScriptBin "keystone-screenrecord" ''
    [[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
    OUTPUT_DIR="''${KEYSTONE_SCREENRECORD_DIR:-''${XDG_VIDEOS_DIR:-$HOME/Videos}}"

    if [[ ! -d "$OUTPUT_DIR" ]]; then
      ${pkgs.libnotify}/bin/notify-send "Screen recording directory does not exist: $OUTPUT_DIR" -u critical -t 3000
      exit 1
    fi

    screenrecording() {
      filename="$OUTPUT_DIR/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"
      ${pkgs.libnotify}/bin/notify-send "Screen recording starting..." -t 1000
      sleep 1

      if ${pkgs.pciutils}/bin/lspci | grep -qi 'nvidia'; then
        ${pkgs.wf-recorder}/bin/wf-recorder -f "$filename" -c libx264 -p crf=23 -p preset=medium -p movflags=+faststart "$@"
      else
        ${pkgs.wl-screenrec}/bin/wl-screenrec -f "$filename" --ffmpeg-encoder="-c:v libx264 -crf 23 -preset medium -movflags +faststart" "$@"
      fi
    }

    if ${pkgs.procps}/bin/pgrep -x wl-screenrec >/dev/null || ${pkgs.procps}/bin/pgrep -x wf-recorder >/dev/null; then
      ${pkgs.procps}/bin/pkill -x wl-screenrec
      ${pkgs.procps}/bin/pkill -x wf-recorder
      ${pkgs.libnotify}/bin/notify-send "Screen recording saved to $OUTPUT_DIR" -t 2000
    elif [[ "$1" == "output" ]]; then
      screenrecording
    else
      region=$(${pkgs.slurp}/bin/slurp) || exit 1
      screenrecording -g "$region"
    fi
  '';

  # Audio switch script
  keystoneAudioSwitch = pkgs.writeShellScriptBin "keystone-audio-switch" ''
    focused_monitor="$(${hyprlandPkg}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true).name')"

    sinks=$(${pkgs.pulseaudio}/bin/pactl -f json list sinks | ${pkgs.jq}/bin/jq '[.[] | select((.ports | length == 0) or ([.ports[]? | .availability != "not available"] | any))]')
    sinks_count=$(echo "$sinks" | ${pkgs.jq}/bin/jq '. | length')

    if [ "$sinks_count" -eq 0 ]; then
      ${pkgs.swayosd}/bin/swayosd-client \
        --monitor "$focused_monitor" \
        --custom-message "No audio devices found"
      exit 1
    fi

    current_sink_name=$(${pkgs.pulseaudio}/bin/pactl get-default-sink)
    current_sink_index=$(echo "$sinks" | ${pkgs.jq}/bin/jq -r --arg name "$current_sink_name" 'map(.name) | index($name)')

    if [ "$current_sink_index" != "null" ]; then
      next_sink_index=$(((current_sink_index + 1) % sinks_count))
    else
      next_sink_index=0
    fi

    next_sink=$(echo "$sinks" | ${pkgs.jq}/bin/jq -r ".[$next_sink_index]")
    next_sink_name=$(echo "$next_sink" | ${pkgs.jq}/bin/jq -r '.name')

    next_sink_description=$(echo "$next_sink" | ${pkgs.jq}/bin/jq -r '.description')
    if [ "$next_sink_description" = "(null)" ] || [ "$next_sink_description" = "null" ] || [ -z "$next_sink_description" ]; then
      sink_id=$(echo "$next_sink" | ${pkgs.jq}/bin/jq -r '.properties."object.id"')
      next_sink_description=$(${pkgs.wireplumber}/bin/wpctl status | grep -E "\s+\*?\s+''${sink_id}\." | sed -E 's/^.*[0-9]+\.\s+//' | sed -E 's/\s+\[.*$//')
    fi

    next_sink_volume=$(echo "$next_sink" | ${pkgs.jq}/bin/jq -r \
      '.volume | to_entries[0].value.value_percent | sub("%"; "")')
    next_sink_is_muted=$(echo "$next_sink" | ${pkgs.jq}/bin/jq -r '.mute')

    if [ "$next_sink_is_muted" = "true" ] || [ "$next_sink_volume" -eq 0 ]; then
      icon_state="muted"
    elif [ "$next_sink_volume" -le 33 ]; then
      icon_state="low"
    elif [ "$next_sink_volume" -le 66 ]; then
      icon_state="medium"
    else
      icon_state="high"
    fi

    next_sink_volume_icon="sink-volume-''${icon_state}-symbolic"

    if [ "$next_sink_name" != "$current_sink_name" ]; then
      ${pkgs.pulseaudio}/bin/pactl set-default-sink "$next_sink_name"
    fi

    ${pkgs.swayosd}/bin/swayosd-client \
      --monitor "$focused_monitor" \
      --custom-message "$next_sink_description" \
      --custom-icon "$next_sink_volume_icon"
  '';

  # Idle toggle script
  keystoneIdleToggle = pkgs.writeShellScriptBin "keystone-idle-toggle" ''
    if ${pkgs.procps}/bin/pgrep -x hypridle > /dev/null; then
      ${pkgs.procps}/bin/pkill -x hypridle
      ${pkgs.libnotify}/bin/notify-send "󰅶  Idle inhibitor enabled" "Screen will not lock automatically"
    else
      setsid ${pkgs.uwsm}/bin/uwsm app -- ${pkgs.hypridle}/bin/hypridle &
      ${pkgs.libnotify}/bin/notify-send "󰾪  Idle inhibitor disabled" "Screen will lock after timeout"
    fi
  '';

  # Nightlight toggle script
  keystoneNightlightToggle = pkgs.writeShellScriptBin "keystone-nightlight-toggle" ''
    ON_TEMP=4000
    OFF_TEMP=6000

    if ! ${pkgs.procps}/bin/pgrep -x hyprsunset; then
      setsid ${pkgs.uwsm}/bin/uwsm app -- ${pkgs.hyprsunset}/bin/hyprsunset &
      sleep 1
    fi

    CURRENT_TEMP=$(${hyprlandPkg}/bin/hyprctl hyprsunset temperature 2>/dev/null | grep -oE '[0-9]+')

    if [[ "$CURRENT_TEMP" == "$OFF_TEMP" ]]; then
      ${hyprlandPkg}/bin/hyprctl hyprsunset temperature $ON_TEMP
      ${pkgs.libnotify}/bin/notify-send "  Nightlight screen temperature"
    else
      ${hyprlandPkg}/bin/hyprctl hyprsunset temperature $OFF_TEMP
      ${pkgs.libnotify}/bin/notify-send "   Daylight screen temperature"
    fi
  '';

  # Walker launcher wrapper for menus
  keystoneLaunchWalker = pkgs.writeShellScriptBin "keystone-launch-walker" (
    builtins.readFile ./keystone-launch-walker.sh
  );

  # Main menu script
  keystoneMenu = pkgs.writeShellScriptBin "keystone-menu" (builtins.readFile ./keystone-menu.sh);

  # Keybindings viewer script
  keystoneMenuKeybindings = pkgs.writeShellScriptBin "keystone-menu-keybindings" (
    builtins.readFile ./keystone-menu-keybindings.sh
  );

  # Battery monitor script
  keystoneBatteryMonitor = pkgs.writeShellScriptBin "keystone-battery-monitor" ''
    BATTERY_THRESHOLD=10
    NOTIFICATION_FLAG="/run/user/$UID/keystone_battery_notified"

    # Get battery level
    BATTERY_LEVEL=$(${pkgs.upower}/bin/upower -i $(${pkgs.upower}/bin/upower -e | grep 'BAT') | grep -E "percentage" | awk '{print $2}' | tr -d '%')
    BATTERY_STATE=$(${pkgs.upower}/bin/upower -i $(${pkgs.upower}/bin/upower -e | grep 'BAT') | grep -E "state" | awk '{print $2}')

    send_notification() {
      ${pkgs.libnotify}/bin/notify-send -u critical " Time to recharge!" "Battery is down to ''${1}%" -i battery-caution -t 30000
    }

    if [[ -n "$BATTERY_LEVEL" && "$BATTERY_LEVEL" =~ ^[0-9]+$ ]]; then
      if [[ $BATTERY_STATE == "discharging" && $BATTERY_LEVEL -le $BATTERY_THRESHOLD ]]; then
        if [[ ! -f $NOTIFICATION_FLAG ]]; then
          send_notification $BATTERY_LEVEL
          touch $NOTIFICATION_FLAG
        fi
      else
        rm -f $NOTIFICATION_FLAG
      fi
    fi
  '';
in
{
  config = mkIf cfg.enable {
    home.packages = [
      keystoneScreenrecord
      keystoneAudioSwitch
      keystoneIdleToggle
      keystoneNightlightToggle
      keystoneBatteryMonitor
      keystoneLaunchWalker
      keystoneMenu
      keystoneMenuKeybindings
      # Dependencies that should be available
      pkgs.wf-recorder
      pkgs.wl-screenrec
      pkgs.libxkbcommon # for xkbcli in keybindings menu
      pkgs.hypridle
    ];
  };
}
