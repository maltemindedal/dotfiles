#!/bin/sh
# Symlink the macOS dotfiles into $HOME and install the zsh plugins.
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
link shell/starship.toml    "$HOME/.config/starship.toml"
link git/.gitconfig         "$HOME/.gitconfig"
link git/.gitignore_global  "$HOME/.gitignore_global"

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
  else
    echo "Homebrew not found; skipping --tools. See docs/getting-started.md." >&2
  fi
fi

echo
echo "Done. Run 'exec zsh' to reload. Machine-specific settings go in ~/.zshrc.local and ~/.gitconfig.local."
