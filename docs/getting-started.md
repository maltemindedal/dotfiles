# Getting started (macOS)

This tutorial takes a fresh macOS machine to a fully configured zsh shell, Starship prompt and Git setup. It takes about 10–15 minutes, most of it waiting on Homebrew.

## Prerequisites

- macOS with zsh as the login shell (the default since macOS Catalina).
- [Homebrew](https://brew.sh) installed at `/opt/homebrew` (Apple Silicon default). `shell/.zshrc` hard-codes this prefix for completions and nvm, and expects Homebrew's `shellenv` to already be in `~/.zprofile` — the Homebrew installer adds this line for you.
- `git` (ships with Xcode Command Line Tools).

> Shortcut: `./install.sh --tools` performs steps 2–4 in one go. The manual steps below show what it does.

## 1. Clone the repository

```sh
git clone https://github.com/maltemindedal/dotfiles ~/Developer/dotfiles
cd ~/Developer/dotfiles
```

Any location works; the rest of this tutorial uses `$PWD` so it does not matter where you cloned.

## 2. Link the shell and Git config

```sh
ln -sf "$PWD/shell/.zshrc" ~/.zshrc
mkdir -p ~/.config && ln -sf "$PWD/shell/starship.toml" ~/.config/starship.toml
ln -sf "$PWD/git/.gitconfig" ~/.gitconfig
ln -sf "$PWD/git/.gitignore_global" ~/.gitignore_global
```

Symlinks mean `git pull` in the repo updates your live config — there is no sync step.

## 3. Install the zsh plugins

`shell/.zshrc` sources two plugins from `~/.zsh/plugins/` if they exist:

```sh
mkdir -p ~/.zsh/plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting
```

## 4. Install the optional tools

Every tool below is optional — `.zshrc` checks for each one with `command -v` and skips it when absent. Install them all for the full experience:

```sh
brew install starship fzf zoxide fd eza bat zsh-completions nvm uv gh
```

What each one enables is listed in the [zsh reference](reference/zsh.md#optional-tools). `gh` is used by `.gitconfig` as the GitHub credential helper; run `gh auth login` once after installing it.

## 5. Reload the shell

```sh
exec zsh
```

You should see the Starship prompt. Check that the config loaded:

```sh
alias gs          # → gs='git status'
git config user.name   # → Malte Mindedal
```

## 6. Add machine-specific settings

Commit signing uses an SSH key. `.gitconfig` sets the public key, but the `allowedSignersFile` (needed for `git log --show-signature`) is host-specific. Put it, and anything else local, in `~/.gitconfig.local` and `~/.zshrc.local` — see [Machine-specific overrides](guides/machine-specific-overrides.md).

## Next steps

- Look up aliases and keybindings in the [zsh reference](reference/zsh.md).
- Understand the design in the [architecture overview](architecture/overview.md).
- Setting up a Windows machine too? See [Windows setup](guides/windows-setup.md).
