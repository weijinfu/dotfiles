#!/usr/bin/env bash

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPTS_DIR/lib.sh"

install_zsh_config() {
  link_path "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  run_component install_zsh_config zsh
fi
