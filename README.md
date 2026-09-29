# Dotfiles

Shell and Git configuration for macOS (zsh) and Windows (PowerShell).

## Overview

This repository contains plain configuration files for macOS and Windows. On macOS, `install.sh` symlinks the applicable files into the home directory. The Windows setup copies its configuration files instead. The zsh configuration starts without the optional tools and enables their integrations when available. Untracked local override files hold machine-specific settings such as secrets and host-specific paths.

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

`install.sh` creates the symlinks, clones the zsh plugins and, with `--tools`, installs the optional tools via Homebrew. It is idempotent and can be re-run after `git pull`. A real file already at a link's location, such as an existing `~/.zshrc`, is moved aside to `<name>.<timestamp>.bak`. The equivalent manual steps are in [Getting started](docs/getting-started.md).

### Windows

See [Windows setup](docs/guides/windows-setup.md).

## Usage

After installation, these commands are available:

```sh
gs          # git status
ll          # eza -la --git (falls back to ls -alFG)
z <dir>     # zoxide directory jump
reload      # exec zsh
```

The complete list of aliases, keybindings and options is in the [zsh reference](docs/reference/zsh.md). The [Git reference](docs/reference/git.md) documents the Git settings.

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
├── shell/        .zshrc, starship.toml, PowerShell profile
└── tests/        Tests for install.sh and .zshrc
```

## Contributing

See [docs/contributing.md](docs/contributing.md) for conventions and verification steps.

## License

Released under the [MIT License](LICENSE).
