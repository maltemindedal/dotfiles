# AGENTS.md

- This repo is just source dotfile fragments.
- There is no bootstrap tool, package manager manifest, CI workflow, or task runner.
- Edit files in place; do not assume stow/chezmoi/install scripts exist.
- Directory intent mirrors the target home-directory files:
  - `git/` -> `.gitconfig`, `.gitignore_global`
  - `shell/` -> `.zshrc`, `Microsoft.PowerShell_profile.ps1`, `starship.toml`
  - `settings/` -> `settings.json` (VS Code user settings)
- `shell/.zshrc` manually sources plugins from `~/.zsh/plugins/...`, loads `~/.local/bin/env`, and optionally appends machine-local overrides from `~/.zshrc.local`.
- Preserve those hooks instead of replacing them with a plugin manager or in-repo secrets.
- SSH/Git settings are intentionally cross-platform: `.zshrc` exports the 1Password agent socket and aliases `ssh*` commands to `*.exe`, while `git/.gitconfig` sets `ssh.exe`, `ssh-keygen.exe`, and SSH commit signing. Keep shell and git changes aligned.
- `shell/.zshrc` comments say Starship should be last, but the executable source of truth initializes Starship **before** the NVM block. Preserve the current order unless you are intentionally changing shell startup behavior.
- `settings/settings.json` is JSONC with comments and a large Copilot/chat terminal permission allowlist. Do not rewrite it as strict JSON or "simplify" the permission block without a verified reason.
- There is no repo-wide automated verification harness.
- From the repo root, use focused checks for touched files instead:
  - `git config -f git/.gitconfig --list >/dev/null`
  - `pwsh -NoProfile -Command "[void][scriptblock]::Create((Get-Content -Raw 'shell/Microsoft.PowerShell_profile.ps1'))"` if PowerShell is available
  - `zsh -n shell/.zshrc` if zsh is available
