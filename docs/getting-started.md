# Getting started (macOS)

This tutorial sets up zsh, the Starship prompt, and Git on a fresh macOS machine. It takes about 10 to 15 minutes, most of it waiting for Homebrew.

## Prerequisites

- macOS with zsh as the login shell (the default since macOS Catalina).
- [Homebrew](https://brew.sh) installed at `/opt/homebrew` (Apple Silicon default). `shell/.zshrc` hard-codes this prefix for completions and nvm. It expects Homebrew's `shellenv` command in `~/.zprofile`, which the Homebrew installer adds.
- `git` (ships with Xcode Command Line Tools).

> Run `./install.sh --tools` to complete steps 2 through 4. The manual steps below show what it does.

## 1. Clone the repository

```sh
git clone https://github.com/maltemindedal/dotfiles ~/Developer/dotfiles
cd ~/Developer/dotfiles
```

You can clone the repository anywhere. The rest of this tutorial uses `$PWD`, so the location does not matter.

## 2. Link the shell and Git config

```sh
ln -sf "$PWD/shell/.zshrc" ~/.zshrc
mkdir -p ~/.config && ln -sf "$PWD/shell/starship.toml" ~/.config/starship.toml
ln -sf "$PWD/git/.gitconfig" ~/.gitconfig
ln -sf "$PWD/git/.gitignore_global" ~/.gitignore_global
```

`ln -sf` deletes a file already at the link's location, so move any existing `~/.zshrc` or `~/.gitconfig` you want to keep aside first. `install.sh` does this for you.

`git pull` in the repo updates your live config through the symlinks. There is no sync step.

## 3. Install the zsh plugins

`shell/.zshrc` sources two plugins from `~/.zsh/plugins/` if they exist:

```sh
mkdir -p ~/.zsh/plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting
```

## 4. Install the optional tools

Every tool below is optional. Missing tools do not prevent the shell from starting, but their commands and integrations remain unavailable. Install them all to enable every optional feature:

```sh
brew install starship fzf zoxide fd eza bat zsh-completions nvm uv gh
```

See the [zsh reference](reference/zsh.md#optional-tools) for what each tool enables. `.gitconfig` uses `gh` as the GitHub credential helper; run `gh auth login` once after installing it.

## 5. Reload the shell

```sh
exec zsh
```

You should see the Starship prompt. Check that the config loaded:

```sh
alias gs               # prints gs='git status'
git config user.name   # prints Malte Mindedal
```

## 6. Add machine-specific settings

Commit signing uses an SSH key. `.gitconfig` sets the public key, but the `allowedSignersFile` (needed for `git log --show-signature`) is host-specific. Put it and other machine-specific settings in `~/.gitconfig.local` and `~/.zshrc.local`. See [Machine-specific overrides](guides/machine-specific-overrides.md).

## Next steps

- Look up aliases and keybindings in the [zsh reference](reference/zsh.md).
- Understand the design in the [architecture overview](architecture/overview.md).
- Follow [Windows setup](guides/windows-setup.md) to configure a Windows machine.
