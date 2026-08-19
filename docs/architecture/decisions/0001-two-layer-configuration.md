# 0001 — Two-layer configuration: tracked file + untracked local include

Status: accepted · Date: 2026-08-19

## Context

The same `.zshrc` and `.gitconfig` are used on several machines (personal Mac, work machines, Windows). Some settings differ per host: the SSH `allowedSignersFile` path, Windows `ssh.exe`/`ssh-keygen.exe` program paths, API keys and work-specific aliases. Committing these would either leak secrets or force per-machine branches.

## Decision

Each tracked file loads an optional, untracked sibling from the home directory:

- `shell/.zshrc` → `[ -f ~/.zshrc.local ] && source ~/.zshrc.local`
- `git/.gitconfig` → `[include] path = ~/.gitconfig.local`

Values that must be identical everywhere stay in the tracked file; the signing key is stored as a literal public key (not a file path) for the same reason. `git/.gitconfig.windows` is a ready-made starting point for the Windows local file.

## Consequences

- The tracked files are byte-identical on every machine and `git pull` never conflicts with local state.
- Secrets never enter the repository.
- Two places to look when debugging a setting; documented in [Machine-specific overrides](../../guides/machine-specific-overrides.md).
