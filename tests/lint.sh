#!/bin/sh
# Lints the conventions in AGENTS.md that a test suite cannot see: the commits on
# this branch, commits made on main, and host-specific paths in the tracked
# config. The commit checks cover origin/main..HEAD and pass with a note when
# there is no origin/main. Needs git.
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
hosts=$(git ls-files shell git claude codex cursor | while IFS= read -r f; do
  [ -f "$f" ] && grep -nH -e /Users/ -e /home/ "$f" || true
done)
if [ -n "$hosts" ]; then
  fail "no /Users/ or /home/ paths under shell/, git/, claude/, codex/ and cursor/ (use \$HOME, or ~/.zshrc.local and ~/.gitconfig.local):
$hosts"
else
  pass "no /Users/ or /home/ paths under shell/, git/, claude/, codex/ and cursor/"
fi

# --- Commits on this branch ---
if ! git rev-parse --verify -q origin/main >/dev/null; then
  pass "commits: skipped, no origin/main"
else
  if [ "$(git rev-parse --abbrev-ref HEAD)" = main ] && [ -n "$(git rev-list -1 origin/main..HEAD)" ]; then
    fail "commits: commit on a branch, not on main (main is ahead of origin/main; move the commits to a branch and open a PR)"
  else
    pass "commits: not ahead of origin/main on main"
  fi
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
