#!/bin/sh
# Symlink the macOS dotfiles and agent config into $HOME and install the zsh plugins.
# Idempotent: safe to re-run after `git pull`. A real file or directory already at a
# link's location is moved aside to <name>.<timestamp>.bak rather than deleted.
#
#   ./install.sh          symlinks + plugins
#   ./install.sh --tools  additionally `brew install` the optional CLI tools
set -eu

# Check the arguments before changing anything.
usage() { echo "usage: $0 [--tools]"; }
TOOLS=
case "$#:${1:-}" in
  0:) ;;
  1:--tools) TOOLS=1 ;;
  1:-h | 1:--help) usage; exit 0 ;;
  *) usage >&2; exit 2 ;;
esac

REPO="$(CDPATH='' cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"

link() {
  # link <source-in-repo> <target-in-home>
  mkdir -p "$(dirname "$2")"
  if [ -e "$2" ] && [ ! -L "$2" ]; then
    # ln -sfn would delete a file here, or create the link inside a directory.
    mv "$2" "$2.$STAMP.bak"
    echo "backed up $2 to $2.$STAMP.bak"
  fi
  ln -sfn "$REPO/$1" "$2"
  printf '%-45s -> %s\n' "$2" "$1"
}

link shell/.zshrc           "$HOME/.zshrc"
link shell/.zprofile        "$HOME/.zprofile"
link shell/starship.toml    "$HOME/.config/starship.toml"
link git/.gitconfig         "$HOME/.gitconfig"
link git/.gitignore_global  "$HOME/.gitignore_global"
link claude/settings.json   "$HOME/.claude/settings.json"
link agents/AGENTS.md       "$HOME/.claude/CLAUDE.md"
link agents/AGENTS.md       "$HOME/.codex/AGENTS.md"
link claude/pstack-models.md "$HOME/.claude/pstack-models.md"

# merge_toml <tracked> <live>: print <live> with each top-level key and table of
# <tracked> in place of the live one of the same name. New keys go after the live
# top-level keys, new tables at the end. Line-based, not a TOML parser: a value may
# continue onto lines that do not look like `key =` or `[table]`.
merge_toml() {
  awk '
    function tname(s) { sub(/^[ \t]*[[]+[ \t]*/, "", s); sub(/[ \t]*[]]+[ \t]*(#.*)?$/, "", s); return s }
    function kname(s) { sub(/[ \t]*=.*/, "", s); sub(/^[ \t]*/, "", s); return s }
    function out(s) { print s; printed = 1; lastblank = (s ~ /^[ \t]*$/) }
    function addkeys(  j) {
      for (j = 1; j <= ntk; j++) if (!(tko[j] in lk)) { out(tk[tko[j]]); added = 1 }
    }
    FNR == 1 { f++; sect = ""; blanks = 0 }
    /^[ \t]*[[]/ {
      sect = tname($0); blanks = 0
      if (f == 1) { tto[++ntt] = sect; tt[sect] = $0 }
      else { lto[++nlt] = sect; lt[nlt] = $0 }
      next
    }
    sect != "" {
      if ($0 ~ /^[ \t]*$/) { blanks++; if (f == 2) lb[nlt] = blanks; next }
      for (; blanks > 0; blanks--) if (f == 1) tt[sect] = tt[sect] "\n"; else lt[nlt] = lt[nlt] "\n"
      if (f == 1) tt[sect] = tt[sect] "\n" $0; else { lt[nlt] = lt[nlt] "\n" $0; lb[nlt] = 0 }
      next
    }
    /^[ \t]*[A-Za-z0-9_."\047-]+[ \t]*=/ {
      k = kname($0)
      if (f == 1) { tko[++ntk] = k; tk[k] = $0; tlast = k }
      else { pi[++np] = $0; pk[np] = k; lk[k] = 1 }
      next
    }
    /^[ \t]*(#.*)?$/ { if (f == 2) { pi[++np] = $0; pk[np] = "" }; next }
    {
      if (f == 1) { if (tlast != "") tk[tlast] = tk[tlast] "\n" $0 }
      else if (np > 0 && pk[np] != "") pi[np] = pi[np] "\n" $0
      else { pi[++np] = $0; pk[np] = "" }
    }
    END {
      last = 0
      for (i = 1; i <= np; i++) if (pi[i] !~ /^[ \t]*$/) last = i
      if (last == 0) addkeys()
      for (i = 1; i <= np; i++) {
        out((pk[i] != "" && pk[i] in tk) ? tk[pk[i]] : pi[i])
        if (i == last) addkeys()
      }
      for (i = 1; i <= nlt; i++) {
        if (i == 1 && added && !lastblank) out("")
        out((lto[i] in tt) ? tt[lto[i]] : lt[i])
        for (b = 0; b < lb[i]; b++) out("")
        seen[lto[i]] = 1
      }
      for (j = 1; j <= ntt; j++) if (!(tto[j] in seen)) {
        if (printed && !lastblank) out("")
        out(tt[tto[j]])
      }
    }' "$1" "$2"
}

# merge_json <tracked> <live>: print <live> with the top-level keys of <tracked>.
merge_json() { jq -s '.[0] + .[1]' "$2" "$1"; }

merge() {
  # merge <toml|json> <source-in-repo> <target-in-home>
  # The repo owns the keys and tables it names; the app that owns the live file
  # keeps everything else, such as host paths it writes itself.
  mkdir -p "$(dirname "$3")"
  if [ ! -f "$3" ] || [ -L "$3" ]; then
    if [ -e "$3" ] || [ -L "$3" ]; then
      mv "$3" "$3.$STAMP.bak"
      echo "backed up $3 to $3.$STAMP.bak"
    fi
    (umask 077 && cp "$REPO/$2" "$3")
    printf '%-45s <- %s (copied)\n' "$3" "$2"
    return
  fi
  if [ "$1" = json ] && ! command -v jq >/dev/null; then
    echo "jq not found; skipping the merge of $2 into $3." >&2
    return
  fi
  # Copy first so the result keeps the live file's mode; Codex writes its config 0600.
  cp -p "$3" "$3.$STAMP.new"
  if ! "merge_$1" "$REPO/$2" "$3" > "$3.$STAMP.new"; then
    rm -f "$3.$STAMP.new"
    echo "could not merge $2 into $3; left it unchanged." >&2
    return
  fi
  if cmp -s "$3.$STAMP.new" "$3"; then
    rm -f "$3.$STAMP.new"
    printf '%-45s <- %s (up to date)\n' "$3" "$2"
    return
  fi
  mv "$3" "$3.$STAMP.bak"
  echo "backed up $3 to $3.$STAMP.bak"
  mv "$3.$STAMP.new" "$3"
  printf '%-45s <- %s (merged)\n' "$3" "$2"
}

merge toml codex/config.toml      "$HOME/.codex/config.toml"
merge json cursor/cli-config.json "$HOME/.cursor/cli-config.json"

PLUGINS="$HOME/.zsh/plugins"
mkdir -p "$PLUGINS"
for p in zsh-autosuggestions zsh-syntax-highlighting; do
  if [ -d "$PLUGINS/$p" ]; then
    echo "plugin $p already present"
  else
    git clone --depth 1 "https://github.com/zsh-users/$p" "$PLUGINS/$p"
  fi
done

if [ -n "$TOOLS" ]; then
  if command -v brew >/dev/null; then
    brew install starship fzf zoxide fd eza bat zsh-completions nvm uv gh
    # Homebrew leaves share/ group-writable, and compinit aborts on a group-writable
    # parent of an fpath entry such as share/zsh-completions.
    chmod go-w "$(brew --prefix)/share"
  else
    echo "Homebrew not found; skipping --tools. See docs/getting-started.md." >&2
  fi
fi

echo
echo "Done. Run 'exec zsh' to reload. Machine-specific settings go in ~/.zshrc.local and ~/.gitconfig.local."
