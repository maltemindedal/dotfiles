# Documentation index

All documentation for the dotfiles repository, grouped by purpose.

## Tutorials (learning)

| Document | Description | Audience |
|----------|-------------|----------|
| [getting-started.md](getting-started.md) | Set up a shell and Git on a fresh macOS machine in under 15 minutes. | Someone setting up a new Mac |

## How-to guides (tasks)

| Document | Description | Audience |
|----------|-------------|----------|
| [guides/windows-setup.md](guides/windows-setup.md) | Install the PowerShell profile and Git config on Windows. | Windows users |
| [guides/machine-specific-overrides.md](guides/machine-specific-overrides.md) | Add per-machine zsh and Git settings without touching the repo. | Anyone with secrets or host-specific paths |

## Reference (lookup)

| Document | Description | Audience |
|----------|-------------|----------|
| [reference/zsh.md](reference/zsh.md) | Every alias, keybinding, shell option, environment variable and optional tool in `shell/.zshrc`. | Daily users looking something up |
| [reference/git.md](reference/git.md) | Every key in `git/.gitconfig`, `git/.gitconfig.windows` and the patterns in `git/.gitignore_global`. | Anyone auditing the Git config |

## Explanation (understanding)

| Document | Description | Audience |
|----------|-------------|----------|
| [architecture/overview.md](architecture/overview.md) | Repository layout and the reasons for the installation and load-order choices. | Anyone changing the config |
| [architecture/decisions/0001-two-layer-configuration.md](architecture/decisions/0001-two-layer-configuration.md) | ADR: why tracked config files include an untracked `~/.*.local` file. | Anyone changing the config |
| [architecture/decisions/0002-symlinks-on-macos-copies-on-windows.md](architecture/decisions/0002-symlinks-on-macos-copies-on-windows.md) | ADR: why macOS uses symlinks, Windows uses copies, and no dotfile manager. | Anyone changing the install model |

## Contributing

| Document | Description | Audience |
|----------|-------------|----------|
| [contributing.md](contributing.md) | How to change, check and document the config; commit conventions. | Anyone editing the repo |
