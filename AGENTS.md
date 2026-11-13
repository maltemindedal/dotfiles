# AGENTS.md

Personal zsh, Git, SSH, Starship, PowerShell, Claude Code, Codex and Cursor CLI config. On macOS `install.sh` symlinks it into `$HOME` and merges the Codex and Cursor CLI files, so this repo is the owner's live setup. Every change must keep shell startup at exit 0 with none of the optional tools installed, keep Git identity and signing working, and never lose a user file.

## Commands

There is no CI. `sh tests/check.sh` is the whole gate before every commit and PR. It runs `zsh -n` on `shell/.zshrc` and `shell/.zprofile`, `git config -l` on both gitconfigs, every `tests/*_test.sh` suite and `tests/lint.sh`, then prints `ok` or `FAIL` per check and exits 1 on any failure.

- A new `tests/<name>_test.sh` joins the gate without editing `check.sh`. Each suite keeps its fixtures in its own temporary directory. `DOTFILES_TEST_JOBS=1` runs the checks one at a time (default 4, range 1 to 16).
- To see all of one check's output, run it alone, such as `sh tests/zshrc_test.sh`. Suites have no per-case filter.
- To start the real shell with the real tools: `ZDOTDIR="$PWD/shell" TERM=dumb zsh -i -c exit; echo "exit $?"; rm -f shell/.zcompdump`. Expect exit 0. Two `can't change option: zle` lines and Starship's `TERM=dumb` error are normal.
- No zsh on a Linux container: `apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::=--force-confold install -y zsh`.
- Checks the gate misses (both need Docker):
  - shellcheck for `install.sh` and `tests/*.sh`: `docker run --rm -v "$PWD:/mnt:ro" -w /mnt koalaman/shellcheck:stable -S warning install.sh tests/*.sh`
  - Parse `shell/Microsoft.PowerShell_profile.ps1` and expect `0`: `docker run --rm --platform linux/amd64 -v "$PWD:/repo:ro" mcr.microsoft.com/powershell:latest pwsh -NoProfile -Command '$t=$null;$e=$null;[void][System.Management.Automation.Language.Parser]::ParseFile("/repo/shell/Microsoft.PowerShell_profile.ps1",[ref]$t,[ref]$e);$e.Count'`
- `.agents/skills/verify-dotfiles/scripts/verify.sh all` runs all of the above natively (skipping missing tools) and saves evidence under `/tmp/dotfiles-verify/`. Project skills live in `.agents/skills/`, never `.cursor/skills/`.

## Conventions

- **Commits:** subject `<area>: <imperative, lowercase, no final period>`, with the area from `AREAS` in `tests/lint.sh`. The body says why. A bug fix adds a regression test under `tests/`, and its body opens with `Bug fix.` (or `Bug fix (docs).`, `Bug fix (data loss).`) and ends with `The new regression tests fail without this change.` One logical change per commit, each passing the gate. Never commit on `main`.
- **PRs:** title in commit-subject form. Nobody reviews and nothing runs in CI, so list each check you ran and its result in the PR body.
- **A behaviour change ships in one commit with its test and its docs.** These change together:
  - `shell/.zshrc`: a case in `tests/zshrc_test.sh`, the keybinding table in `docs/reference/zsh.md`, and `docs/architecture/overview.md` when the rationale or startup cost changes.
  - `shell/.zprofile`: a case in `tests/zprofile_test.sh` and the login shell section of `docs/reference/zsh.md`.
  - `install.sh`: `tests/install_test.sh`, `docs/getting-started.md` and the installation text in `README.md`.
  - A link target in `install.sh`: `links_ok` and the link and backup counts in `tests/install_test.sh`, step 2 of `docs/getting-started.md`, the layouts in `docs/architecture/overview.md` and `README.md`, and `docs/guides/windows-setup.md` for files Windows also uses.
  - A merged file in `install.sh` (`merge toml|json`): the merge cases in `tests/install_test.sh`, the `cp -n` line in step 2 of `docs/getting-started.md`, the `merged into` line in `docs/architecture/overview.md` and the `README.md` layout. Track only keys the user sets, not keys the app writes itself.
  - The `brew install` list: the identical string in `tests/install_test.sh` and `docs/getting-started.md`, plus the optional-tool lists in `README.md` and `docs/reference/zsh.md`.
  - `claude/cloud-setup.sh`: `tests/claude_cloud_setup_test.sh`.
  - `agents/AGENTS.md` or `claude/pstack-models.md`: the matching heredoc in `claude/cloud-setup.sh` (the test compares them byte for byte).
  - The `attribution` or `includeCoAuthoredBy` values in `claude/settings.json`: the jq filter in `disable_attribution` in `claude/cloud-setup.sh`.
  - The check list in `CONTRIBUTING.md`: `.github/pull_request_template.md`.
  - A new doc: its Diátaxis section in `docs/README.md` and the Documentation table in `README.md`.
  - The table layout of `docs/reference/*.md`, steps 2 and 4 of `docs/getting-started.md` or the layout in `docs/architecture/overview.md`: the parsing in `tests/docs_test.sh`, which checks those tables against the config.
- **`.zshrc` must survive Claude Code's shell snapshot**, which sources `~/.zshrc` non-interactively and copies its aliases and functions into agent shells. Keep aliases, completions and anything that writes to stderr inside `if [[ -o interactive ]]`, and keep copied functions free of helpers and `compdef`; `tests/snapshot_test.sh` enforces this. Guard every optional tool or file with `command -v X >/dev/null` or `[ -f … ]`.
- **Shell scripts** are POSIX `sh` with `set -eu` and must run under macOS `/bin/sh` (bash 3.2) and Debian's dash. In `install.sh`, check arguments before any side effect, and move a file already at a target to `<name>.<timestamp>.bak`, never delete it.
- **Prose** is British English (behaviour, initialise, colour; US spelling only in code identifiers such as `list-colors`), in short active sentences, with no em dashes.
- **Check external facts before writing them.** Confirm a tool's flags or behaviour against upstream docs or by running it.
- **Vendored files stay verbatim.** `shell/starship.toml` is Starship's plain-text-symbols preset (pinned at `tests/fixtures/starship-plain-text-symbols.toml`), then a marker line and the `claude_cost` and `claude_model` symbols. `tests/starship_test.sh` fails on any other change. To refresh it, update the fixture with `starship preset plain-text-symbols`, then the file. `CODE_OF_CONDUCT.md` is Contributor Covenant 3.0 with only the reporting contact filled in.
- Record a non-obvious design choice in the Design decisions section of `docs/architecture/overview.md`.

## Gotchas

- **The checkout `install.sh` linked is the live system** (`readlink ~/.zshrc`, normally `~/Developer/dotfiles`). Edits, checkouts, stashes and merges there take effect in the next shell and `git` call. Work in a worktree or another clone.
- **Never run `./install.sh` without asking.** Run from a worktree, it repoints `~/.zshrc`, `~/.gitconfig` and `~/.claude/settings.json` there, and they dangle once the worktree is removed. It also rewrites `~/.codex/config.toml` and `~/.cursor/cli-config.json`, and `--tools` runs `brew install`. Use `sh tests/install_test.sh` to exercise it.
- **Writes to `$HOME` dotfiles land in this repo.** `git config --global` writes into `git/.gitconfig`; put host-specific or secret keys in `~/.gitconfig.local`. Tool installers that append to `~/.zshrc` edit `shell/.zshrc`, and Claude Code's `/config` and permission changes edit `claude/settings.json`. Check `git -C ~/Developer/dotfiles status` after installing a tool.
- **Security changes: name them in the PR body.** These are edits to `claude/settings.json` (the live permissions and sandbox config of every Claude Code agent on this machine) and to the `~/.ssh` steps of `install.sh`. Those steps link `ssh/config`, append the owner's signer line to `~/.ssh/allowed_signers` and may set `gpg.ssh.allowedSignersFile` in `~/.gitconfig.local`. Never link, replace or reorder `allowed_signers`, and keep every email other than the one in `git/.gitconfig` out of the repo.
- **The repo owns the keys in `codex/config.toml` and `cursor/cli-config.json`.** The next `./install.sh` reverts a tracked key changed in the app, so change it here.
- **`tests/zshrc_test.sh` failing about six cases on macOS** usually means Homebrew's `share/` is group-writable, so compaudit aborts compinit. Check `ls -ld "$(brew --prefix)/share"`. The fix, `chmod go-w "$(brew --prefix)/share"`, changes the host, so ask first.
- **There is no `.gitignore`.** Remove stray outputs you create. Keep `git/.gitignore_global` to OS and editor files, because it is the global ignore for every repo.
- **Kept on purpose, do not "fix":** hard-coded macOS paths (`/opt/homebrew/…`, `/usr/bin/ssh-add --apple-load-keychain`, `$HOME/Library/pnpm`; Linux support was dropped), `$PNPM_HOME/bin` on `PATH`, user directories first on `PATH`, `compinit -C` skipping compaudit for 24 hours, `eval "$(tool init zsh)"`, and `Invoke-Expression` in the PowerShell profile. Before proposing version pins, a CI workflow, a startup-speed tweak or hardening, read PR #2's body (`gh pr view 2 -R maltemindedal/dotfiles`).
- Before changing load order, startup cost or how files reach `$HOME`, or choosing between a tracked file and `~/.zshrc.local` / `~/.gitconfig.local`, read the Design decisions in `docs/architecture/overview.md`.

## Cloud environments

- **Claude Code cloud** runs only the setup script pasted into the environment, a copy of `claude/cloud-setup.sh`. After editing that script, or a file it mirrors, tell the owner to paste it into the environment again. It is bash without `set -e` on purpose: a failed step prints a skip line and the script still exits 0, so it never blocks a session. Keep secrets out of it, because the environment stores it in plain text.
- **Cursor Cloud** runs `sh .cursor/cloud-install.sh`, which installs `zsh` and `shellcheck` from apt and `pwsh` only on amd64 Ubuntu 22.04 and 24.04 (`verify.sh` skips the PowerShell parse elsewhere). Do not add version pins or a CI workflow to it. `tests/cloud_install_test.sh` checks the host classification.
