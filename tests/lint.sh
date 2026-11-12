#!/bin/sh
# Lints the conventions in AGENTS.md that a test suite cannot see: the commits on
# this branch and host-specific paths in the tracked config. The commit checks
# cover origin/main..HEAD and pass with a note when there is no origin/main.
# Needs git.
#
#   sh tests/lint.sh
set -eu

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$REPO"
fails=0

pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }

AREAS='shell git install.sh test docs agents'

# --- Host paths: the tracked config runs on every machine ---
hosts=$(git ls-files shell git | while IFS= read -r f; do
  [ -f "$f" ] && grep -nH -e /Users/ -e /home/ "$f" || true
done)
if [ -n "$hosts" ]; then
  fail "no /Users/ or /home/ paths under shell/ and git/ (use \$HOME, or ~/.zshrc.local and ~/.gitconfig.local):
$hosts"
else
  pass "no /Users/ or /home/ paths under shell/ and git/"
fi

# --- Commits on this branch ---
if ! git rev-parse --verify -q origin/main >/dev/null; then
  pass "commits: skipped, no origin/main"
else
  RANGE="$(git merge-base origin/main HEAD)..HEAD"
  area_re=$(printf '%s' "$AREAS" | sed 's/\./\\./g; s/ /|/g')
  bad_subjects=
  untested=
  for c in $(git rev-list --no-merges "$RANGE"); do
    subject=$(git log -1 --format=%s "$c")
    printf '%s\n' "$subject" | grep -Eq "^($area_re): [a-z].*[^.]\$" ||
      bad_subjects="$bad_subjects
  $(git rev-parse --short "$c") $subject"
    case $(git log -1 --format=%b "$c" | head -1) in
      "Bug fix (docs"*) ;;
      "Bug fix"*)
        git diff-tree --no-commit-id --name-only -r "$c" | grep -q '^tests/' ||
          untested="$untested
  $(git rev-parse --short "$c") $subject" ;;
    esac
  done
  if [ -n "$bad_subjects" ]; then
    fail "commits: subjects are <area>: <lowercase imperative> with no final period, area one of: $AREAS$bad_subjects"
  else
    pass "commits: subjects are <area>: <lowercase imperative> with no final period"
  fi
  if [ -n "$untested" ]; then
    fail "commits: a Bug fix commit adds its regression test under tests/$untested"
  else
    pass "commits: a Bug fix commit adds its regression test under tests/"
  fi
fi

echo
if [ "$fails" -eq 0 ]; then echo "all lint checks passed"; else echo "$fails lint check(s) failed"; exit 1; fi
