#!/bin/sh
# Exercise the gate in a tiny fixture, without recursively running real suites.
set -eu
REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/repo/tests" "$TMP/bin"
cp "$REPO/tests/check.sh" "$TMP/repo/tests/check.sh"
printf '#!/bin/sh\nexit 0\n' > "$TMP/bin/zsh"
cp "$TMP/bin/zsh" "$TMP/bin/git"
chmod +x "$TMP/bin/"*
printf 'exit 0\n' > "$TMP/repo/tests/lint.sh"
cat > "$TMP/repo/tests/a_test.sh" <<'CASE'
# When probing concurrency, the next suite must run before this one finishes.
if [ "${PROBE:-0}" = 1 ]; then
  n=0
  while [ ! -f tests/started ]; do
    n=$((n + 1))
    [ "$n" -lt 5 ] || { echo 'next suite never started' >&2; exit 1; }
    sleep 1
  done
fi
echo 'ok   hidden passing case'
CASE
printf 'touch tests/started\n' > "$TMP/repo/tests/b_test.sh"
fails=0
check() {
  if "$@"; then printf 'ok   %s\n' "$*"; else printf 'FAIL %s\n' "$*"; fails=$((fails + 1)); fi
}
run_gate() {
  # A different working directory also checks the runner's root resolution.
  (cd "$TMP" && env PATH="$TMP/bin:/usr/bin:/bin" DOTFILES_TEST_JOBS="$1" PROBE="$2" \
    sh "$TMP/repo/tests/check.sh") > "$TMP/out" 2>&1
}
check run_gate 4 1
cp "$TMP/out" "$TMP/parallel"
check run_gate 1 0
check cmp "$TMP/parallel" "$TMP/out"
check grep -qx 'all checks passed' "$TMP/out"
if grep -q 'hidden passing case' "$TMP/out"; then fails=$((fails + 1)); echo 'FAIL passing output leaked'; fi

printf 'echo "ok   hidden passing case"\necho "failure detail" >&2\nexit 1\n' > "$TMP/repo/tests/a_test.sh"
printf 'exit 1\n' > "$TMP/repo/tests/b_test.sh"
if run_gate 4 0; then
  echo 'FAIL failing suites returned success'; fails=$((fails + 1))
else
  check test "$?" -eq 1
fi
check grep -qx '     failure detail' "$TMP/out"
check grep -qx 'FAIL sh tests/a_test.sh' "$TMP/out"
check grep -qx 'FAIL sh tests/b_test.sh' "$TMP/out"
check grep -qx 'ok   sh tests/lint.sh' "$TMP/out"
check grep -qx '2 check(s) failed' "$TMP/out"
if grep -q 'hidden passing case' "$TMP/out"; then fails=$((fails + 1)); echo 'FAIL passing case in failure output'; fi
for jobs in 0 -1 invalid 17; do
  if run_gate "$jobs" 0; then
    echo "FAIL accepted invalid job count $jobs"; fails=$((fails + 1))
  else
    check test "$?" -eq 2
  fi
done
[ "$fails" -eq 0 ]
