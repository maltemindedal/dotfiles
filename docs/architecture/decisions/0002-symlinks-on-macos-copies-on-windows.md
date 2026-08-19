# 0002 — Symlinks on macOS, copies on Windows

Status: accepted · Date: 2026-08-19

## Context

The config files need to land in `$HOME`. Options were a symlink farm, copying files, or a dotfile manager (stow, chezmoi, bare-repo trick).

## Decision

- **macOS:** `ln -sfn` from the repo into `$HOME`, wrapped in [`install.sh`](../../../install.sh). Updating is `git pull`; nothing to sync.
- **Windows:** copy files (`Copy-Item`). Symlinks on Windows require Developer Mode or elevation, and the Windows surface is two files.
- No dotfile manager: the repo has six files and one target per file; a manager adds a dependency without removing any work.

## Consequences

- macOS changes are live instantly; editing `~/.zshrc` edits the repo (good for iteration, but `git status` shows it).
- Windows copies drift until re-copied; the [Windows guide](../../guides/windows-setup.md) is the update procedure.
- Revisit if the file count or platform set grows.
