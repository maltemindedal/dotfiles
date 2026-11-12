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

# Stubs. `git clone ... <dir>` creates <dir>/<name>.zsh, `brew --prefix` prints
# $HOME/homebrew; both log their arguments.
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
if [ "$1" = --prefix ]; then echo "$HOME/homebrew"; fi
EOF
chmod +x "$TMP/stubs/git" "$TMP/stubs/brew"
cp "$TMP/stubs/git" "$TMP/stubs-nobrew/git"

# new_home <name>: create an empty home directory and print its path.
new_home() { mkdir "$TMP/$1" && printf '%s\n' "$TMP/$1"; }

# run_install <home> [args...]: run $INSTALL from an unrelated cwd with a clean
# environment and the stubs in $BIN, then $SYS, on PATH. Output goes to <home>.out
# and <home>.err; the exit status is returned.
BIN="$TMP/stubs" SYS=/usr/bin:/bin INSTALL="$REPO/install.sh"
run_install() {
  h=$1; shift
  (cd "$TMP" && env -i HOME="$h" PATH="$BIN:$SYS" STUB_LOG="$h.log" \
    sh "$INSTALL" "$@") > "$h.out" 2> "$h.err"
}

links_ok() { # links_ok <home>: every target is a symlink into the repo
  [ "$(readlink "$1/.zshrc")" = "$REPO/shell/.zshrc" ] &&
    [ "$(readlink "$1/.config/starship.toml")" = "$REPO/shell/starship.toml" ] &&
    [ "$(readlink "$1/.gitconfig")" = "$REPO/git/.gitconfig" ] &&
    [ "$(readlink "$1/.gitignore_global")" = "$REPO/git/.gitignore_global" ] &&
    [ "$(readlink "$1/.claude/settings.json")" = "$REPO/claude/settings.json" ] &&
    [ "$(readlink "$1/.claude/CLAUDE.md")" = "$REPO/agents/AGENTS.md" ] &&
    [ "$(readlink "$1/.codex/AGENTS.md")" = "$REPO/agents/AGENTS.md" ] &&
    [ "$(readlink "$1/.claude/pstack-models.md")" = "$REPO/claude/pstack-models.md" ]
}
count() { grep -c "$1" "$2" || true; }
status_is() { # status_is <status> <command...>
  want=$1; shift
  "$@" && got=0 || got=$?
  [ "$got" -eq "$want" ]
}
empty_dir() { [ -z "$(ls -A "$1")" ]; }
tree() { (cd "$1" && ls -lAR . && find . -type f -exec cksum {} + | sort); } # names, modes, links, bytes
real_git() { h=$1; shift; env -i HOME="$h" PATH=/usr/bin:/bin git "$@"; }       # no stub, as after install
only_owner_writes() { [ "$(ls -ld "$1" | cut -c6,9)" = -- ]; } # no group or other w

# --- Fresh install ---
H=$(new_home fresh)
check "fresh: exits 0" run_install "$H"
check "fresh: links all eight targets into the repo" links_ok "$H"
check "fresh: clones zsh-autosuggestions" \
  grep -qx "git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions $H/.zsh/plugins/zsh-autosuggestions" "$H.log"
check "fresh: clones zsh-syntax-highlighting" \
  grep -qx "git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting $H/.zsh/plugins/zsh-syntax-highlighting" "$H.log"
check "fresh: does not run brew" [ "$(count '^brew' "$H.log")" -eq 0 ]
check "fresh: prints one line per link" [ "$(count ' -> ' "$H.out")" -eq 8 ]
check "fresh: writes nothing to stderr" [ ! -s "$H.err" ]
check "fresh: copies the Codex config" cmp -s "$H/.codex/config.toml" "$REPO/codex/config.toml"
check "fresh: turns off Codex commit attribution" grep -qx 'commit_attribution = ""' "$H/.codex/config.toml"
check "fresh: copies the Cursor CLI config" cmp -s "$H/.cursor/cli-config.json" "$REPO/cursor/cli-config.json"
check "fresh: turns off Cursor CLI commit and PR attribution" \
  test "$(sed -n '/^  "attribution": {/,/^  }/p' "$H/.cursor/cli-config.json")" = '  "attribution": {
    "attributeCommitsToAgent": false,
    "attributePRsToAgent": false
  },'
real_git "$H" init -q "$H/repo"
check "installed: a new repo ignores .DS_Store through the global ignore" \
  real_git "$H" -C "$H/repo" check-ignore -q .DS_Store
check "installed: git has a user.email" test -n "$(real_git "$H" config --global user.email)"
check "installed: git signs with ssh" test "$(real_git "$H" config --global gpg.format)" = ssh
rm -rf "$H/repo"

# --- Re-run is idempotent ---
check "rerun: exits 0" run_install "$H"
check "rerun: links unchanged" links_ok "$H"
check "rerun: does not clone again" [ "$(count '^git clone' "$H.log")" -eq 2 ]
check "rerun: reports plugins already present" [ "$(count 'already present' "$H.out")" -eq 2 ]
check "rerun: leaves the copied Codex and Cursor configs up to date" [ "$(count '(up to date)$' "$H.out")" -eq 2 ]
check "rerun: makes no backups" [ "$(count 'backed up' "$H.out")" -eq 0 ]

# --- Codex and Cursor configs are merged into the live files ---
# A repo copy with fixture configs, so the expected files below do not change when
# the real codex/ and cursor/ configs do. Its links dangle; that is fine here.
FIX="$TMP/fixture-repo"
mkdir -p "$FIX/codex" "$FIX/cursor"
cp "$REPO/install.sh" "$FIX/"
cat > "$FIX/codex/config.toml" <<'EOF'
# merged, not linked
model = "new-model"
commit_attribution = ""

[desktop]
mode = "steer"

[extra]
x = 1
EOF
printf '%s\n' '{"editor": {"vimMode": false}, "attribution": {"attributeCommitsToAgent": false, "attributePRsToAgent": false}}' \
  > "$FIX/cursor/cli-config.json"
INSTALL="$FIX/install.sh"
files_are() { # files_are <expected-content> <file>
  [ "$(cat "$2"; echo .)" = "$1
." ]
}
baks() { find "$1" -name '*.bak' | wc -l | tr -d ' '; }

H=$(new_home merge)
mkdir -p "$H/.codex" "$H/.cursor"
LIVE_TOML='notify = ["/Users/me/notify", "turn-ended"]
model = "old-model"

[desktop]
mode = "queue"
old = 1

[marketplaces.x]
source = "/Users/me/x"

[projects."/Users/me/repo"]
trust_level = "trusted"'
printf '%s\n' "$LIVE_TOML" > "$H/.codex/config.toml"
chmod 600 "$H/.codex/config.toml"
printf '%s\n' '{"version": 1, "editor": {"vimMode": true, "extra": 1}, "attribution": {"attributeCommitsToAgent": true}}' \
  > "$H/.cursor/cli-config.json"
check "merge: exits 0" run_install "$H"
check "merge: keeps notify, [marketplaces.x] and [projects.\"…\"] and replaces the tracked keys and tables" \
  files_are 'notify = ["/Users/me/notify", "turn-ended"]
model = "new-model"
commit_attribution = ""

[desktop]
mode = "steer"

[marketplaces.x]
source = "/Users/me/x"

[projects."/Users/me/repo"]
trust_level = "trusted"

[extra]
x = 1' "$H/.codex/config.toml"
check "merge: keeps the Codex config readable only by its owner" \
  test "$(ls -l "$H/.codex/config.toml" | cut -c1-10)" = -rw-------
check "merge: keeps the old Codex config as a backup" files_are "$LIVE_TOML" "$H"/.codex/config.toml.*.bak
if command -v jq >/dev/null; then
  check "merge: keeps the Cursor CLI's own keys and sets the tracked ones" \
    files_are '{
  "version": 1,
  "editor": {
    "vimMode": false
  },
  "attribution": {
    "attributeCommitsToAgent": false,
    "attributePRsToAgent": false
  }
}' "$H/.cursor/cli-config.json"
  check "merge: reports two backups" [ "$(count 'backed up' "$H.out")" -eq 2 ]
else
  pass "merge: Cursor CLI config: skipped, jq not installed"
fi
cp "$H/.codex/config.toml" "$H.toml"
cp "$H/.cursor/cli-config.json" "$H.json"
BAKS=$(baks "$H")
check "merge rerun: exits 0" run_install "$H"
check "merge rerun: leaves the Codex config byte-identical" cmp -s "$H/.codex/config.toml" "$H.toml"
check "merge rerun: leaves the Cursor CLI config byte-identical" cmp -s "$H/.cursor/cli-config.json" "$H.json"
check "merge rerun: makes no new backup" [ "$(baks "$H")" -eq "$BAKS" ]

H=$(new_home merge-tables-only)
mkdir -p "$H/.codex"
printf '%s\n' '[projects."/Users/me/repo"]' 'trust_level = "trusted"' > "$H/.codex/config.toml"
check "merge, no live top-level keys: exits 0" run_install "$H"
check "merge, no live top-level keys: puts the tracked keys above the first table" \
  files_are 'model = "new-model"
commit_attribution = ""

[projects."/Users/me/repo"]
trust_level = "trusted"

[desktop]
mode = "steer"

[extra]
x = 1' "$H/.codex/config.toml"

# Without jq, an existing Cursor CLI config is left alone with a warning. The PATH
# holds only the commands install.sh needs, and no jq.
mkdir "$TMP/stubs-nojq"
for c in sh dirname basename date mkdir mv ln cp cmp awk rm; do ln -s "$(command -v "$c")" "$TMP/stubs-nojq/$c"; done
cp "$TMP/stubs/git" "$TMP/stubs-nojq/git"
H=$(new_home nojq)
mkdir -p "$H/.cursor"
printf '%s\n' '{"version": 1}' > "$H/.cursor/cli-config.json"
BIN="$TMP/stubs-nojq" SYS="$TMP/stubs-nojq"
check "no jq: exits 0" run_install "$H"
BIN="$TMP/stubs" SYS=/usr/bin:/bin
check "no jq: warns on stderr" grep -q '^jq not found; skipping the merge of cursor/cli-config.json' "$H.err"
check "no jq: leaves the Cursor CLI config unchanged" files_are '{"version": 1}' "$H/.cursor/cli-config.json"
check "no jq: still installs the Codex config" grep -qx 'commit_attribution = ""' "$H/.codex/config.toml"
INSTALL="$REPO/install.sh"

# --- Existing symlinks are replaced ---
H=$(new_home relink)
mkdir -p "$H/.config"
ln -s /nonexistent "$H/.zshrc"
ln -s /nonexistent "$H/.config/starship.toml"
check "relink: exits 0" run_install "$H"
check "relink: replaces stale symlinks" links_ok "$H"

# --- Existing files and directories are moved aside, not lost ---
H=$(new_home existing)
mkdir -p "$H/.config" "$H/.claude"
echo 'my zshrc' > "$H/.zshrc"
echo 'my gitconfig' > "$H/.gitconfig"
mkdir "$H/.gitignore_global"
echo 'my file' > "$H/.gitignore_global/inside"
echo '{"theme": "dark"}' > "$H/.claude/settings.json"
check "existing: exits 0" run_install "$H"
check "existing: links all eight targets into the repo" links_ok "$H"
check "existing: keeps the old ~/.zshrc as a backup" grep -qsx 'my zshrc' "$H"/.zshrc.*.bak
check "existing: keeps the old ~/.gitconfig as a backup" grep -qsx 'my gitconfig' "$H"/.gitconfig.*.bak
check "existing: moves a directory out of the way intact" test -f "$H"/.gitignore_global.*.bak/inside
check "existing: keeps the old ~/.claude/settings.json as a backup" \
  grep -qsx '{"theme": "dark"}' "$H"/.claude/settings.json.*.bak
check "existing: reports each backup" [ "$(count 'backed up' "$H.out")" -eq 4 ]
check "existing: rerun makes no further backups" run_install "$H"
check "existing: rerun reports no backups" [ "$(count 'backed up' "$H.out")" -eq 0 ]

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

# --- Arguments are checked before anything changes ---
# A home with a file, a stale link and a directory at link targets, so a stray link,
# backup or edit changes its tree.
H=$(new_home badarg)
mkdir -p "$H/.config" "$H/.gitignore_global"
echo 'my zshrc' > "$H/.zshrc"
ln -s /nonexistent "$H/.gitconfig"
BEFORE=$(tree "$H")
for args in --tool foo -x --TOOLS '' '--tools extra' 'foo --tools'; do
  # shellcheck disable=SC2086  # split on purpose: '--tools extra' is two arguments
  [ -n "$args" ] && set -- $args || set -- ''
  check "bad arguments [$args]: exits 2" status_is 2 run_install "$H" "$@"
  check "bad arguments [$args]: prints usage on stderr" grep -q '^usage:' "$H.err"
  check "bad arguments [$args]: leaves \$HOME byte-identical" test "$(tree "$H")" = "$BEFORE"
done
H=$(new_home help)
check "--help: exits 0" run_install "$H" --help
check "--help: prints usage" grep -q '^usage:' "$H.out"
check "--help: leaves \$HOME untouched" empty_dir "$H"

# --- --tools ---
H=$(new_home tools)
mkdir -p "$H/homebrew/share" && chmod 777 "$H/homebrew/share"
check "tools: exits 0" run_install "$H" --tools
check "tools: installs the optional tools with brew" \
  grep -qx 'brew install starship fzf zoxide fd eza bat zsh-completions nvm uv gh' "$H.log"
check "tools: makes Homebrew's share dir writable only by its owner" \
  only_owner_writes "$H/homebrew/share"

H=$(new_home nobrew)
BIN="$TMP/stubs-nobrew"
check "tools without brew: exits 0" run_install "$H" --tools
BIN="$TMP/stubs"
check "tools without brew: still links" links_ok "$H"
check "tools without brew: warns on stderr" grep -q 'Homebrew not found' "$H.err"

echo
if [ "$fails" -eq 0 ]; then echo "all install.sh tests passed"; else echo "$fails install.sh test(s) failed"; exit 1; fi
