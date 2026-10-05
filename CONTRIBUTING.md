# Contributing

This is a personal configuration, so there is no formal process. These conventions keep the repo coherent.

Everyone taking part is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Making a change

1. Edit the file under `shell/` or `git/`. Because `install.sh` symlinks the macOS files, editing the repository also changes the installed configuration.
2. Check it:

   ```sh
   zsh -n shell/.zshrc             # syntax check
   git config -f git/.gitconfig -l # parse check; lists every key
   sh tests/install_test.sh        # installer tests (temp $HOME, stub git and brew)
   sh tests/zshrc_test.sh          # .zshrc tests (temp $HOME)
   reload                          # runs exec zsh to reload the live shell
   ```

3. Re-run `./install.sh` if you added a new file that needs a symlink. Add the file to the script first.
4. When you change what `install.sh` or `.zshrc` does, add or update a case in `tests/`.
5. Update the docs that describe what you changed. Use [`docs/reference/zsh.md`](docs/reference/zsh.md) or [`docs/reference/git.md`](docs/reference/git.md). Also update [`docs/README.md`](docs/README.md) if you added a document.

## Conventions

- Anything machine-specific (secrets, absolute paths, host-specific keys) goes in `~/.zshrc.local` / `~/.gitconfig.local`, never in tracked files. See [Machine-specific overrides](docs/guides/machine-specific-overrides.md).
- Guard optional tools in `.zshrc` with `command -v …` or a file-existence check so the shell works without them.
- Commit messages use an imperative subject, optionally prefixed with the area (`shell:`, `git:`, `docs:`). Include a body explaining *why* when it isn't obvious. See `git log` for examples.
- `.gitconfig` enables SSH signing for commits.
- Record non-obvious design choices as an architecture decision record (ADR) in [`docs/architecture/decisions/`](docs/architecture/decisions/).
