#!/bin/sh
# Run the whole gate: the syntax and parse checks, every tests/*_test.sh suite and
# tests/lint.sh. Prints ok or FAIL for each check, shows what a failing check
# printed (less its passing cases), and exits 1 if any check failed. Runs from any
# directory.
#
#   sh tests/check.sh
set -eu

CDPATH='' cd -- "$(dirname -- "$0")/.."
OUT="$(mktemp)"
trap 'rm -f "$OUT"' EXIT
fails=0

run() { # run <command...>
  if "$@" > "$OUT" 2>&1; then
    printf 'ok   %s\n' "$*"
  else
    printf 'FAIL %s\n' "$*"
    grep -v '^ok ' "$OUT" | sed 's/^/     /'
    fails=$((fails + 1))
  fi
}

run zsh -n shell/.zshrc
run git config -f git/.gitconfig -l
run git config -f git/.gitconfig.windows -l
for t in tests/*_test.sh; do run sh "$t"; done
run sh tests/lint.sh

echo
if [ "$fails" -eq 0 ]; then echo "all checks passed"; else echo "$fails check(s) failed"; exit 1; fi
