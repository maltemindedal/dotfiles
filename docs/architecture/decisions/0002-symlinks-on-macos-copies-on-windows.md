# 0002. Symlinks on macOS and copies on Windows

- Status: accepted
- Date: 2026-08-19

## Context

The config files need to land in `$HOME`. Options were a symlink farm, copying files, or a dotfile manager (stow, chezmoi, bare-repo trick).

## Decision

- **macOS.** [`install.sh`](../../../install.sh) runs `ln -sfn` from the repository into `$HOME`. Run `git pull` to update the configuration. No separate sync step is needed.
- **Windows.** Use `Copy-Item` to copy configuration files into the home directory. Symlinks on Windows require Developer Mode or elevation.
- **No dotfile manager.** The repository has six files and one target per file. A manager would add a dependency without reducing the setup work.

## Consequences

- On macOS, changes take effect immediately because editing `~/.zshrc` edits the repository. `git status` shows those changes.
- Windows copies do not update with the repository. Follow the [Windows guide](../../guides/windows-setup.md) to copy them again.
- Reconsider this decision if the repository adds more files or platforms.
