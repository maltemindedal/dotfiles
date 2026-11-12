#!/bin/sh
# Tests for shell/.zprofile. Each case starts a zsh login shell under env -i with
# a temp $HOME and ZDOTDIR. The Homebrew cases run a copy with /opt/homebrew
# pointed at a temp prefix, so they do not depend on the host's Homebrew.
#
#   sh tests/zprofile_test.sh
set -eu

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fails=0

pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }
check() { # check <description> <command...>
  desc=$1; shift
  if "$@"; then pass "$desc"; else fail "$desc"; fi
}

# login <home> <zprofile>: start a login shell that prints its PATH. Output goes
# to <home>.out and <home>.err; the exit status is returned.
login() {
  mkdir -p "$1"
  cp "$2" "$1/.zprofile"
  env -i HOME="$1" ZDOTDIR="$1" PATH=/usr/bin:/bin zsh -l -c 'print -r -- "$PATH"' > "$1.out" 2> "$1.err"
}
# sources <home>: source <home>/.zprofile in zsh and return its status, which a
# caller such as `source ~/.zprofile && cmd` sees.
sources() { env -i HOME="$1" PATH=/usr/bin:/bin zsh -c '. "$HOME/.zprofile"' 2> /dev/null; }
path_is() { [ "$(cat "$1.out")" = "$2" ]; }

BREW="$TMP/homebrew"
sed "s|/opt/homebrew|$BREW|g" "$REPO/shell/.zprofile" > "$TMP/zprofile"
check "the Homebrew copy points at the temp prefix" grep -qF "$BREW/bin/brew shellenv zsh" "$TMP/zprofile"

H="$TMP/tracked"
check "tracked file: a login shell exits 0" login "$H" "$REPO/shell/.zprofile"
check "tracked file: writes nothing to stderr" [ ! -s "$H.err" ]

H="$TMP/neither"
check "no Docker, no Homebrew: a login shell exits 0" login "$H" "$TMP/zprofile"
check "no Docker, no Homebrew: writes nothing to stderr" [ ! -s "$H.err" ]
check "no Docker, no Homebrew: sourcing it returns 0" sources "$H"
# macOS /etc/zprofile runs path_helper, which may reorder PATH; compare with a
# login shell that has no ~/.zprofile.
mkdir "$TMP/bare"
env -i HOME="$TMP/bare" ZDOTDIR="$TMP/bare" PATH=/usr/bin:/bin zsh -l -c 'print -r -- "$PATH"' > "$TMP/bare.out"
BARE=$(cat "$TMP/bare.out")
check "no Docker, no Homebrew: leaves PATH as a login shell without it has it" path_is "$H" "$BARE"

mkdir -p "$BREW/bin" "$TMP/both/.docker/bin"
printf '%s\n' '#!/bin/sh' "[ \"\$*\" = 'shellenv zsh' ] && echo 'export PATH=\"$BREW/bin:\$PATH\"'" > "$BREW/bin/brew"
chmod +x "$BREW/bin/brew"
H="$TMP/both"
check "Docker and Homebrew: a login shell exits 0" login "$H" "$TMP/zprofile"
check "Docker and Homebrew: writes nothing to stderr" [ ! -s "$H.err" ]
check "Docker and Homebrew: sourcing it returns 0" sources "$H"
check "Docker and Homebrew: puts Homebrew first and Docker last on PATH" \
  path_is "$H" "$BREW/bin:$BARE:$H/.docker/bin"

echo
if [ "$fails" -eq 0 ]; then echo "all .zprofile tests passed"; else echo "$fails .zprofile test(s) failed"; exit 1; fi
