#!/bin/sh
# Tests that the docs keep up with the config. Each case reads the names a config
# file defines and checks that the doc which promises to list them mentions each
# one. They catch a missing entry, not a wrong or stale one. Needs git.
#
#   sh tests/docs_test.sh
# shellcheck disable=SC2016  # sed scripts and doc text hold literal $ and backticks on purpose
set -eu

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$REPO"
fails=0

pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }

# listed <description> <needles> <text>: pass if <text> contains every line of
# <needles>, else name the missing ones. An empty <needles> fails too, so a
# broken extraction cannot pass unnoticed.
listed() {
  missing=
  while IFS= read -r needle; do
    case $3 in *"$needle"*) ;; *) missing="$missing [$needle]" ;; esac
  done <<EOF
$2
EOF
  if [ -z "$2" ]; then fail "$1: found nothing to look for"
  elif [ -n "$missing" ]; then fail "$1; missing:$missing"
  else pass "$1"; fi
}
ticks() { sed 's/.*/`&`/'; }                         # wrap each line in backticks
first_cells() { awk -F'|' '/^[|]/ { print $2 }' "$1"; } # first cell of each table row

# --- docs/reference/zsh.md lists every alias, option, variable and optional tool ---
ZSH_DOC=$(first_cells docs/reference/zsh.md)
listed "zsh reference: every alias in .zshrc" \
  "$(sed -n '/^[[:space:]]*#/d; s/.*alias \([^= ]*\)=.*/\1/p' shell/.zshrc | ticks)" "$ZSH_DOC"
listed "zsh reference: every option .zshrc sets" \
  "$(sed -n 's/^setopt \([^#]*\).*/\1/p' shell/.zshrc | tr -s ' ' '\n' | sed '/^$/d' | ticks)" "$ZSH_DOC"
listed "zsh reference: every variable .zshrc sets" \
  "$(sed -n 's/^[[:space:]]*\(export \)\{0,1\}\([A-Z][A-Z0-9_]*\)=.*/\2/p' shell/.zshrc | ticks)" "$ZSH_DOC"
listed "zsh reference: every tool .zshrc looks for" \
  "$(sed -n 's/.*command -v \([^ ]*\) .*/\1/p' shell/.zshrc | ticks)" "$ZSH_DOC"

# --- docs/reference/git.md lists every key and ignore pattern ---
# git prints keys in lower case as section.subsection.key; the doc may write
# section "subsection".key, so compare that form in lower case.
GIT_DOC=$(first_cells docs/reference/git.md | sed 's/ "\([^"]*\)"\./.\1./g' | tr '[:upper:]' '[:lower:]')
listed "git reference: every key in .gitconfig and .gitconfig.windows" \
  "$(for f in git/.gitconfig git/.gitconfig.windows; do git config -f "$f" --name-only -l; done | sort -u | ticks)" "$GIT_DOC"
listed "git reference: every pattern in .gitignore_global" \
  "$(sed '/^#/d; /^$/d' git/.gitignore_global | ticks)" "$(grep '^|' docs/reference/git.md)"

# --- The manual steps and the layout match install.sh ---
LINKS=$(sed -n 's/^link \([^ ]*\)  *"\$HOME\/\([^"]*\)"$/\1 \2/p' install.sh)   # <source> <target under ~>
listed "getting started: links every file install.sh links" \
  "$(printf '%s\n' "$LINKS" | while read -r src dst; do printf 'ln -sf "$PWD/%s" ~/%s\n' "$src" "$dst"; done)" \
  "$(cat docs/getting-started.md)"
listed "getting started: runs the same brew install as install.sh" \
  "$(sed -n 's/^[[:space:]]*\(brew install .*\)/[\1]/p' install.sh)" \
  "$(sed -n 's/^\(brew install .*\)/[\1]/p' docs/getting-started.md)"   # [ ] makes it a whole-line match
listed "architecture overview: maps every target install.sh links" \
  "$(printf '%s\n' "$LINKS" | while read -r src dst; do printf '→ ~/%s \n' "$dst"; done)" \
  "$(cat docs/architecture/overview.md)"
listed "architecture overview: lists every file in shell/ and git/" \
  "$(git ls-files shell git | sed 's|.*/|  |; s/$/ /')" "$(cat docs/architecture/overview.md)"

echo
if [ "$fails" -eq 0 ]; then echo "all docs tests passed"; else echo "$fails docs test(s) failed"; exit 1; fi
