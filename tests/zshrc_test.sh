#!/bin/sh
# Tests for shell/.zshrc. Each case starts zsh against a throwaway $HOME with a clean
# environment and PATH=/usr/bin:/bin, so none of the optional tools is found and the
# real home directory is untouched. Needs zsh.
#
#   sh tests/zshrc_test.sh
# shellcheck disable=SC2016  # zsh code is passed to zsh in single quotes on purpose
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
no_stderr() { [ -z "$("$@" 2>&1 >/dev/null)" ]; }

# new_home <name>: create a home directory with ~/.zshrc linked to the repo copy.
new_home() {
  mkdir "$TMP/$1" && ln -s "$REPO/shell/.zshrc" "$TMP/$1/.zshrc" && printf '%s\n' "$TMP/$1"
}
# zi <home> <command>: run <command> in an interactive zsh.
zi() { env -i HOME="$1" PATH=/usr/bin:/bin TERM=dumb zsh -i -c "$2"; }
# zn <home> <command>: source ~/.zshrc in a non-interactive zsh, then run <command>.
zn() { env -i HOME="$1" PATH=/usr/bin:/bin zsh -c "source ~/.zshrc; $2"; }

# fake_node <home> <version>...: install stub Node versions where nvm keeps them.
fake_node() {
  h=$1; shift
  for v; do
    mkdir -p "$h/.nvm/versions/node/$v/bin"
    printf '#!/bin/sh\n' > "$h/.nvm/versions/node/$v/bin/node"
    chmod +x "$h/.nvm/versions/node/$v/bin/node"
  done
}
# nvm_alias <home> <name> <value>: write an nvm alias file.
nvm_alias() { mkdir -p "$(dirname "$1/.nvm/alias/$2")" && printf '%s\n' "$3" > "$1/.nvm/alias/$2"; }
# first_path <home>: print the first PATH entry of an interactive shell.
first_path() { zi "$1" 'print -r -- $path[1]'; }

# --- Startup, aliases, PATH ---
H=$(new_home basic)
check "startup: writes nothing to stderr" no_stderr zi "$H" true
check "startup: sourcing ~/.zshrc returns 0" env -i HOME="$H" PATH=/usr/bin:/bin zsh -c 'source ~/.zshrc'
check "startup: an interactive shell's first status is 0" zi "$H" exit
check "aliases: defined in interactive shells" test "$(zi "$H" 'alias gs')" = "gs='git status'"
check "aliases: not defined in non-interactive shells" test "$(zn "$H" 'alias gs || echo none')" = none
check "aliases: ls falls back to ls -G without eza" test "$(zi "$H" 'alias ls')" = "ls='ls -G'"
check "PATH: prepends ~/.local/bin, bun and pnpm in order" \
  test "$(zi "$H" 'print -r -- $path[1,3]')" = "$H/.local/bin $H/.bun/bin $H/Library/pnpm/bin"
check "PATH: reloading does not duplicate entries" \
  test "$(zi "$H" 'source ~/.zshrc; print -r -- ${#${(M)path:#$HOME/.local/bin}}')" = 1

# --- Completion dump ---
H=$(new_home completion)
echo 'skip_global_compinit=1' > "$H/.zshenv"   # Debian/Ubuntu: skip /etc/zsh/zshrc's compinit, as on macOS
zi "$H" true
check "completion: first start writes ~/.zcompdump" test -s "$H/.zcompdump"
check "completion: and compiles it to ~/.zcompdump.zwc" test -s "$H/.zcompdump.zwc"
check "completion: leaves no temporary files" test "$(cd "$H" && echo .zcompdump*)" = ".zcompdump .zcompdump.zwc"
check "completion: a later start loads completions" test "$(zi "$H" 'print -r -- ${+_comps[git]}')" = 1

# --- ~/.zshrc.local ---
H=$(new_home local)
printf 'LOCAL_MARK=loaded\nalias gs=custom\n' > "$H/.zshrc.local"
check "local: ~/.zshrc.local is sourced" test "$(zi "$H" 'print -r -- $LOCAL_MARK')" = loaded
check "local: ~/.zshrc.local can override aliases" test "$(zi "$H" 'alias gs')" = "gs=custom"

# --- nvm default Node on PATH ---
H=$(new_home nvm_lts)
fake_node "$H" v22.1.0 v24.9.0 v24.21.0
nvm_alias "$H" default 'lts/*'
nvm_alias "$H" 'lts/*' lts/krypton
nvm_alias "$H" lts/krypton v24.21.0
check "nvm: follows default -> lts/* -> lts/krypton -> version" \
  test "$(first_path "$H")" = "$H/.nvm/versions/node/v24.21.0/bin"

H=$(new_home nvm_partial)
fake_node "$H" v9.11.2 v22.1.0 v24.9.0 v24.10.0
nvm_alias "$H" default 24
check "nvm: partial version picks the newest match numerically" \
  test "$(first_path "$H")" = "$H/.nvm/versions/node/v24.10.0/bin"

H=$(new_home nvm_node)
fake_node "$H" v9.11.2 v22.1.0 v24.10.0
nvm_alias "$H" default node
check "nvm: 'node' picks the newest installed version" \
  test "$(first_path "$H")" = "$H/.nvm/versions/node/v24.10.0/bin"

H=$(new_home nvm_system)
fake_node "$H" v24.10.0
nvm_alias "$H" default system
check "nvm: 'system' adds nothing to PATH" test "$(first_path "$H")" = "$H/.local/bin"

H=$(new_home nvm_missing)
fake_node "$H" v24.10.0
nvm_alias "$H" default v21.0.0
check "nvm: an uninstalled default adds nothing to PATH" test "$(first_path "$H")" = "$H/.local/bin"

H=$(new_home nvm_none)
fake_node "$H" v24.10.0
check "nvm: no default alias adds nothing to PATH" test "$(first_path "$H")" = "$H/.local/bin"

H=$(new_home nvm_loop)
fake_node "$H" v24.10.0
nvm_alias "$H" default a
nvm_alias "$H" a default
check "nvm: an alias loop terminates and adds nothing" test "$(first_path "$H")" = "$H/.local/bin"

H=$(new_home nvm_bad_pattern)
fake_node "$H" v24.10.0
nvm_alias "$H" default '24('
printf 'LOCAL_MARK=loaded\n' > "$H/.zshrc.local"
check "nvm: a malformed alias does not abort the rest of .zshrc" \
  test "$(zi "$H" 'print -r -- $LOCAL_MARK' 2>/dev/null)" = loaded
check "nvm: a malformed alias prints no error" no_stderr zi "$H" true

echo
if [ "$fails" -eq 0 ]; then echo "all .zshrc tests passed"; else echo "$fails .zshrc test(s) failed"; exit 1; fi
