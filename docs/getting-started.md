# Getting started (macOS)

This tutorial sets up zsh, the Starship prompt, Git, and the Claude Code, Codex and Cursor CLI config on a fresh macOS machine. It takes about 10 to 15 minutes, most of it waiting for Homebrew.

## Prerequisites

- macOS with zsh as the login shell (the default since macOS Catalina).
- [Homebrew](https://brew.sh) installed at `/opt/homebrew` (Apple Silicon default). `shell/.zshrc` hard-codes this prefix for completions and nvm. It expects Homebrew's `shellenv` command in `~/.zprofile`. The Homebrew installer does not add it; it prints the commands under "Next steps". The line is `eval "$(/opt/homebrew/bin/brew shellenv zsh)"`.
- `git` (ships with Xcode Command Line Tools).

> Run `./install.sh --tools` to complete steps 2 through 4. The manual steps below show what it does.

## 1. Clone the repository

```sh
git clone https://github.com/maltemindedal/dotfiles ~/Developer/dotfiles
cd ~/Developer/dotfiles
```

You can clone the repository anywhere. The rest of this tutorial uses `$PWD`, so the location does not matter.

## 2. Link the shell, Git and agent config

```sh
ln -sf "$PWD/shell/.zshrc" ~/.zshrc
mkdir -p ~/.config && ln -sf "$PWD/shell/starship.toml" ~/.config/starship.toml
ln -sf "$PWD/git/.gitconfig" ~/.gitconfig
ln -sf "$PWD/git/.gitignore_global" ~/.gitignore_global
mkdir -p ~/.claude
ln -sf "$PWD/claude/settings.json" ~/.claude/settings.json
ln -sf "$PWD/claude/CLAUDE.md" ~/.claude/CLAUDE.md
ln -sf "$PWD/claude/pstack-models.md" ~/.claude/pstack-models.md
```

`ln -sf` deletes a file already at the link's location, so move any existing `~/.zshrc`, `~/.gitconfig` or `~/.claude/settings.json` you want to keep aside first. `install.sh` does this for you.

`claude/settings.json` holds Claude Code's permissions, sandbox and plugin settings, and turns off commit and PR attribution. Claude Code writes changes you make in `/config` through the link, so they show up in `git status`. The repo does not track `~/.claude/settings.local.json`.

`git pull` in the repo updates your live config through the symlinks. There is no sync step.

The Codex and Cursor CLI configs are not linked, because the Codex app and the Cursor CLI write their own state and host paths into them. On a new Mac, copy them into place:

```sh
mkdir -p ~/.codex ~/.cursor
cp -n "$PWD/codex/config.toml" ~/.codex/config.toml
cp -n "$PWD/cursor/cli-config.json" ~/.cursor/cli-config.json
```

`cp -n` leaves an existing file alone. `install.sh` merges into an existing file instead: the keys and tables the repo file names replace the live ones, and the rest of the live file stays. It backs up the old file to `<name>.<timestamp>.bak` first, and writes nothing when the result is already the live file. The Cursor merge needs `jq`, which recent macOS versions ship in `/usr/bin`; without it, `install.sh` warns and leaves an existing file alone. Both files turn off agent attribution in commits and PRs. A change you make to one of those keys in the app is undone by the next `./install.sh`, so make it in the repo file too.

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
chmod go-w "$(brew --prefix)/share"
```

Homebrew leaves its `share` directory group-writable. `compinit` treats that as insecure and aborts, because `zsh-completions` lives inside it, so the `chmod` removes the write permission.

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

## 7. Turn off attribution in the Cursor app

The Cursor app keeps its attribution setting in its own storage, not in a file this repo can install. In the Cursor app, open **Settings**, then **Agents**, and turn off **Attribution**.

The repo does not track the Cursor app's other settings, `~/.cursor/mcp.json` or `~/.agents/skills`.

## Next steps

- Look up aliases and keybindings in the [zsh reference](reference/zsh.md).
- Understand the design in the [architecture overview](architecture/overview.md).
- Follow [Windows setup](guides/windows-setup.md) to configure a Windows machine.
