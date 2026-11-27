#!/bin/sh
# github/sync-labels.sh must create missing labels, correct changed ones, leave
# matching and extra labels alone, and change nothing with --check. Each case
# runs the script with a stub gh that logs its calls. No network.
#
#   sh tests/sync_labels_test.sh
set -eu

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fails=0
TAB=$(printf '\t')

pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }
expect() { # expect <description> <got> <expected>
  if [ "$2" = "$3" ]; then pass "$1"; else
    fail "$1"
    printf '     got:\n%s\n     expected:\n%s\n' "$(printf '%s\n' "$2" | sed 's/^/     |/')" "$(printf '%s\n' "$3" | sed 's/^/     |/')"
  fi
}

mkdir "$TMP/bin"
cat > "$TMP/bin/gh" <<'STUB'
#!/bin/sh
case "$1 $2" in
  "api "*) printf 'me/one\nme/two\n' ;;
  "repo list") printf '%s/repo\n' "$3" ;;
  "label list") cat "$STUB_HAVE" ;;
  "label create")
    printf '%s\n' "$*" >> "$STUB_LOG"
    [ "${STUB_CREATE_FAILS:-0}" -eq 0 ] ;;
  *) echo "unexpected gh call: $*" >&2; exit 9 ;;
esac
STUB
chmod +x "$TMP/bin/gh"
export PATH="$TMP/bin:$PATH" STUB_LOG="$TMP/log" STUB_HAVE="$TMP/have"

# The stub repo already has every label right, except one with a wrong colour and
# one missing, plus a label of its own.
CANON=$(grep -v '^#' "$REPO/github/labels.tsv")
FIRST=$(printf '%s\n' "$CANON" | sed -n 1p | cut -f1)
SECOND=$(printf '%s\n' "$CANON" | sed -n 2p | cut -f1)
drifted() {
  printf '%s\n' "$CANON" | sed -n "1s/${TAB}[0-9a-f]\{6\}${TAB}/${TAB}000000$TAB/p; 3,\$p"
  printf 'frontend\td4c5f9\tOnly this repo has it\n'
}
run() { # run <args...>; sets out and code
  : > "$STUB_LOG"
  code=0
  out=$(sh "$REPO/github/sync-labels.sh" "$@" 2>&1) || code=$?
}

# --- labels.tsv is well formed ---
bad=$(printf '%s\n' "$CANON" | grep -vE "^[^${TAB}]+${TAB}[0-9a-f]{6}${TAB}[^${TAB}]+\$" || true)
expect "labels.tsv: every line is name, lowercase hex colour and description" "$bad" ""
expect "labels.tsv: no name appears twice" \
  "$(printf '%s\n' "$CANON" | cut -f1 | tr '[:upper:]' '[:lower:]' | sort | uniq -d)" ""

GUIDE="$REPO/docs/guides/github-labels.md"
expect "github-labels guide: its table lists every label in labels.tsv, in order" \
  "$(sed -n 's/^| `\([^`]*\)` | .*/\1/p' "$GUIDE")" "$(printf '%s\n' "$CANON" | cut -f1)"

# --- --check reports and changes nothing ---
drifted > "$STUB_HAVE"
run --check me/one
expect "--check exits 1 when a repo differs" "$code" 1
expect "--check lists the changed and the missing label" "$out" "DIFF me/one
     update $FIRST
     create $SECOND"
expect "--check creates no labels" "$(cat "$STUB_LOG")" ""

# --- a sync fixes only what differs ---
run me/one
expect "sync exits 0" "$code" 0
expect "sync updates the changed label and creates the missing one, nothing else" "$(cut -d' ' -f3- "$STUB_LOG" | sed 's/ -R .*//')" "$FIRST
$SECOND"
expect "sync passes --force so an existing label is updated" "$(grep -c -- '--force' "$STUB_LOG")" 2
case $(cat "$STUB_LOG") in *frontend*) fail "sync leaves a repo's own labels alone" ;; *) pass "sync leaves a repo's own labels alone" ;; esac

# --- a repo that matches is left alone ---
{ printf '%s\n' "$CANON"; printf 'frontend\td4c5f9\tOnly this repo has it\n'; } > "$STUB_HAVE"
run --check me/one
expect "--check exits 0 when every label matches" "$code" 0
expect "--check prints ok for a matching repo" "$out" "ok   me/one"
run
expect "no arguments: syncs every repo gh api lists" "$out" "ok   me/one
ok   me/two"
run someone
expect "OWNER: syncs that owner's repos" "$out" "ok   someone/repo"
expect "a matching repo gets no label calls" "$(cat "$STUB_LOG")" ""

# --- failures ---
drifted > "$STUB_HAVE"
STUB_CREATE_FAILS=1 run me/one
expect "a failed label change exits 1" "$code" 1
case $out in "FAIL me/one"*) pass "a failed label change prints FAIL" ;; *) fail "a failed label change prints FAIL: $out" ;; esac
run me/one/extra
expect "a malformed argument exits 2" "$code" 2
expect "a malformed argument makes no gh call" "$(cat "$STUB_LOG")" ""

echo
if [ "$fails" -eq 0 ]; then echo "all sync-labels tests passed"; else echo "$fails sync-labels test(s) failed"; exit 1; fi
