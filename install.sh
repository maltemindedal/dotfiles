#!/bin/sh
# Symlink the macOS dotfiles into $HOME and install the zsh plugins.
# Idempotent: safe to re-run after `git pull`.
#
#   ./install.sh          symlinks + plugins
#   ./install.sh --tools  additionally `brew install` the optional CLI tools
set -eu

REPO="$(cd "$(dirname "$0")" && pwd)"

link() {
  # link <source-in-repo> <target-in-home>
  mkdir -p "$(dirname "$2")"
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

if [ "${1:-}" = "--tools" ]; then
  if command -v brew >/dev/null; then
    brew install starship fzf zoxide fd eza bat zsh-completions nvm uv gh
  else
    echo "Homebrew not found; skipping --tools. See docs/getting-started.md." >&2
  fi
fi

echo
echo "Done. Run 'exec zsh' to reload. Machine-specific settings go in ~/.zshrc.local and ~/.gitconfig.local."
