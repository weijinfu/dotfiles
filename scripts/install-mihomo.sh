#!/usr/bin/env bash

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPTS_DIR/lib.sh"

install_mihomo_config() {
  local source_file="$DOTFILES_DIR/mihomo/config.yaml"
  local target_dir="$CONFIG_HOME/mihomo"

  ensure_dir "$target_dir"
  ensure_dir "$target_dir/proxy_providers"
  ensure_dir "$target_dir/ruleset"
  ensure_dir "$target_dir/ui"
  link_path "$source_file" "$target_dir/config.yaml"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  run_component install_mihomo_config mihomo
fi
