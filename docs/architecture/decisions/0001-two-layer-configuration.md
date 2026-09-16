# 0001. Tracked configuration with an untracked local include

- Status: accepted
- Date: 2026-08-19

## Context

Several macOS and Windows machines use the tracked configuration. Some settings differ by host. These include the SSH `allowedSignersFile` path, Windows `ssh.exe` and `ssh-keygen.exe` paths, API keys, and work-specific aliases. Committing these settings would leak secrets or require a branch for each machine.

## Decision

Each tracked file loads an optional, untracked sibling from the home directory:

- `shell/.zshrc` loads `~/.zshrc.local` when the local file exists.
- `git/.gitconfig` includes `~/.gitconfig.local`.

Values that must be identical everywhere stay in the tracked file. `.gitconfig` stores the signing key as a literal public key instead of a file path for the same reason. `git/.gitconfig.windows` is a starting point for the Windows local file.

## Consequences

- The tracked files are byte-identical on every machine and `git pull` never conflicts with local state.
- Secrets never enter the repository.
- Debugging a setting requires checking both files. [Machine-specific overrides](../../guides/machine-specific-overrides.md) documents them.
