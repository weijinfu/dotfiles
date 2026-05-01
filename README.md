# dotfiles

Personal config files for a new machine bootstrap.

## Supported platforms

- macOS
- Ubuntu

## What gets installed

- `~/.config/yazi` -> repo `yazi/`
- `~/.config/mihomo/config.yaml` -> repo `mihomo/config.yaml`

`mihomo` runtime directories are created locally under `~/.config/mihomo/`:

- `proxy_providers/`
- `ruleset/`
- `ui/`

This avoids downloaded rule files and subscriptions polluting the repository.

## Usage

Clone the repo, then run:

```bash
chmod +x install.sh
./install.sh
```

## Notes

- Existing files or symlinks at the target paths are backed up automatically with a timestamp suffix like `.backup.20260502123045`.
- The install script only links config files. It does not install binaries such as `yazi`, `mihomo`, `tmux`, `vim`, or `code`.
