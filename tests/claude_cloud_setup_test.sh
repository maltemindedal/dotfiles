#!/bin/sh
# claude/cloud-setup.sh must write ~/.claude/CLAUDE.md and pstack-models.md,
# byte-identical to claude/, and exit 0 whether the claude CLI and apt-get
# work, fail or are missing. Temp $HOME, stub claude,
# apt-get and zsh, no network.
#
#   sh tests/claude_cloud_setup_test.sh
set -eu

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fails=0
BASH_BIN="$(command -v bash)"

pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }

BIN="$TMP/bin"
mkdir "$BIN"
for tool in cat mkdir tail sed; do
  if command -v "$tool" > /dev/null 2>&1; then ln -s "$(command -v "$tool")" "$BIN/$tool"; fi
done

run_setup() { # run_setup <name> <claude exit code, or "missing">
  name="$1"
  home="$TMP/$name/home"
  mkdir -p "$home"
  rm -f "$BIN/claude"
  if [ "$2" != missing ]; then
    printf '%s\n' '#!/bin/sh' "echo \"\$*\" >> \"\$HOME/claude.log\"" "exit $2" > "$BIN/claude"
    chmod +x "$BIN/claude"
  fi
  if HOME="$home" PATH="$BIN" "$BASH_BIN" "$REPO/claude/cloud-setup.sh" > "$TMP/$name/out" 2>&1; then
    pass "$name: exits 0"
  else
    fail "$name: exits 0"
    sed 's/^/     |/' "$TMP/$name/out"
  fi
  for f in CLAUDE.md pstack-models.md; do
    if cmp -s "$REPO/claude/$f" "$home/.claude/$f"; then pass "$name: writes $f identical to claude/$f"; else fail "$name: writes $f identical to claude/$f"; fi
  done
}

expect_out() { # expect_out <name> <line>
  if grep -qxF "$2" "$TMP/$1/out"; then pass "$1: prints '$2'"; else
    fail "$1: prints '$2'"
    sed 's/^/     |/' "$TMP/$1/out"
  fi
}

run_setup works 0
expect_out works "plugins: installed pstack@pstack-claude"
if grep -qxF "plugin install pstack@pstack-claude --scope user" "$TMP/works/home/claude.log"; then
  pass "works: installs pstack at user scope"
else
  fail "works: installs pstack at user scope"
fi

imports_ok=1
for f in $(sed -n 's|^@~/\.claude/||p' "$TMP/works/home/.claude/CLAUDE.md"); do
  [ -s "$TMP/works/home/.claude/$f" ] || imports_ok=0
done
if [ "$imports_ok" -eq 1 ]; then pass "works: every CLAUDE.md import is written"; else fail "works: every CLAUDE.md import is written"; fi

cp -R "$TMP/works/home/.claude" "$TMP/first-run"
HOME="$TMP/works/home" PATH="$BIN" "$BASH_BIN" "$REPO/claude/cloud-setup.sh" > /dev/null 2>&1
if diff -r "$TMP/first-run" "$TMP/works/home/.claude" > /dev/null; then pass "works: a second run changes nothing"; else fail "works: a second run changes nothing"; fi

run_setup claude-fails 1
expect_out claude-fails "plugins: could not install pstack@pstack-claude, skipping:"

run_setup claude-missing missing
expect_out claude-missing "plugins: claude CLI not on PATH, skipping pstack@pstack-claude"

expect_out claude-missing "zsh: apt-get not on PATH, skipping"

stub_apt() { # stub_apt <exit code>
  printf '%s\n' '#!/bin/sh' "echo \"\${DEBIAN_FRONTEND:-} \$*\" >> \"\$HOME/apt.log\"" "exit $1" > "$BIN/apt-get"
  chmod +x "$BIN/apt-get"
}

unset DEBIAN_FRONTEND   # the stub logs it, to show the script sets it for the install
stub_apt 0
run_setup zsh-missing 0
expect_out zsh-missing "zsh: installed"
if [ "$(cat "$TMP/zsh-missing/home/apt.log")" = " update
noninteractive -o Dpkg::Options::=--force-confold install -y zsh" ]; then
  pass "zsh-missing: updates apt, then installs zsh without a conffile prompt"
else
  fail "zsh-missing: updates apt, then installs zsh without a conffile prompt"
fi

stub_apt 1
run_setup apt-fails 0
expect_out apt-fails "zsh: could not install, skipping:"

stub_apt 0
printf '%s\n' '#!/bin/sh' > "$BIN/zsh"
chmod +x "$BIN/zsh"
run_setup zsh-present 0
expect_out zsh-present "zsh: already installed"
if [ -e "$TMP/zsh-present/home/apt.log" ]; then fail "zsh-present: does not call apt-get"; else pass "zsh-present: does not call apt-get"; fi
rm -f "$BIN/zsh" "$BIN/apt-get"

if [ -e "$TMP/works/home/.claude/settings.json" ]; then
  fail "works: leaves settings.json alone"
else
  pass "works: leaves settings.json alone"
fi

echo
if [ "$fails" -eq 0 ]; then echo "all claude cloud-setup tests passed"; else echo "$fails claude cloud-setup test(s) failed"; exit 1; fi
