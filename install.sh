#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_SUFFIX="$(date +%Y%m%d%H%M%S)"

log() {
  printf '[install] %s\n' "$1"
}

warn() {
  printf '[install] warning: %s\n' "$1" >&2
}

detect_platform() {
  case "$(uname -s)" in
    Darwin)
      PLATFORM="macos"
      ;;
    Linux)
      if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "${ID:-}" in
          ubuntu)
            PLATFORM="ubuntu"
            ;;
          *)
            warn "detected Linux distribution '${ID:-unknown}', continuing with Ubuntu-compatible layout"
            PLATFORM="ubuntu"
            ;;
        esac
      else
        warn "unable to detect Linux distribution, continuing with Ubuntu-compatible layout"
        PLATFORM="ubuntu"
      fi
      ;;
    *)
      printf 'Unsupported platform: %s\n' "$(uname -s)" >&2
      exit 1
      ;;
  esac
}

ensure_dir() {
  mkdir -p "$1"
}

backup_existing() {
  local target="$1"

  if [[ -L "$target" ]]; then
    local current
    current="$(readlink "$target")"
    if [[ "$current" == "$2" ]]; then
      log "already linked: $target"
      return 1
    fi
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    local backup_target="${target}.backup.${BACKUP_SUFFIX}"
    log "backing up $target -> $backup_target"
    mv "$target" "$backup_target"
  fi

  return 0
}

link_path() {
  local source="$1"
  local target="$2"

  ensure_dir "$(dirname "$target")"

  if backup_existing "$target" "$source"; then
    ln -s "$source" "$target"
    log "linked $target -> $source"
  fi
}

install_yazi() {
  local source_dir="$SCRIPT_DIR/yazi"
  local target_dir="$CONFIG_HOME/yazi"

  if [[ ! -d "$source_dir" ]]; then
    warn "missing yazi config directory: $source_dir"
    return
  fi

  link_path "$source_dir" "$target_dir"
}

install_mihomo() {
  local source_file="$SCRIPT_DIR/mihomo/config.yaml"
  local target_dir="$CONFIG_HOME/mihomo"
  local target_file="$target_dir/config.yaml"

  if [[ ! -f "$source_file" ]]; then
    warn "missing mihomo config file: $source_file"
    return
  fi

  ensure_dir "$target_dir"
  ensure_dir "$target_dir/proxy_providers"
  ensure_dir "$target_dir/ruleset"
  ensure_dir "$target_dir/ui"

  link_path "$source_file" "$target_file"
}

print_summary() {
  cat <<EOF

Install completed for ${PLATFORM}.

Configured paths:
  - ${CONFIG_HOME}/yazi -> ${SCRIPT_DIR}/yazi
  - ${CONFIG_HOME}/mihomo/config.yaml -> ${SCRIPT_DIR}/mihomo/config.yaml

Notes:
  - Existing configs were backed up with suffix: .backup.${BACKUP_SUFFIX}
  - This script installs config links only. It does not install yazi, mihomo, tmux, vim, or code.
EOF
}

main() {
  detect_platform
  log "platform: ${PLATFORM}"
  log "config home: ${CONFIG_HOME}"

  install_yazi
  install_mihomo
  print_summary
}

main "$@"
