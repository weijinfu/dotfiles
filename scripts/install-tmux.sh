#!/usr/bin/env bash

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools.sh
source "$SCRIPTS_DIR/tools.sh"

install_tmux_config() {
  ensure_tmux
  link_path "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  run_component install_tmux_config tmux
fi
