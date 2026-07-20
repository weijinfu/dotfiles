#!/usr/bin/env bash

if [[ -n "${DOTFILES_TOOLS_LOADED:-}" ]]; then
  return
fi
DOTFILES_TOOLS_LOADED=1

# shellcheck source=lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

APT_UPDATED=0

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    BREW_BIN="$(command -v brew)"
    return
  fi

  command -v curl >/dev/null 2>&1 ||
    die "curl is required to install Homebrew"

  log "installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    BREW_BIN="/opt/homebrew/bin/brew"
  elif [[ -x /usr/local/bin/brew ]]; then
    BREW_BIN="/usr/local/bin/brew"
  else
    die "Homebrew installation completed but brew was not found"
  fi
}

brew_install() {
  ensure_homebrew
  log "installing with Homebrew: $*"
  "$BREW_BIN" install "$@"
}

run_apt_get() {
  if ((EUID == 0)); then
    apt-get "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo apt-get "$@"
  else
    die "sudo is required to install Ubuntu packages"
  fi
}

apt_install() {
  if ((APT_UPDATED == 0)); then
    log "updating apt package metadata"
    run_apt_get update
    APT_UPDATED=1
  fi
  log "installing with apt: $*"
  run_apt_get install -y "$@"
}

ensure_curl() {
  if command -v curl >/dev/null 2>&1; then
    return
  fi

  case "$PLATFORM" in
    macos)
      die "curl is required but is not available"
      ;;
    ubuntu)
      apt_install curl
      ;;
  esac
}

ensure_git() {
  if git --version >/dev/null 2>&1; then
    return
  fi

  case "$PLATFORM" in
    macos)
      brew_install git
      ;;
    ubuntu)
      apt_install git
      ;;
  esac

  git --version >/dev/null 2>&1 || die "git installation failed"
}

vim_has_clipboard() {
  command -v vim >/dev/null 2>&1 &&
    vim --version 2>/dev/null | grep -q '+clipboard'
}

vim_is_coc_compatible() {
  command -v vim >/dev/null 2>&1 &&
    vim -Nu NONE -n -es -i NONE \
      -c 'if !has("patch-9.0.0438") | cq | endif' \
      -c 'qa'
}

vim_is_ready() {
  vim_has_clipboard && vim_is_coc_compatible
}

ensure_vim() {
  if vim_is_ready; then
    log "compatible clipboard-enabled Vim is already installed"
    return
  fi

  case "$PLATFORM" in
    macos)
      brew_install vim
      ;;
    ubuntu)
      apt_install vim-gtk3
      ;;
  esac

  vim_has_clipboard || die "vim installation lacks +clipboard support"
  vim_is_coc_compatible ||
    die "coc.nvim requires Vim 9.0.0438 or newer"
}

ensure_tmux() {
  if command -v tmux >/dev/null 2>&1; then
    log "tmux is already installed"
    return
  fi

  case "$PLATFORM" in
    macos)
      brew_install tmux
      ;;
    ubuntu)
      apt_install tmux
      ;;
  esac

  command -v tmux >/dev/null 2>&1 || die "tmux installation failed"
}

node_is_compatible() {
  command -v node >/dev/null 2>&1 &&
    node -e '
      const [major, minor] = process.versions.node.split(".").map(Number);
      process.exit(major > 16 || (major === 16 && minor >= 18) ? 0 : 1);
    ' >/dev/null 2>&1
}

install_node_ubuntu() {
  local version
  local arch
  local target
  local temp_dir
  local archive
  local install_root
  local install_dir

  ensure_curl
  command -v xz >/dev/null 2>&1 || apt_install xz-utils

  version="$(
    curl -fsSL https://nodejs.org/dist/index.tab |
      awk -F '\t' '
        NR > 1 && $10 != "-" && $10 != "" && version == "" { version = $1 }
        END { print version }
      '
  )"
  [[ -n "$version" ]] || die "failed to determine the current Node.js LTS version"

  case "$(uname -m)" in
    x86_64)
      arch="x64"
      ;;
    aarch64 | arm64)
      arch="arm64"
      ;;
    *)
      die "Node.js automatic install does not support architecture: $(uname -m)"
      ;;
  esac

  target="node-${version}-linux-${arch}"
  temp_dir="$(mktemp -d)"
  archive="$temp_dir/node.tar.xz"
  install_root="$HOME/.local/lib/nodejs"
  install_dir="$install_root/$target"

  log "downloading official Node.js LTS ${version} for ${arch}"
  if ! curl -fL --retry 3 \
    -o "$archive" \
    "https://nodejs.org/dist/${version}/${target}.tar.xz"; then
    rm -rf "$temp_dir"
    die "failed to download Node.js"
  fi

  if ! tar -xJf "$archive" -C "$temp_dir"; then
    rm -rf "$temp_dir"
    die "failed to extract Node.js"
  fi

  ensure_dir "$install_root"
  ensure_dir "$HOME/.local/bin"
  if [[ ! -d "$install_dir" ]]; then
    mv "$temp_dir/$target" "$install_dir"
  fi
  ln -sfn "$install_dir/bin/node" "$HOME/.local/bin/node"
  ln -sfn "$install_dir/bin/npm" "$HOME/.local/bin/npm"
  ln -sfn "$install_dir/bin/npx" "$HOME/.local/bin/npx"
  rm -rf "$temp_dir"

  export PATH="$HOME/.local/bin:$PATH"
  log "installed Node.js ${version} in $install_dir"
}

ensure_node() {
  if node_is_compatible; then
    log "compatible Node.js is already installed"
    return
  fi

  case "$PLATFORM" in
    macos)
      brew_install node
      ;;
    ubuntu)
      install_node_ubuntu
      ;;
  esac

  node_is_compatible ||
    die "Node.js 16.18 or newer is required by coc.nvim"
}

install_yazi_ubuntu() {
  local arch
  local target
  local temp_dir
  local archive
  local extracted_dir

  ensure_curl
  command -v unzip >/dev/null 2>&1 || apt_install unzip

  case "$(uname -m)" in
    x86_64)
      arch="x86_64"
      ;;
    aarch64 | arm64)
      arch="aarch64"
      ;;
    *)
      die "Yazi automatic install does not support architecture: $(uname -m)"
      ;;
  esac

  target="yazi-${arch}-unknown-linux-gnu"
  temp_dir="$(mktemp -d)"
  archive="$temp_dir/yazi.zip"
  extracted_dir="$temp_dir/$target"

  log "downloading the latest official Yazi release for ${arch}"
  if ! curl -fL --retry 3 \
    -o "$archive" \
    "https://github.com/sxyazi/yazi/releases/latest/download/${target}.zip"; then
    rm -rf "$temp_dir"
    die "failed to download Yazi"
  fi

  if ! unzip -q "$archive" -d "$temp_dir"; then
    rm -rf "$temp_dir"
    die "failed to extract Yazi"
  fi

  ensure_dir "$HOME/.local/bin"
  install -m 0755 "$extracted_dir/yazi" "$HOME/.local/bin/yazi"
  install -m 0755 "$extracted_dir/ya" "$HOME/.local/bin/ya"
  rm -rf "$temp_dir"

  export PATH="$HOME/.local/bin:$PATH"
  log "installed yazi and ya in $HOME/.local/bin"
}

ensure_yazi() {
  if command -v yazi >/dev/null 2>&1 &&
    command -v ya >/dev/null 2>&1; then
    log "yazi and ya are already installed"
    return
  fi

  case "$PLATFORM" in
    macos)
      brew_install yazi
      ;;
    ubuntu)
      install_yazi_ubuntu
      ;;
  esac

  command -v yazi >/dev/null 2>&1 || die "yazi installation failed"
  command -v ya >/dev/null 2>&1 || die "Yazi CLI installation failed"
}
