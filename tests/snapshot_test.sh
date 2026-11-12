#!/bin/sh
# Replays Claude Code's shell snapshot against shell/.zshrc. The snapshot sources
# ~/.zshrc in a non-interactive zsh, copies the aliases and the functions whose
# names do not start with _, and loads the copies into each agent shell without
# the rest of .zshrc. This test does the same on a copy of .zshrc whose
# /opt/homebrew points at a fake prefix, with every optional file .zshrc tests for
# in place, then calls each copied function in a bare zsh. Needs zsh.
#
#   sh tests/snapshot_test.sh
# shellcheck disable=SC2016  # zsh code is passed to zsh in single quotes on purpose
set -eu

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
fails=0

pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }

H=$TMP/home
BREW=$TMP/brew
mkdir -p "$H" "$BREW/opt/nvm/etc/bash_completion.d"
printf 'nvm() { echo nvm "$@"; }\n' > "$BREW/opt/nvm/nvm.sh"
printf 'compdef _nvm nvm\n' > "$BREW/opt/nvm/etc/bash_completion.d/nvm"
sed "s|/opt/homebrew|$BREW|g" "$REPO/shell/.zshrc" > "$H/.zshrc"

# The fake prefix only works if the sed above reached every Homebrew path.
want=$(grep -oF /opt/homebrew "$REPO/shell/.zshrc" | wc -l | tr -d ' ')
got=$(grep -oF "$BREW" "$H/.zshrc" | wc -l | tr -d ' ')
if [ "$want" -gt 0 ] && [ "$got" = "$want" ] && ! grep -qF /opt/homebrew "$H/.zshrc"; then
  pass "seam: all $want /opt/homebrew paths point at the fake prefix"
else
  fail "seam: all /opt/homebrew paths point at the fake prefix ($got of $want; fix the sed in tests/snapshot_test.sh)"
fi

# Create every file under ~ that .zshrc guards with -s or -f. A completion script
# registers a stub_<name> completion, so loading one outside the interactive block shows.
grep -o '\-[sf] [^] ]*' "$H/.zshrc" | cut -c4- | sort -u | while read -r f; do
  p=$(env -i HOME="$H" BUN_INSTALL="$H/.bun" zsh -fc "print -r -- $f" 2>/dev/null) || continue
  case $p in
    "$H"/*)
      [ -e "$p" ] && continue
      mkdir -p "$(dirname "$p")"
      case $p in
        */_*|*completion*) echo "compdef _stub stub_${p##*/}" ;;
        *) echo : ;;
      esac > "$p" ;;
  esac
done

env -i HOME="$H" ERR="$TMP/err" PATH=/usr/bin:/bin zsh -c '
  source ~/.zshrc >/dev/null 2>"$ERR"
  zmodload zsh/parameter
  for k in ${(k)_comps[(I)stub_*]}; do print -r -- "registers completion $k" >> "$ERR"; done
  for f in ${(k)functions}; do [[ $f == _* || ${functions_source[$f]} != ~/.zshrc ]] || functions $f; done
  alias -L' > "$TMP/snapshot" 2>/dev/null
env -i HOME="$H" PATH=/usr/bin:/bin zsh -c 'alias -L' > "$TMP/base" 2>/dev/null || true

if [ -s "$TMP/err" ]; then
  fail "non-interactive source: no stderr and no completions (put them inside [[ -o interactive ]]): $(head -2 "$TMP/err" | tr '\n' ' ')"
else
  pass "non-interactive source: no stderr and no completions"
fi
extra=$(grep '^alias ' "$TMP/snapshot" | grep -vxF -f "$TMP/base" || true)
if [ -n "$extra" ]; then
  fail "non-interactive source: defines no aliases (put them inside [[ -o interactive ]]): $(printf '%s\n' "$extra" | head -3 | tr '\n' ' ')"
else
  pass "non-interactive source: defines no aliases"
fi

FUNCS=$(env -i zsh -fc "source $TMP/snapshot; print -l \${(k)functions}")
if [ -n "$FUNCS" ]; then pass "snapshot: copies functions"; else fail "snapshot: copies functions (did /opt/homebrew move?)"; fi
for f in $FUNCS; do
  err=$(env -i HOME="$H" PATH=/usr/bin:/bin zsh -fc "source $TMP/snapshot; $f --version" 2>&1 >/dev/null) || true
  case $err in
    *FUNCNEST*|*compdef*|*"command not found: _"*)
      fail "snapshot: $f works on its own (no helper functions, no compdef, unset itself first): $(printf '%s\n' "$err" | head -1)" ;;
    *) pass "snapshot: $f works on its own" ;;
  esac
done

echo
if [ "$fails" -eq 0 ]; then echo "all snapshot tests passed"; else echo "$fails snapshot test(s) failed"; exit 1; fi
