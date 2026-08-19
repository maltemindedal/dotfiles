# Dotfiles

Shell and Git configuration for macOS (zsh) and Windows (PowerShell).

## Overview

This repository contains plain configuration files that are symlinked (macOS) or copied (Windows) into the home directory. The zsh configuration detects optional tools at startup and works without them. Machine-specific settings, such as secrets and host-specific paths, are kept in local override files that are not tracked by the repository.

## Requirements

- **macOS:** zsh (default shell), [Homebrew](https://brew.sh) at `/opt/homebrew`, Git.
- **Windows:** PowerShell 7.2 or later, [Starship](https://starship.rs), Git.

Optional CLI tools (Starship, fzf, zoxide, fd, eza, bat, nvm, uv, gh) extend the shell; see the [zsh reference](docs/reference/zsh.md#optional-tools).

## Installation

### macOS

```sh
git clone https://github.com/maltemindedal/dotfiles ~/Developer/dotfiles
cd ~/Developer/dotfiles
./install.sh --tools
exec zsh
```

`install.sh` creates the symlinks, clones the zsh plugins and, with `--tools`, installs the optional tools via Homebrew. It is idempotent and can be re-run after `git pull`. The equivalent manual steps are in [Getting started](docs/getting-started.md).

### Windows

See [Windows setup](docs/guides/windows-setup.md).

## Usage

After installation the shell provides, among others:

```sh
gs          # git status
ll          # eza -la --git (falls back to ls -alFG)
z <dir>     # zoxide directory jump
reload      # exec zsh
```

The complete list of aliases, keybindings and options is in the [zsh reference](docs/reference/zsh.md). Git settings are documented in the [Git reference](docs/reference/git.md).

## Documentation

| Document | Contents |
|----------|----------|
| [Documentation index](docs/README.md) | Annotated table of contents |
| [Getting started](docs/getting-started.md) | Step-by-step macOS setup |
| [Windows setup](docs/guides/windows-setup.md) | PowerShell profile and Git on Windows |
| [Machine-specific overrides](docs/guides/machine-specific-overrides.md) | Using `~/.zshrc.local` and `~/.gitconfig.local` |
| [zsh reference](docs/reference/zsh.md) | Aliases, keybindings, options, optional tools |
| [Git reference](docs/reference/git.md) | Every `.gitconfig` key and the global ignore list |
| [Architecture overview](docs/architecture/overview.md) | Layout and design rationale |
| [Decision records](docs/architecture/decisions/) | ADRs for non-obvious choices |
| [Contributing](docs/contributing.md) | How to change, verify and document the configuration |

## Repository layout

```
.
├── AGENTS.md     Guidelines for AI coding agents
├── LICENSE       MIT license
├── install.sh    macOS installer (symlinks, plugins, optional tools)
├── docs/         Documentation
├── git/          .gitconfig, Windows overlay, global gitignore
└── shell/        .zshrc, starship.toml, PowerShell profile
```

## Contributing

Conventions and verification steps are described in [docs/contributing.md](docs/contributing.md).

## License

Released under the [MIT License](LICENSE).
