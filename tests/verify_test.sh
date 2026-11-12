#!/bin/sh
# Tests for .agents/skills/verify-dotfiles/scripts/verify.sh. A stub shellcheck on
# PATH fails on any file argument that does not exist, so the cases check which
# files verify.sh hands to shellcheck without needing shellcheck. Needs bash.
#
#   sh tests/verify_test.sh
set -eu

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fails=0

pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }

if ! command -v bash >/dev/null; then
  pass "verify.sh: skipped, no bash"
  exit 0
fi

mkdir "$TMP/bin"
cat > "$TMP/bin/shellcheck" <<'EOF'
#!/bin/sh
while [ $# -gt 0 ]; do
  case $1 in
    -S) shift ;;
    -*) ;;
    *) [ -f "$1" ] || { echo "$1: does not exist" >&2; exit 2; } ;;
  esac
  shift
done
EOF
chmod +x "$TMP/bin/shellcheck"

# From each subdirectory, run verify.sh lint by a relative path, as a contributor does.
for dir in tests shell docs; do
  rel=../.agents/skills/verify-dotfiles/scripts/verify.sh
  if (cd "$REPO/$dir" && env -i HOME="$TMP" PATH="$TMP/bin:/usr/bin:/bin" \
    DOTFILES_VERIFY_ARTIFACTS="$TMP/art-$dir" bash "$rel" lint) > "$TMP/out" 2>&1; then
    pass "verify.sh lint: passes when run from $dir/"
  else
    fail "verify.sh lint: passes when run from $dir/ (resolve paths before cd): $(grep -h . "$TMP/art-$dir"/lint.stderr 2>/dev/null | head -1)"
  fi
done

echo
if [ "$fails" -eq 0 ]; then echo "all verify.sh tests passed"; else echo "$fails verify.sh test(s) failed"; exit 1; fi
