# AGENTS.md

Personal zsh, Git, Starship and PowerShell config. On macOS `install.sh` symlinks it into `$HOME`, so this repo is the owner's live shell and Git setup: a change must keep shell startup at exit 0 with none of the optional tools installed, keep Git identity and signing working, and never lose a user file.

## Commands

There is no CI and `main` has no required checks, so these four commands are the whole gate before every commit and PR. Run them from the repo root:

```sh
zsh -n shell/.zshrc
git config -f git/.gitconfig -l
sh tests/install_test.sh          # seconds; temp $HOME, stub git and brew, no network
sh tests/zshrc_test.sh            # 10 s to 2 min; temp $HOME, env -i, PATH=/usr/bin:/bin
```

- The suites are linear scripts with no filter, so there is no single-test form.
- The checklist's `reload` is an alias, and agent shells get none of `.zshrc`'s aliases. To start the shell with the real tools instead: `ZDOTDIR="$PWD/shell" TERM=dumb zsh -i -c exit; echo "exit $?"; rm -f shell/.zcompdump`. Expect exit 0; two `can't change option: zle` lines and Starship's `TERM=dumb` error are normal, and the `rm` removes the completion dump zsh writes into `$ZDOTDIR`.
- No zsh (Linux cloud container): `apt-get install -y zsh`; both suites then pass on Debian.
- Extra checks for files the four commands miss:
  - `git/.gitconfig.windows`: `git config -f git/.gitconfig.windows -l`
  - `install.sh`, `tests/*.sh` (needs Docker): `docker run --rm -v "$PWD:/mnt:ro" -w /mnt koalaman/shellcheck:stable -S warning install.sh tests/*.sh`. Default severity also reports a pre-existing SC2012 info in `tests/install_test.sh`.
  - `shell/Microsoft.PowerShell_profile.ps1` has no test; parse it (needs Docker, 460 MB amd64 image) and expect `0`: `docker run --rm --platform linux/amd64 -v "$PWD:/repo:ro" mcr.microsoft.com/powershell:latest pwsh -NoProfile -Command '$t=$null;$e=$null;[void][System.Management.Automation.Language.Parser]::ParseFile("/repo/shell/Microsoft.PowerShell_profile.ps1",[ref]$t,[ref]$e);$e.Count'`

## Conventions

- **Commits:** subject `<area>: <imperative, lowercase, no final period>` with area `shell`, `git`, `install.sh`, `test`, `docs` or `agents`. The body says why. A bug fix adds a regression test, its body opens with `Bug fix.` (or `Bug fix (docs).`, `Bug fix (data loss).`) and ends with `The new regression tests fail without this change.` One logical change per commit, each passing the gate.
- **PRs:** title in commit-subject form, merged with squash (the convention since #3). Nobody reviews and nothing runs in CI, so the PR body is the only record of verification: list each check you ran and its result.
- **A behaviour change ships in one commit with its test and its docs.** These change together:
  - `shell/.zshrc`: a case in `tests/zshrc_test.sh` and `docs/reference/zsh.md`, which lists every alias, keybinding, option, env var and optional tool; `docs/architecture/overview.md` too when the rationale or startup cost changes.
  - Any file in `git/`: `docs/reference/git.md`, which lists every key and ignore pattern.
  - `install.sh`: `tests/install_test.sh`, `docs/getting-started.md` and the installation text in `README.md`.
  - A link target in `install.sh`: `links_ok` and the link and backup counts in `tests/install_test.sh`, step 2 of `docs/getting-started.md`, the layouts in `docs/architecture/overview.md` and `README.md`, and `docs/guides/windows-setup.md` for files Windows also uses.
  - The `brew install` list: the identical string in `tests/install_test.sh` and `docs/getting-started.md`, plus the optional-tool lists in `README.md` and `docs/reference/zsh.md`.
  - The check list in `CONTRIBUTING.md`: `.github/pull_request_template.md`.
  - A new doc: its Diátaxis section in `docs/README.md` and the Documentation table in `README.md`.
- **`.zshrc` must survive Claude Code's shell snapshot**, which sources `~/.zshrc` non-interactively and copies its aliases and functions one by one into agent shells. This has broken agent shells four times, from `npm` recursing until FUNCNEST to `gs` shadowing Ghostscript. So:
  - aliases, completion scripts and anything that calls `compdef` go inside `if [[ -o interactive ]]`;
  - a function is self-contained (no helper functions) and unsets itself before loading what it wraps, as `nvm()` does;
  - every optional tool or file is guarded with `command -v X >/dev/null` or `[ -f … ]`.
- **Shell scripts** are POSIX `sh` with `set -eu`, and run under macOS `/bin/sh` (bash 3.2) and Debian's dash. New steps in `install.sh` keep its two guarantees: arguments are checked before any side effect, and a file already at a target is moved to `<name>.<timestamp>.bak`, never deleted.
- **Prose** is British English (behaviour, initialise, colour; US spelling only in code identifiers such as `list-colors`), in short active sentences, with no em dashes.
- **Check external facts before writing them.** Confirm a tool's flags or behaviour against upstream docs or by running it; three past commits corrected docs that contradicted the config or upstream.
- **Vendored files stay verbatim:** `shell/starship.toml` is Starship's no-nerd-font preset (`starship preset no-nerd-font | diff - shell/starship.toml` prints nothing), and `CODE_OF_CONDUCT.md` is Contributor Covenant 3.0 with only the reporting contact filled in.
- Record a non-obvious design choice as an ADR in `docs/architecture/decisions/`, in the format of the existing two.

## Gotchas

- **The checkout `install.sh` linked is the live system.** `readlink ~/.zshrc` shows it, normally `~/Developer/dotfiles`. Uncommitted edits, `git checkout`, `git stash` and merges there reach the next shell and `git` call at once. Work in a worktree or another clone, so changes go live only when `main` is pulled into that checkout.
- **Run `./install.sh` only in the live checkout, and ask first.** It links `$HOME` to its own directory, so run from a worktree it repoints `~/.zshrc` and `~/.gitconfig` there, and they dangle once the worktree is removed. `--tools` also runs `brew install` and a `chmod`. To exercise the installer, run `sh tests/install_test.sh`.
- **Writes to `$HOME` dotfiles land in this repo.** `git config --global` writes into `git/.gitconfig`; put host-specific or secret keys in `~/.gitconfig.local` with `git config --file ~/.gitconfig.local`. Tool installers that append to `~/.zshrc` edit `shell/.zshrc` (the bun installer added a hard-coded `/Users/…` line after Starship), so check `git -C ~/Developer/dotfiles status` after installing a tool.
- **`tests/zshrc_test.sh` failing about six cases on macOS** usually means Homebrew's `share/` is group-writable, so compaudit aborts compinit. Check `ls -ld "$(brew --prefix)/share"` before touching `.zshrc`. The fix, `chmod go-w "$(brew --prefix)/share"`, changes the host, so ask first.
- **The repo has no `.gitignore`**, so stray outputs show up in `git status`; remove the ones you created. Keep `git/.gitignore_global` to OS and editor files: it is the global ignore for every repo, and a build pattern there would hide tracked files such as `*.sql` everywhere.
- **Deliberate choices that PR #2 reviewed and kept:** hard-coded macOS paths (`/opt/homebrew/…`, `/usr/bin/ssh-add --apple-load-keychain`, `$HOME/Library/pnpm`; Linux support was dropped), `$PNPM_HOME/bin` on `PATH` (the pnpm 11+ layout), user directories first on `PATH`, `compinit -C` skipping compaudit for 24 hours, `eval "$(tool init zsh)"`, and `Invoke-Expression` in the PowerShell profile.

## Docs

- Before changing load order, startup cost or how files are installed, read `docs/architecture/overview.md`.
- Before deciding whether a setting belongs in a tracked file or in `~/.zshrc.local` / `~/.gitconfig.local`, read `docs/architecture/decisions/0001-two-layer-configuration.md`.
- Before changing how files reach `$HOME`, or proposing a dotfile manager, read `docs/architecture/decisions/0002-symlinks-on-macos-copies-on-windows.md`.
- Before proposing version pins, a CI workflow, a startup-speed tweak or hardening, read PR #2's body (`gh pr view 2 -R maltemindedal/dotfiles`): it holds the open decisions and what was considered and kept.
