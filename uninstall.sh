#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$ROOT_DIR/scripts"

# shellcheck source=scripts/lib.sh
source "$SCRIPTS_DIR/lib.sh"

COMPONENTS="zsh tmux vim yazi mihomo vscode"
SELECTED=""
LAST_RESTORED=0

print_help() {
  cat <<EOF
Usage:
  ./uninstall.sh                     Interactive selection
  ./uninstall.sh all                 Restore every configuration
  ./uninstall.sh vim yazi            Restore selected configurations

Available configurations:
  zsh  tmux  vim  yazi  mihomo  vscode

This removes managed symlinks and restores the latest .backup.<timestamp>.
Installed applications, plugins, fonts, and runtime data are preserved.
EOF
}

add_component() {
  local component="$1"

  case " $SELECTED " in
    *" $component "*)
      ;;
    *)
      SELECTED="${SELECTED:+$SELECTED }$component"
      ;;
  esac
}

select_all() {
  local component
  for component in $COMPONENTS; do
    add_component "$component"
  done
}

parse_selection() {
  local selection="$1"
  local item

  for item in $selection; do
    case "$item" in
      1 | all)
        select_all
        ;;
      2 | zsh)
        add_component zsh
        ;;
      3 | tmux)
        add_component tmux
        ;;
      4 | vim)
        add_component vim
        ;;
      5 | yazi)
        add_component yazi
        ;;
      6 | mihomo)
        add_component mihomo
        ;;
      7 | vscode)
        add_component vscode
        ;;
      *)
        die "unknown configuration: $item"
        ;;
    esac
  done
}

prompt_selection() {
  local answer

  cat <<'EOF'
Choose configurations to restore (space-separated numbers or names):
  1) all
  2) zsh
  3) tmux
  4) vim
  5) yazi
  6) mihomo
  7) vscode
EOF
  printf 'Selection [all]: '
  read -r answer
  parse_selection "${answer:-all}"
}

latest_backup() {
  local target="$1"
  local backups

  shopt -s nullglob
  backups=("$target".backup.*)
  shopt -u nullglob

  ((${#backups[@]} > 0)) || return 1
  printf '%s\n' "${backups[@]}" | LC_ALL=C sort | tail -n 1
}

restore_path() {
  local source="$1"
  local target="$2"
  local current
  local backup=""

  LAST_RESTORED=0

  if [[ -L "$target" ]]; then
    current="$(readlink "$target")"
    if [[ "$current" == "$source" ]]; then
      rm "$target"
      log "removed managed link: $target"
    else
      warn "not touching unmanaged link: $target -> $current"
      return
    fi
  elif [[ -e "$target" ]]; then
    warn "not touching non-managed path: $target"
    return
  fi

  if backup="$(latest_backup "$target")"; then
    mv "$backup" "$target"
    LAST_RESTORED=1
    log "restored $target from $backup"
  else
    log "no previous backup for $target"
  fi
}

uninstall_zsh_config() {
  restore_path "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
}

uninstall_tmux_config() {
  restore_path "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
}

uninstall_vim_config() {
  restore_path "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"
}

uninstall_yazi_config() {
  local source_dir="$DOTFILES_DIR/yazi"
  local target_dir="$CONFIG_HOME/yazi"
  local file
  local restored_file=0
  local directory_backup=""
  local preserved_dir

  for file in yazi.toml keymap.toml theme.toml package.toml; do
    restore_path "$source_dir/$file" "$target_dir/$file"
    if ((LAST_RESTORED == 1)); then
      restored_file=1
    fi
  done

  if ((restored_file == 0)) &&
    directory_backup="$(latest_backup "$target_dir")"; then
    if [[ -e "$target_dir" || -L "$target_dir" ]]; then
      preserved_dir="${target_dir}.uninstalled.${BACKUP_SUFFIX}"
      mv "$target_dir" "$preserved_dir"
      log "preserved Yazi runtime data: $preserved_dir"
    fi
    mv "$directory_backup" "$target_dir"
    log "restored $target_dir from $directory_backup"
  fi
}

uninstall_mihomo_config() {
  restore_path \
    "$DOTFILES_DIR/mihomo/config.yaml" \
    "$CONFIG_HOME/mihomo/config.yaml"
}

uninstall_vscode_config() {
  local target_dir

  case "$PLATFORM" in
    macos)
      target_dir="$HOME/Library/Application Support/Code/User"
      ;;
    ubuntu)
      target_dir="$CONFIG_HOME/Code/User"
      ;;
  esac

  restore_path \
    "$DOTFILES_DIR/vscode/settings.json" \
    "$target_dir/settings.json"
}

uninstall_selected() {
  local component

  initialize_install
  log "selected: $SELECTED"

  for component in $SELECTED; do
    case "$component" in
      zsh)
        uninstall_zsh_config
        ;;
      tmux)
        uninstall_tmux_config
        ;;
      vim)
        uninstall_vim_config
        ;;
      yazi)
        uninstall_yazi_config
        ;;
      mihomo)
        uninstall_mihomo_config
        ;;
      vscode)
        uninstall_vscode_config
        ;;
    esac
  done

  cat <<EOF

Uninstall completed for ${PLATFORM}.
Processed: ${SELECTED}
Applications, plugins, fonts, and runtime data were not removed.
EOF
}

main() {
  if (($# == 0)); then
    if [[ -t 0 ]]; then
      prompt_selection
    else
      die "non-interactive use requires a configuration name or 'all'"
    fi
  else
    case "$1" in
      -h | --help)
        print_help
        return
        ;;
    esac
    parse_selection "$*"
  fi

  [[ -n "$SELECTED" ]] || die "no configuration selected"
  uninstall_selected
}

main "$@"
