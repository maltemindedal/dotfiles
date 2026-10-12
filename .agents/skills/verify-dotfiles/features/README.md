# Feature map: dotfiles

| Feature | Driven by | Notes |
| --- | --- | --- |
| zsh config (`shell/.zshrc`): aliases, options, keybindings, optional tools | `gate` (`zsh -n`, `tests/zshrc_test.sh`) | Starship prompt rendering is not checked |
| Git config (`git/.gitconfig`, `.gitconfig.windows`, `.gitignore_global`) | `gate` (`git config -l`, docs test) | Values are not compared, only parsed |
| `install.sh` (symlinks, backups, plugins, `--tools`) | `gate` (`tests/install_test.sh`, temp HOME, stub git/brew), `install` (flags) | Real `brew install` and network clones are never run |
| Docs list every alias, option, key and link | `gate` (`tests/docs_test.sh`) | Prose and wrong values are not caught |
| Windows PowerShell profile | `pwsh` | SKIP unless `pwsh` is installed |
