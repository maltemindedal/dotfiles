#!/bin/sh
# Checks that shell/starship.toml is Starship's plain-text-symbols preset plus
# the claude_cost and claude_model symbols below a marker line. Needs awk.
# With starship installed it also notes when the pinned preset has gone stale.
#
#   sh tests/starship_test.sh
set -eu

CDPATH='' cd -- "$(dirname -- "$0")/.."
FILE=${STARSHIP_TOML:-shell/starship.toml}
FIXTURE=tests/fixtures/starship-plain-text-symbols.toml
MARKER='# ---- Local additions: keep everything above this line identical to tests/fixtures/starship-plain-text-symbols.toml ----'
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fail=0

n=$(grep -nxF -- "$MARKER" "$FILE" | cut -d: -f1 | head -n 1 || true)
if [ -z "$n" ]; then
  echo "FAIL $FILE has no marker line. Fix: copy $FIXTURE to $FILE, then append the marker line (see this script) and the local additions."
  exit 1
fi

# The marker is preceded by one blank separator line.
head -n $((n - 2)) "$FILE" > "$TMP/above"
tail -n +$((n + 1)) "$FILE" > "$TMP/below"

if cmp -s "$TMP/above" "$FIXTURE"; then
  echo "ok   text above the marker equals $FIXTURE"
else
  echo "FAIL $FILE above the marker differs from $FIXTURE:"
  diff "$FIXTURE" "$TMP/above" | head -n 20 | sed 's/^/     /'
  echo "     Fix: replace everything above the marker with the contents of $FIXTURE."
  echo "     To adopt a newer preset, update the fixture first: starship preset plain-text-symbols > $FIXTURE"
  fail=1
fi

awk '
  /^[[:space:]]*(#|$)/ { next }
  /^\[/ { table = $0; gsub(/[][ ]/, "", table); next }
  /^[A-Za-z_][A-Za-z0-9_-]*[[:space:]]*=/ { key = $1; sub(/=.*/, "", key); print table "." key }
' "$TMP/below" > "$TMP/keys"
printf 'claude_cost.symbol\nclaude_model.symbol\n' > "$TMP/want"
if cmp -s "$TMP/keys" "$TMP/want"; then
  echo "ok   keys below the marker are claude_cost.symbol and claude_model.symbol"
else
  echo "FAIL $FILE below the marker has these keys:"
  sed 's/^/     /' "$TMP/keys"
  echo "     Fix: below the marker keep only claude_cost.symbol and claude_model.symbol."
  echo "     Other overrides belong in ~/.config/starship.toml or a change to this test."
  fail=1
fi

if command -v starship >/dev/null 2>&1; then
  if starship preset plain-text-symbols 2>/dev/null | cmp -s - "$FIXTURE"; then
    echo "ok   installed starship preset matches the fixture"
  else
    echo "NOTE the installed 'starship preset plain-text-symbols' differs from $FIXTURE. Refresh the fixture and $FILE if you want the newer preset."
  fi
fi

exit "$fail"
