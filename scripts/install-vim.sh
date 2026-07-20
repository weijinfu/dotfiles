#!/usr/bin/env bash

set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools.sh
source "$SCRIPTS_DIR/tools.sh"

install_vim_plugins() {
  local plug_file="$HOME/.vim/autoload/plug.vim"

  ensure_curl
  ensure_git
  ensure_node

  if [[ ! -f "$plug_file" ]]; then
    ensure_dir "$(dirname "$plug_file")"
    log "installing vim-plug"
    curl -fL --retry 3 \
      -o "$plug_file" \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi

  log "installing Vim plugins"
  vim -Nu "$HOME/.vimrc" -n -es -i NONE \
    -c 'PlugInstall --sync' \
    -c 'qa'

  [[ -d "$HOME/.vim/plugged/catppuccin" ]] ||
    die "catppuccin Vim plugin installation failed"
  [[ -d "$HOME/.vim/plugged/vim-airline" ]] ||
    die "vim-airline installation failed"
  [[ -d "$HOME/.vim/plugged/coc.nvim" ]] ||
    die "coc.nvim installation failed"
}

install_vim_config() {
  ensure_vim
  link_path "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"
  install_vim_plugins
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  run_component install_vim_config vim
fi
