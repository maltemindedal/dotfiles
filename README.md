# Dotfiles

Personal dotfiles for macOS (zsh) and Windows (PowerShell). Use at your own risk! 😊

## Layout

| Path | Installs to |
|------|-------------|
| `shell/.zshrc` | `~/.zshrc` |
| `shell/starship.toml` | `~/.config/starship.toml` |
| `shell/Microsoft.PowerShell_profile.ps1` | `$PROFILE` (Windows) |
| `git/.gitconfig` | `~/.gitconfig` |
| `git/.gitconfig.windows` | `~/.gitconfig.local` (Windows only) |
| `git/.gitignore_global` | `~/.gitignore_global` |
| `AGENTS.md` | Guidelines for AI coding agents |

## Setup (macOS)

```sh
git clone https://github.com/maltemindedal/dotfiles ~/Developer/dotfiles
cd ~/Developer/dotfiles

ln -sf "$PWD/shell/.zshrc" ~/.zshrc
mkdir -p ~/.config && ln -sf "$PWD/shell/starship.toml" ~/.config/starship.toml
ln -sf "$PWD/git/.gitconfig" ~/.gitconfig
ln -sf "$PWD/git/.gitignore_global" ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global

# Zsh plugins (sourced by .zshrc if present)
mkdir -p ~/.zsh/plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting

# Tools used by .zshrc (all optional — it degrades gracefully)
brew install starship fzf zoxide fd eza bat zsh-completions nvm uv
```

Machine-specific git settings (e.g. `gpg.ssh.allowedSignersFile`) go in `~/.gitconfig.local`, which is included by `.gitconfig`.
