#!/usr/bin/env bash

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools.sh
source "$SCRIPTS_DIR/tools.sh"

link_yazi_configs() {
  local source_dir="$DOTFILES_DIR/yazi"
  local target_dir="$CONFIG_HOME/yazi"
  local current
  local file

  if [[ -L "$target_dir" ]]; then
    current="$(readlink "$target_dir")"
    if [[ "$current" == "$source_dir" ]]; then
      log "migrating Yazi from a directory link to individual config links"
      rm "$target_dir"
    else
      backup_existing "$target_dir" "$source_dir"
    fi
  fi

  ensure_dir "$target_dir"
  for file in yazi.toml keymap.toml theme.toml package.toml; do
    link_path "$source_dir/$file" "$target_dir/$file"
  done
}

install_yazi_packages() {
  local package_file="$CONFIG_HOME/yazi/package.toml"
  local checksum_file="$CONFIG_HOME/yazi/.package-checksum"
  local package_checksum

  package_checksum="$(cksum <"$package_file")"
  if [[ -d "$CONFIG_HOME/yazi/plugins/toggle-pane.yazi" &&
    -d "$CONFIG_HOME/yazi/flavors/catppuccin-mocha.yazi" &&
    -f "$checksum_file" &&
    "$(<"$checksum_file")" == "$package_checksum" ]]; then
    log "Yazi plugins and flavors are already installed"
    return
  fi

  ensure_git
  log "installing Yazi plugins and flavors"
  XDG_CONFIG_HOME="$CONFIG_HOME" ya pkg install

  [[ -d "$CONFIG_HOME/yazi/plugins/toggle-pane.yazi" ]] ||
    die "toggle-pane.yazi installation failed"
  [[ -d "$CONFIG_HOME/yazi/flavors/catppuccin-mocha.yazi" ]] ||
    die "Catppuccin Yazi flavor installation failed"

  printf '%s\n' "$package_checksum" >"$checksum_file"
}

install_yazi_config() {
  ensure_yazi
  link_yazi_configs
  install_yazi_packages
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  run_component install_yazi_config yazi
fi
