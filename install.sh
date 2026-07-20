#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$ROOT_DIR/scripts"

# shellcheck source=scripts/lib.sh
source "$SCRIPTS_DIR/lib.sh"
# shellcheck source=scripts/install-zsh.sh
source "$SCRIPTS_DIR/install-zsh.sh"
# shellcheck source=scripts/install-tmux.sh
source "$SCRIPTS_DIR/install-tmux.sh"
# shellcheck source=scripts/install-vim.sh
source "$SCRIPTS_DIR/install-vim.sh"
# shellcheck source=scripts/install-yazi.sh
source "$SCRIPTS_DIR/install-yazi.sh"
# shellcheck source=scripts/install-mihomo.sh
source "$SCRIPTS_DIR/install-mihomo.sh"
# shellcheck source=scripts/install-vscode.sh
source "$SCRIPTS_DIR/install-vscode.sh"

COMPONENTS="zsh tmux vim yazi mihomo vscode"
SELECTED=""

print_help() {
  cat <<EOF
Usage:
  ./install.sh                     Interactive selection
  ./install.sh all                 Install every configuration
  ./install.sh vim yazi            Install selected configurations

Available configurations:
  zsh  tmux  vim  yazi  mihomo  vscode
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
Choose configurations (space-separated numbers or names):
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

install_selected() {
  local component

  initialize_install
  log "selected: $SELECTED"

  for component in $SELECTED; do
    case "$component" in
      zsh)
        install_zsh_config
        ;;
      tmux)
        install_tmux_config
        ;;
      vim)
        install_vim_config
        ;;
      yazi)
        install_yazi_config
        ;;
      mihomo)
        install_mihomo_config
        ;;
      vscode)
        install_vscode_config
        ;;
    esac
  done

  cat <<EOF

Install completed for ${PLATFORM}.
Configured: ${SELECTED}
Existing paths were backed up with suffix: .backup.${BACKUP_SUFFIX}
EOF
}

main() {
  if (($# == 0)); then
    if [[ -t 0 ]]; then
      prompt_selection
    else
      select_all
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
  install_selected
}

main "$@"
