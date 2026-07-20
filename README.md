# dotfiles

Personal config files for a new machine bootstrap.

## Supported platforms

- macOS
- Ubuntu

## What gets installed

- `~/.zshrc` -> repo `zsh/.zshrc`
- `~/.tmux.conf` -> repo `tmux/.tmux.conf`
- `~/.vimrc` -> repo `vim/.vimrc`
- Yazi TOML files under `~/.config/yazi/` -> repo `yazi/`
- `~/.config/mihomo/config.yaml` -> repo `mihomo/config.yaml`
- VS Code Vim settings in `User/settings.json` -> repo `vscode/settings.json`

VS Code's user config directory is platform-specific:

- macOS: `~/Library/Application Support/Code/User/`
- Ubuntu: `~/.config/Code/User/`

`mihomo` runtime directories are created locally under `~/.config/mihomo/`:

- `proxy_providers/`
- `ruleset/`
- `ui/`

This avoids downloaded rule files and subscriptions polluting the repository.

## Usage

Run the unified installer without arguments for an interactive selection:

```bash
./install.sh
```

Install everything in one command:

```bash
./install.sh all
```

Install only selected configurations:

```bash
./install.sh vim yazi
```

Numbers shown in the interactive menu can also be passed as arguments:

```bash
./install.sh 4 5
```

Each component can also be run independently:

```bash
./scripts/install-zsh.sh
./scripts/install-tmux.sh
./scripts/install-vim.sh
./scripts/install-yazi.sh
./scripts/install-mihomo.sh
./scripts/install-vscode.sh
```

Shared linking and backup behavior lives in `scripts/lib.sh`; binary installation
helpers live in `scripts/tools.sh`.

## Uninstall and restore

Restore configurations from the latest timestamped backups:

```bash
# Interactive selection
./uninstall.sh

# Restore everything
./uninstall.sh all

# Restore only selected configurations
./uninstall.sh vim yazi
```

The uninstall script removes only symlinks managed by this repository. It does not
uninstall applications, Vim/Yazi plugins, fonts, or runtime data, and it does not
overwrite paths that were replaced or edited after installation.

If they are missing, the script installs:

- macOS: clipboard-enabled `vim`, `tmux`, `yazi`, `git`, and Node.js with Homebrew
- Ubuntu: `vim-gtk3` for system clipboard support and `tmux` with `apt`; `yazi`
  and `ya` from the latest official Yazi GitHub release into `~/.local/bin`
- An official Node.js LTS binary on Ubuntu when the installed Node.js is too old
  for `coc.nvim`

The script also installs:

- Vim plugins declared in `.vimrc` using vim-plug
- Yazi plugins and flavors locked in `package.toml` using `ya pkg install`
- Yazi's recommended Nerd Fonts Symbols Only font

On Ubuntu, the font and its fontconfig fallback configuration are installed under
the user's home directory and `fc-cache` is refreshed. When Yazi runs over SSH,
glyphs are rendered by the local terminal, so the font must also be installed on
the client machine.

Homebrew is installed automatically when it is needed. Ubuntu package installation
may request `sudo`; the Yazi binary installer supports `x86_64` and `aarch64`.
The installed Vim must be 9.0.0438 or newer for the current `coc.nvim` release;
Ubuntu 24.04 and newer provide a compatible `vim-gtk3`.

## Notes

- Existing files or symlinks at the target paths are backed up automatically with a timestamp suffix like `.backup.20260502123045`.
- The install script does not install `zsh`, `mihomo`, or `code`.
