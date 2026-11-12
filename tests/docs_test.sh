#!/bin/sh
# Tests that the docs keep up with the config. The listed cases read the names a
# config file defines and check that the doc which promises to list them mentions
# each one. The row cases go the other way: each table row in a reference doc
# must name something the config still defines, with the value it sets wherever
# the row states one. Needs git.
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

# --- Every row in docs/reference/zsh.md matches .zshrc ---
# rows <doc> prints line|kind|section|name|stated|values for each `name` in the
# first cell of each table row. kind is the header's first cell, section the
# first `token` of the ## heading above. When the second cell starts with a
# backtick, stated is y and values holds its `tokens`, separated by \037: paired
# with the names when the counts match (`..`, `...` and `cd ..`, `cd ../..`),
# else all given to each name. A row with no `name` prints one record with an
# empty name.
US=$(printf '\037')
rows() {
  awk -F'|' -v us="$US" '
    function ticks(cell, t,   n, i, p) { n = split(cell, p, "`"); for (i = 2; i < n; i += 2) t[i / 2] = p[i]; return int((n - 1) / 2) }
    /^## / { ns = ticks($0, h); section = ns ? h[1] : ""; kind = ""; next }
    !/^[|]/ { kind = ""; next }
    kind == "" { kind = $2; gsub(/^ +| +$/, "", kind); next }
    /^[|][-| ]*$/ { next }
    {
      nn = ticks($2, name); nv = 0; stated = "n"
      if ($3 ~ /^ *`/) { stated = "y"; nv = ticks($3, val) }
      all = ""; for (i = 1; i <= nv; i++) all = all (i > 1 ? us : "") val[i]
      if (nn == 0) { print NR "|" kind "|" section "||" stated "|" all; next }
      for (i = 1; i <= nn; i++)
        print NR "|" kind "|" section "|" name[i] "|" stated "|" (nv == nn ? val[i] : all)
    }' "$1"
}
# matches <doc value> <config value>: equal, or the doc value ends in … and
# the config value starts with the rest.
matches() {
  case $1 in *…) case $2 in "${1%…}"*) return 0 ;; esac; return 1 ;; esac
  [ "$1" = "$2" ]
}
# defined <defs> <name> <stated> <value>: <defs> holds name|value lines; pass if
# <name> has one and, when <stated> is y, one of its values matches <value>.
defined() {
  found=0
  while IFS='|' read -r n v; do
    [ "$n" = "$2" ] || continue
    [ "$3" = y ] || return 0
    matches "$4" "$v" && return 0
    found=1
  done <<EOF2
$1
EOF2
  return $((found + 1))   # 1: no such name, 2: no matching value
}
ZSHRC_CODE=$(sed '/^[[:space:]]*#/d; s/[[:space:]]#.*//' shell/.zshrc)
ALIAS_DEFS=$(printf '%s\n' "$ZSHRC_CODE" | sed -n "s/.*alias \([^= ]*\)=[\"']\(.*\)[\"']\$/\1|\2/p")
VAR_DEFS=$(printf '%s\n' "$ZSHRC_CODE" | sed -n 's/^[[:space:]]*\(export \)\{0,1\}\([A-Z][A-Z0-9_]*\)=\(.*\)$/\2|\3/p' |
  sed "s/|\"\(.*\)\"\$/|\1/; s/|'\(.*\)'\$/|\1/")
OPTS=$(printf '%s\n' "$ZSHRC_CODE" | sed -n 's/^setopt //p' | tr -s ' ' '\n' | sed 's/.*/&|/')
ZSH_ROWS=$(rows docs/reference/zsh.md)
wrong=$(printf '%s\n' "$ZSH_ROWS" | while IFS='|' read -r line kind _ name stated value; do
  at="docs/reference/zsh.md:$line \`$name\`"
  case $kind in
    (Alias) defs=$ALIAS_DEFS what=alias ;;
    (Variable) defs=$VAR_DEFS what=variable ;;
    (Option) defs=$OPTS what=option stated=n ;;
    (Tool)
      printf '%s\n' "$ZSHRC_CODE" | grep -qwF -- "$name" ||
        printf '\n  [%s: shell/.zshrc never mentions it; delete the row]' "$at"
      continue ;;
    (Key) continue ;;   # keybindings: escape sequences in .zshrc, symbols in the doc
    (*) printf '\n  [docs/reference/zsh.md:%s: no check for a "%s" table; add one to tests/docs_test.sh]' "$line" "$kind"; continue ;;
  esac
  rc=0; defined "$defs" "$name" "$stated" "$value" || rc=$?
  case $rc in
    (1) printf '\n  [%s: shell/.zshrc sets no %s %s; delete the row]' "$at" "$what" "$name" ;;
    (2) printf '\n  [%s | `%s`: shell/.zshrc has %s]' "$at" "$value" \
         "$(printf '%s\n' "$defs" | awk -F'|' -v n="$name" '$1 == n { s = s (s ? " or " : "") "`" $2 "`" } END { print s }')" ;;
  esac
done)
if [ -z "$ZSH_ROWS" ] || [ -z "$ALIAS_DEFS" ] || [ -z "$VAR_DEFS" ] || [ -z "$OPTS" ]; then
  fail "zsh reference: every row matches .zshrc: found nothing to compare"
elif [ -n "$wrong" ]; then fail "zsh reference: every row matches .zshrc; fix the row or .zshrc:$wrong"
else pass "zsh reference: every row matches .zshrc"; fi

# --- docs/reference/git.md lists every key and ignore pattern ---
# git prints keys in lower case as section.subsection.key; the doc may write
# section "subsection".key, so compare that form in lower case.
GIT_DOC=$(first_cells docs/reference/git.md | sed 's/ "\([^"]*\)"\./.\1./g' | tr '[:upper:]' '[:lower:]')
listed "git reference: every key in .gitconfig and .gitconfig.windows" \
  "$(for f in git/.gitconfig git/.gitconfig.windows; do git config -f "$f" --name-only -l; done | sort -u | ticks)" "$GIT_DOC"
listed "git reference: every pattern in .gitignore_global" \
  "$(sed '/^#/d; /^$/d' git/.gitignore_global | ticks)" "$(grep '^|' docs/reference/git.md)"

# --- Every row in docs/reference/git.md matches git/ ---
# A Key row names a key in the git/ file its ## heading names, and gives all its
# values in order (credential helpers have two: `` then the gh helper). A Group
# row lists patterns from .gitignore_global.
then_list() { awk 'NR > 1 { printf "` then `" } { printf "%s", $0 }'; }
GIT_ROWS=$(rows docs/reference/git.md)
wrong=$(printf '%s\n' "$GIT_ROWS" | while IFS='|' read -r line kind section name stated value; do
  at="docs/reference/git.md:$line \`$name\`" file="git/$section"
  if [ ! -f "$file" ]; then
    printf '\n  [docs/reference/git.md:%s: the heading above names no file in git/]' "$line"; continue
  fi
  case $kind in
    (Key)
      key=$(printf '%s' "$name" | sed 's/ "\([^"]*\)"\./.\1./')
      if ! have=$(git config -f "$file" --get-all "$key"); then
        printf '\n  [%s: %s does not set it; delete the row]' "$at" "$file"; continue
      fi
      [ "$stated" = y ] || continue
      want=$(printf '%s' "$value" | tr "$US" '\n')
      matches "$want" "$have" ||
        printf '\n  [%s | `%s`: %s has `%s`]' "$at" "$(printf '%s\n' "$want" | then_list)" "$file" \
          "$(printf '%s\n' "$have" | then_list)" ;;
    (Group)
      printf '%s' "$value" | tr "$US" '\n' | while IFS= read -r pattern; do
        grep -qxF -- "$pattern" "$file" ||
          printf '\n  [docs/reference/git.md:%s `%s`: %s does not list it; delete it from the row]' "$line" "$pattern" "$file"
      done ;;
    (*) printf '\n  [docs/reference/git.md:%s: no check for a "%s" table; add one to tests/docs_test.sh]' "$line" "$kind" ;;
  esac
done)
if [ -z "$GIT_ROWS" ]; then fail "git reference: every row matches git/: found nothing to compare"
elif [ -n "$wrong" ]; then fail "git reference: every row matches git/; fix the row or the file:$wrong"
else pass "git reference: every row matches git/"; fi

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
MERGES=$(sed -n 's/^merge [a-z]* \([^ ]*\)  *"\$HOME\/\([^"]*\)"$/\1 \2/p' install.sh)  # <source> <target under ~>
listed "getting started: copies every file install.sh merges" \
  "$(printf '%s\n' "$MERGES" | while read -r src dst; do printf 'cp -n "$PWD/%s" ~/%s\n' "$src" "$dst"; done)" \
  "$(cat docs/getting-started.md)"
listed "architecture overview: maps every file install.sh merges" \
  "$(printf '%s\n' "$MERGES" | while read -r src dst; do printf 'merged into ~/%s \n' "$dst"; done)" \
  "$(cat docs/architecture/overview.md)"
listed "architecture overview: lists every file in shell/, git/, agents/, claude/, codex/ and cursor/" \
  "$(git ls-files shell git agents claude codex cursor | sed 's|.*/|  |; s/$/ /')" "$(cat docs/architecture/overview.md)"

echo
if [ "$fails" -eq 0 ]; then echo "all docs tests passed"; else echo "$fails docs test(s) failed"; exit 1; fi
