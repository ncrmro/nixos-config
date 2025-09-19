#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/hyprland-app-groups.conf"
CONFIG_FILE=./hyprland-app-groups.conf
usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS] COMMAND

Automatically open applications in specified Hyprland workspaces.

COMMANDS:
    launch GROUP    Launch all applications in the specified group
    start          Launch all autostart groups
    list           List all configured groups
    help           Show this help message

OPTIONS:
    -c, --config FILE    Use custom config file (default: $CONFIG_FILE)
    -d, --dry-run       Show what would be executed without launching
    -v, --verbose       Enable verbose output
    -h, --help          Show this help message

EXAMPLES:
    $SCRIPT_NAME launch dev
    $SCRIPT_NAME --dry-run start
    $SCRIPT_NAME --config ~/custom.conf list

EOF
}

log() {
  [[ "${VERBOSE:-0}" == "1" ]] && echo "[INFO] $*" >&2
}

error() {
  echo "[ERROR] $*" >&2
  exit 1
}

launch_app() {
  local workspace="$1"
  local app_cmd="$2"
  local window_class="${3:-}"
  local delay="${4:-0.5}"

  log "Launching '$app_cmd' on workspace $workspace"

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "[DRY-RUN] Would execute: hyprctl dispatch workspace $workspace"
    echo "[DRY-RUN] Would execute: $app_cmd &"
    [[ -n "$window_class" ]] && echo "[DRY-RUN] Would wait for window class: $window_class"
    return
  fi

  hyprctl dispatch workspace "$workspace"

  eval "$app_cmd" &
  local pid=$!

  if [[ -n "$window_class" ]]; then
    log "Waiting for window class: $window_class"
    local attempts=0
    while ! hyprctl clients -j | jq -e ".[] | select(.class == \"$window_class\")" >/dev/null 2>&1; do
      sleep 0.1
      attempts=$((attempts + 1))
      if [[ $attempts -gt 100 ]]; then
        log "Warning: Timeout waiting for $window_class"
        break
      fi
    done
  fi

  sleep "$delay"
}

move_window_to_workspace() {
  local window_class="$1"
  local workspace="$2"

  log "Moving window class '$window_class' to workspace $workspace"

  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "[DRY-RUN] Would execute: hyprctl dispatch movetoworkspacesilent $workspace,class:$window_class"
    return
  fi

  hyprctl dispatch movetoworkspacesilent "$workspace,class:$window_class"
}

parse_config() {
  local config_file="$1"

  if [[ ! -f "$config_file" ]]; then
    error "Config file not found: $config_file"
  fi

  log "Parsing config file: $config_file"

  unset GROUPS GROUP_AUTOSTART
  declare -gA GROUPS
  declare -gA GROUP_AUTOSTART
  local current_group=""

  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(echo "$line" | xargs)"

    [[ -z "$line" ]] && continue

    if [[ "$line" =~ ^\[(.+)\]$ ]]; then
      current_group="${BASH_REMATCH[1]}"
      GROUPS["$current_group"]=""
      GROUP_AUTOSTART["$current_group"]="false"
      log "Found group: $current_group"
    elif [[ -n "$current_group" ]]; then
      if [[ "$line" =~ ^autostart[[:space:]]*=[[:space:]]*(.+)$ ]]; then
        GROUP_AUTOSTART["$current_group"]="${BASH_REMATCH[1]}"
      else
        GROUPS["$current_group"]+="$line"$'\n'
      fi
    fi
  done <"$config_file"
}

launch_group() {
  local group="$1"

  if [[ -z "${GROUPS[$group]:-}" ]]; then
    error "Group '$group' not found in configuration"
  fi

  echo "Launching group: $group"

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    IFS='|' read -r workspace app_cmd window_class delay <<<"$line"

    workspace="$(echo "$workspace" | xargs)"
    app_cmd="$(echo "$app_cmd" | xargs)"
    window_class="$(echo "${window_class:-}" | xargs)"
    delay="$(echo "${delay:-0.5}" | xargs)"

    launch_app "$workspace" "$app_cmd" "$window_class" "$delay"
  done <<<"${GROUPS[$group]}"

  echo "Group '$group' launched successfully"
}

launch_autostart_groups() {
  local launched=0

  for group in "${!GROUPS[@]}"; do
    if [[ "${GROUP_AUTOSTART[$group]}" == "true" ]]; then
      echo "Auto-starting group: $group"
      launch_group "$group"
      launched=$((launched + 1))
    fi
  done

  if [[ $launched -eq 0 ]]; then
    echo "No autostart groups configured"
  else
    echo "Launched $launched autostart group(s)"
  fi
}

list_groups() {
  if [[ ${#GROUPS[@]} -eq 0 ]]; then
    echo "No groups configured"
    return
  fi

  echo "Configured groups:"
  for group in "${!GROUPS[@]}"; do
    local autostart="${GROUP_AUTOSTART[$group]}"
    local app_count=$(echo -n "${GROUPS[$group]}" | grep -c '^')
    echo "  - $group (apps: $app_count, autostart: $autostart)"
  done
}

main() {
  local config_file="$CONFIG_FILE"
  local command=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -c | --config)
      config_file="$2"
      shift 2
      ;;
    -d | --dry-run)
      DRY_RUN=1
      shift
      ;;
    -v | --verbose)
      VERBOSE=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    launch | start | list | help)
      command="$1"
      shift
      break
      ;;
    *)
      error "Unknown option: $1"
      ;;
    esac
  done

  if [[ -z "$command" ]]; then
    usage
    exit 1
  fi

  parse_config "$config_file"

  case "$command" in
  launch)
    [[ -z "${1:-}" ]] && error "Group name required"
    launch_group "$1"
    ;;
  start)
    launch_autostart_groups
    ;;
  list)
    list_groups
    ;;
  help)
    usage
    ;;
  *)
    error "Unknown command: $command"
    ;;
  esac
}

main "$@"

