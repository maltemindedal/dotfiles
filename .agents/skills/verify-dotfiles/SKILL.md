---
name: verify-dotfiles
description: Verify the macOS/Windows dotfiles (zsh, Git config, install.sh, PowerShell profile). Runs the documented gate (tests/check.sh), shellcheck, install.sh's argument contract and, when pwsh exists, the PowerShell profile parse. Use before every commit or PR: this repo has no CI, so this is the only record of verification.
---

# verify-dotfiles

Surface: shell config a user installs with `./install.sh` and then lives in. There is no app to launch; the "drive" is the test suites (they install into a temp `$HOME` with stub `git`/`brew` and start zsh under `env -i`) plus the checks AGENTS.md lists for files the gate misses.

## Helper

`.agents/skills/verify-dotfiles/scripts/verify.sh <doctor|gate|lint|install|pwsh|cleanup|all>`, from anywhere in the repo. Evidence: `<name>.cmd/.stdout/.stderr/.exit` under `/tmp/dotfiles-verify/<run-id>/`. The last line is `RESULT: PASS (<step>)` only when every check passed, `RESULT: PASS with SKIP (...)` when a tool was missing, `RESULT: FAIL (...)` with exit 1 otherwise.

- `doctor` (read-only): `sh`, `zsh`, `git` present (needed); shellcheck optional.
- `gate`: `sh tests/check.sh` (zsh -n, both gitconfigs, install/zshrc/docs suites). Needs exit 0, `all checks passed`, no `FAIL` line. Takes 10 s to 2 min.
- `lint`: `shellcheck -S warning install.sh tests/*.sh` and this helper. SKIP without shellcheck (`apt-get install shellcheck` or `brew install shellcheck`; AGENTS.md has a Docker form).
- `install`: `install.sh --help` exits 0 with usage, an unknown flag exits 2 with usage on stderr. It never runs a real install: that would link into your `$HOME`.
- `pwsh`: parses `shell/Microsoft.PowerShell_profile.ps1`, expects `0` errors. SKIP without `pwsh`.
- `all`: doctor, then the rest. Doctor failing stops the run.

## Launch and cleanup

Nothing long-lived starts. The suites clean their own temp dirs; `cleanup` only reports where the evidence is. Never run `./install.sh` without `--help` against a real `$HOME` to verify: use `tests/install_test.sh`.

## Proof standard

Paste the `RESULT:` line and each check's PASS/SKIP into the PR body (AGENTS.md: the PR body is the only record). A SKIP is unverified, not a pass.

## Feature map

See `features/README.md`.
