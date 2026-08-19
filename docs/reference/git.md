# Git reference

Source of truth: [`git/.gitconfig`](../../git/.gitconfig), [`git/.gitconfig.windows`](../../git/.gitconfig.windows), [`git/.gitignore_global`](../../git/.gitignore_global).

## `.gitconfig` (installed as `~/.gitconfig`)

| Key | Value | Effect |
|-----|-------|--------|
| `user.name` | `Malte Mindedal` | Commit author |
| `user.email` | `112257731+maltemindedal@users.noreply.github.com` | GitHub no-reply address |
| `user.signingkey` | `ssh-ed25519 AAAA…` (literal public key) | Signing key; a literal key rather than a path so the file is portable |
| `gpg.format` | `ssh` | Sign with SSH instead of GPG |
| `commit.gpgsign` | `true` | Sign every commit |
| `tag.gpgsign` | `true` | Sign every tag |
| `init.defaultBranch` | `main` | Default branch for `git init` |
| `push.autoSetupRemote` | `true` | First `git push` sets upstream automatically |
| `fetch.prune` | `true` | Remove stale remote-tracking branches on fetch |
| `credential "https://github.com".helper` | `` (reset) then `!gh auth git-credential` | Use GitHub CLI for credentials |
| `credential "https://gist.github.com".helper` | `` (reset) then `!gh auth git-credential` | Same, for gists |
| `include.path` | `~/.gitconfig.local` | Machine-specific overrides (see below) |

Not set here but required for signing to verify locally: `gpg.ssh.allowedSignersFile` — put it in `~/.gitconfig.local`.

## `.gitconfig.windows` (copied to `~/.gitconfig.local` on Windows)

| Key | Value | Effect |
|-----|-------|--------|
| `core.sshCommand` | `ssh.exe` | Use Windows OpenSSH for transport |
| `gpg.ssh.program` | `ssh-keygen.exe` | Use Windows OpenSSH for signing |

## `.gitignore_global` (installed as `~/.gitignore_global`)

Activate with `git config --global core.excludesfile ~/.gitignore_global` (or set `core.excludesfile` in `~/.gitconfig.local`). Scope is OS and editor junk only; project artifacts belong in per-project `.gitignore` files.

| Group | Patterns |
|-------|----------|
| macOS | `.DS_Store`, `.AppleDouble`, `.LSOverride`, `._*`, `.Spotlight-V100`, `.Trashes` |
| Windows | `Thumbs.db`, `ehthumbs.db`, `desktop.ini` |
| Editors / IDEs | `.vscode/`, `.idea/`, `*.iml`, `*.sublime-workspace`, `*.swp`, `*.swo`, `*~` |
| Local env / secrets | `.env.local` |
