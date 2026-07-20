#!/usr/bin/env bash

if [[ -n "${DOTFILES_LIB_LOADED:-}" ]]; then
  return
fi
DOTFILES_LIB_LOADED=1

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_SUFFIX="$(date +%Y%m%d%H%M%S)"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

log() {
  printf '[install] %s\n' "$1"
}

warn() {
  printf '[install] warning: %s\n' "$1" >&2
}

die() {
  printf '[install] error: %s\n' "$1" >&2
  exit 1
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
            warn "detected Linux distribution '${ID:-unknown}', using Ubuntu-compatible layout"
            PLATFORM="ubuntu"
            ;;
        esac
      else
        warn "unable to detect Linux distribution, using Ubuntu-compatible layout"
        PLATFORM="ubuntu"
      fi
      ;;
    *)
      die "unsupported platform: $(uname -s)"
      ;;
  esac
}

initialize_install() {
  detect_platform
  log "platform: $PLATFORM"
  log "config home: $CONFIG_HOME"
}

ensure_dir() {
  mkdir -p "$1"
}

backup_existing() {
  local target="$1"
  local source="$2"

  if [[ -L "$target" ]]; then
    local current
    current="$(readlink "$target")"
    if [[ "$current" == "$source" ]]; then
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

  if [[ ! -e "$source" && ! -L "$source" ]]; then
    die "missing config path: $source"
  fi

  ensure_dir "$(dirname "$target")"
  if backup_existing "$target" "$source"; then
    ln -s "$source" "$target"
    log "linked $target -> $source"
  fi
}

run_component() {
  initialize_install
  "$1"
  log "$2 configuration completed"
}
