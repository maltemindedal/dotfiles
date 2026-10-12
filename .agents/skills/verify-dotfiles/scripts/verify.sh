#!/usr/bin/env bash
# Verify the dotfiles the way a contributor does (there is no CI), and keep the evidence.
# Usage: verify.sh <doctor|gate|lint|install|pwsh|cleanup|all>
set -uo pipefail

SELF="$(CDPATH="" cd -- "$(dirname -- "$0")" && pwd)/$(basename -- "$0")"
ROOT="$(git -C "$(dirname "$SELF")" rev-parse --show-toplevel)"
RUN_ID="${DOTFILES_VERIFY_RUN:-$(date +%Y%m%d-%H%M%S)}"
ART="${DOTFILES_VERIFY_ARTIFACTS:-/tmp/dotfiles-verify/$RUN_ID}"
mkdir -p "$ART"
cd "$ROOT" || exit 1

run() {
  local name="$1"; shift
  printf '%q ' "$@" > "$ART/$name.cmd"; echo >> "$ART/$name.cmd"
  "$@" > "$ART/$name.stdout" 2> "$ART/$name.stderr"
  local rc=$?
  echo "$rc" > "$ART/$name.exit"
  echo "[$name] exit=$rc  ($ART/$name.*)"
  return "$rc"
}
expect() {
  local desc="$1" file="$2" pattern="$3"
  if grep -qE -- "$pattern" "$file"; then echo "  PASS $desc"; else echo "  FAIL $desc (no /$pattern/ in $file)"; FAILED=1; fi
}
FAILED=0
SKIPPED=0
skip() { echo "  SKIP $1"; echo "$1" > "$ART/$2.skip"; SKIPPED=1; }

doctor() {
  echo "artifacts: $ART"
  echo "repo: $ROOT @ $(git rev-parse --short HEAD) ($(git rev-parse --abbrev-ref HEAD))"
  local t ok=0
  for t in sh zsh git; do
    if command -v "$t" >/dev/null; then echo "  PASS $t present"; else echo "  FAIL $t missing (tests/check.sh needs it)"; ok=1; fi
  done
  command -v shellcheck >/dev/null && echo "  PASS shellcheck $(shellcheck --version | sed -n 's/^version: //p')" || echo "  WARN shellcheck missing: lint will SKIP"
  return "$ok"
}

# The whole documented gate (AGENTS.md): syntax checks plus every test suite.
gate() {
  run gate sh tests/check.sh || FAILED=1
  expect "tests/check.sh exits 0" "$ART/gate.exit" "^0$"
  expect "tests/check.sh says all checks passed" "$ART/gate.stdout" "^all checks passed$"
  if grep -q "^FAIL" "$ART/gate.stdout"; then echo "  FAIL a check printed FAIL"; FAILED=1; fi
}

# The extra check AGENTS.md lists for files the gate misses, run natively instead of in Docker.
lint() {
  command -v shellcheck >/dev/null || { skip "lint: shellcheck not installed" lint; return; }
  run lint shellcheck -S warning install.sh tests/*.sh "$SELF" || FAILED=1
  expect "shellcheck -S warning is clean" "$ART/lint.exit" "^0$"
}

# install.sh's argument contract, the part a user hits before anything is linked.
# The linking itself is driven by tests/install_test.sh (temp HOME, stub git/brew) inside `gate`.
install() {
  run install-help sh install.sh --help; expect "--help exits 0" "$ART/install-help.exit" "^0$"
  expect "--help prints usage" "$ART/install-help.stdout" "^usage: .*install.sh \[--tools\]"
  run install-bad sh install.sh --nope; expect "unknown flag exits 2" "$ART/install-bad.exit" "^2$"
  expect "unknown flag prints usage on stderr" "$ART/install-bad.stderr" "^usage:"
}

pwsh_check() {
  command -v pwsh >/dev/null || { skip "pwsh: PowerShell not installed; shell/Microsoft.PowerShell_profile.ps1 is not parsed (AGENTS.md has the Docker command)" pwsh; return; }
  run pwsh pwsh -NoProfile -Command '$t=$null;$e=$null;[void][System.Management.Automation.Language.Parser]::ParseFile("shell/Microsoft.PowerShell_profile.ps1",[ref]$t,[ref]$e);$e.Count'
  expect "PowerShell profile parses with 0 errors" "$ART/pwsh.stdout" "^0$"
}

cleanup() { echo "cleanup done (nothing long-lived started; the test suites remove their temp HOMEs); evidence kept in $ART"; }

case "${1:-}" in
  doctor) doctor || FAILED=1 ;;
  gate) gate ;;
  lint) lint ;;
  install) install ;;
  pwsh) pwsh_check ;;
  cleanup) cleanup ;;
  all) if doctor; then gate; lint; install; pwsh_check; else FAILED=1; echo "  doctor failed: not driving this checkout"; fi; cleanup ;;
  *) sed -n '2,3p' "$0"; exit 2 ;;
esac
if [ "$FAILED" != 0 ]; then echo "RESULT: FAIL ($1)"; elif [ "$SKIPPED" != 0 ]; then echo "RESULT: PASS with SKIP ($1): skipped features are unverified"; else echo "RESULT: PASS ($1)"; fi
exit "$FAILED"
