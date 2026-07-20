#!/usr/bin/env bash

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPTS_DIR/lib.sh"

install_vscode_config() {
  local target_dir

  case "$PLATFORM" in
    macos)
      target_dir="$HOME/Library/Application Support/Code/User"
      ;;
    ubuntu)
      target_dir="$CONFIG_HOME/Code/User"
      ;;
  esac

  link_path "$DOTFILES_DIR/vscode/settings.json" "$target_dir/settings.json"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  run_component install_vscode_config vscode
fi
