#!/bin/sh
# Run the whole gate: the syntax and parse checks, every tests/*_test.sh suite and
# tests/lint.sh. Prints ok or FAIL for each check, shows what a failing check
# printed (less its passing cases), and exits 1 if any check failed. Runs from any
# directory.
#
#   sh tests/check.sh
set -eu

CDPATH='' cd -- "$(dirname -- "$0")/.."
# Each suite owns its temporary HOME. Bound concurrency and give every check its
# own log; collect in launch order so diagnostics stay readable and repeatable.
JOBS=${DOTFILES_TEST_JOBS:-4}
case $JOBS in
  [1-9]|1[0-6]) ;;
  *) echo 'DOTFILES_TEST_JOBS must be an integer from 1 to 16' >&2; exit 2 ;;
esac
OUT="$(mktemp -d)"
trap 'wait; rm -rf "$OUT"' EXIT
trap 'exit 1' HUP INT TERM
fails=0
launched=0
collected=0

collect() {
  collected=$((collected + 1))
  wait "$(cat "$OUT/$collected.pid")"
  cat "$OUT/$collected.report"
  if [ -f "$OUT/$collected.failed" ]; then fails=$((fails + 1)); fi
}

run() { # run <command...>
  launched=$((launched + 1))
  (
    if "$@" > "$OUT/$launched.log" 2>&1; then
      printf 'ok   %s\n' "$*"
    else
      touch "$OUT/$launched.failed"
      printf 'FAIL %s\n' "$*"
      grep -v '^ok ' "$OUT/$launched.log" | sed 's/^/     /'
    fi
  ) > "$OUT/$launched.report" &
  echo "$!" > "$OUT/$launched.pid"
  if [ "$((launched - collected))" -ge "$JOBS" ]; then collect; fi
}

run zsh -n shell/.zshrc
run zsh -n shell/.zprofile
run git config -f git/.gitconfig -l
run git config -f git/.gitconfig.windows -l
for t in tests/*_test.sh; do run sh "$t"; done
run sh tests/lint.sh
while [ "$collected" -lt "$launched" ]; do collect; done

echo
if [ "$fails" -eq 0 ]; then echo "all checks passed"; else echo "$fails check(s) failed"; exit 1; fi
