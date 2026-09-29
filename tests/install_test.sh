#!/bin/sh
# Tests for install.sh. Each case runs the installer against a throwaway $HOME with
# stub `git` and `brew` commands on PATH, so it touches neither the real home
# directory nor the network.
#
#   sh tests/install_test.sh
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

# Stubs. `git clone ... <dir>` creates <dir>/<name>.zsh; both log their arguments.
mkdir "$TMP/stubs" "$TMP/stubs-nobrew"
cat > "$TMP/stubs/git" <<'EOF'
#!/bin/sh
echo "git $*" >> "$STUB_LOG"
[ "$1" = clone ] || exit 1
for dir; do :; done
mkdir -p "$dir" && : > "$dir/$(basename "$dir").zsh"
EOF
cat > "$TMP/stubs/brew" <<'EOF'
#!/bin/sh
echo "brew $*" >> "$STUB_LOG"
EOF
chmod +x "$TMP/stubs/git" "$TMP/stubs/brew"
cp "$TMP/stubs/git" "$TMP/stubs-nobrew/git"

# new_home <name>: create an empty home directory and print its path.
new_home() { mkdir "$TMP/$1" && printf '%s\n' "$TMP/$1"; }

# run_install <home> [args...]: run install.sh from an unrelated cwd with a clean
# environment and the stubs in $BIN on PATH. Output goes to <home>.out and
# <home>.err; the exit status is returned.
BIN="$TMP/stubs"
run_install() {
  h=$1; shift
  (cd "$TMP" && env -i HOME="$h" PATH="$BIN:/usr/bin:/bin" STUB_LOG="$h.log" \
    sh "$REPO/install.sh" "$@") > "$h.out" 2> "$h.err"
}

links_ok() { # links_ok <home>: every target is a symlink into the repo
  [ "$(readlink "$1/.zshrc")" = "$REPO/shell/.zshrc" ] &&
    [ "$(readlink "$1/.config/starship.toml")" = "$REPO/shell/starship.toml" ] &&
    [ "$(readlink "$1/.gitconfig")" = "$REPO/git/.gitconfig" ] &&
    [ "$(readlink "$1/.gitignore_global")" = "$REPO/git/.gitignore_global" ]
}
count() { grep -c "$1" "$2" || true; }

# --- Fresh install ---
H=$(new_home fresh)
check "fresh: exits 0" run_install "$H"
check "fresh: links all four files into the repo" links_ok "$H"
check "fresh: clones zsh-autosuggestions" \
  grep -qx "git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions $H/.zsh/plugins/zsh-autosuggestions" "$H.log"
check "fresh: clones zsh-syntax-highlighting" \
  grep -qx "git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting $H/.zsh/plugins/zsh-syntax-highlighting" "$H.log"
check "fresh: does not run brew" [ "$(count '^brew' "$H.log")" -eq 0 ]
check "fresh: prints one line per link" [ "$(count ' -> ' "$H.out")" -eq 4 ]
check "fresh: writes nothing to stderr" [ ! -s "$H.err" ]

# --- Re-run is idempotent ---
check "rerun: exits 0" run_install "$H"
check "rerun: links unchanged" links_ok "$H"
check "rerun: does not clone again" [ "$(count '^git clone' "$H.log")" -eq 2 ]
check "rerun: reports plugins already present" [ "$(count 'already present' "$H.out")" -eq 2 ]

# --- Existing symlinks are replaced ---
H=$(new_home relink)
mkdir -p "$H/.config"
ln -s /nonexistent "$H/.zshrc"
ln -s /nonexistent "$H/.config/starship.toml"
check "relink: exits 0" run_install "$H"
check "relink: replaces stale symlinks" links_ok "$H"

# --- A relative invocation ignores CDPATH ---
# With CDPATH exported, `cd dotfiles` can land in another directory of the same name
# and print it, which would corrupt every link target.
H=$(new_home cdpath)
mkdir -p "$TMP/decoy/$(basename "$REPO")"
cdpath_install() {
  (cd "$(dirname "$REPO")" && env -i HOME="$H" PATH="$BIN:/usr/bin:/bin" STUB_LOG="$H.log" \
    CDPATH="$TMP/decoy" sh "$(basename "$REPO")/install.sh") > "$H.out" 2> "$H.err"
}
check "cdpath: exits 0" cdpath_install
check "cdpath: links point into the repo" links_ok "$H"

# --- --tools ---
H=$(new_home tools)
check "tools: exits 0" run_install "$H" --tools
check "tools: installs the optional tools with brew" \
  grep -qx 'brew install starship fzf zoxide fd eza bat zsh-completions nvm uv gh' "$H.log"

H=$(new_home nobrew)
BIN="$TMP/stubs-nobrew"
check "tools without brew: exits 0" run_install "$H" --tools
BIN="$TMP/stubs"
check "tools without brew: still links" links_ok "$H"
check "tools without brew: warns on stderr" grep -q 'Homebrew not found' "$H.err"

echo
if [ "$fails" -eq 0 ]; then echo "all install.sh tests passed"; else echo "$fails install.sh test(s) failed"; exit 1; fi
