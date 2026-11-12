# Contributing

This is a personal configuration, so there is no formal process. These conventions keep the repo coherent.

Everyone taking part is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Making a change

1. Edit the file under `shell/` or `git/`. Because `install.sh` symlinks the macOS files, editing the repository also changes the installed configuration.
2. Check it:

   ```sh
   sh tests/check.sh   # every check below; prints ok or FAIL for each
   reload              # runs exec zsh to reload the live shell
   ```

   `tests/check.sh` runs `zsh -n` on `.zshrc` and `.zprofile`, parses `.gitconfig` and `.gitconfig.windows` with `git config -l`, runs every `tests/*_test.sh` suite (each in a temp `$HOME` with stubs and no network), and runs `tests/lint.sh`, which fails on commits made on `main`, checks the commit subjects on your branch and rejects `/Users/` and `/home/` paths under `shell/`, `git/`, `ssh/`, `agents/`, `claude/`, `codex/` and `cursor/`. It shows the output of any check that fails. Run a check on its own, such as `sh tests/zshrc_test.sh`, to see every case.

   The gate runs up to four checks at once and prints their results in the order above. Set `DOTFILES_TEST_JOBS=1 sh tests/check.sh` to run sequentially, or choose a limit from 1 to 16. Each check has its own captured output; all checks finish even when one fails.

3. Re-run `./install.sh` if you added a new file that needs a symlink. Add the file to the script first.
4. When you change what `install.sh` or `.zshrc` does, add or update a case in `tests/`.
5. Update the docs that describe what you changed. Use [`docs/reference/zsh.md`](docs/reference/zsh.md) or [`docs/reference/git.md`](docs/reference/git.md). Also update [`docs/README.md`](docs/README.md) if you added a document. The docs tests fail when a reference doc, the getting started steps or the architecture layout misses a name the config defines, such as a new alias, Git key or link. They also fail when a reference table row names something the config no longer defines, or states a different value from it. They do not check that a description is right.

## Conventions

- Anything machine-specific (secrets, absolute paths, host-specific keys) goes in `~/.zshrc.local` / `~/.gitconfig.local`, never in tracked files. See [Machine-specific overrides](docs/guides/machine-specific-overrides.md).
- Guard optional tools in `.zshrc` with `command -v …` or a file-existence check so the shell works without them.
- Commit subjects are `<area>: <imperative, lowercase, no final period>`; `tests/lint.sh` lists the areas and fails on any other subject. Include a body explaining *why* when it isn't obvious. A body that opens with `Bug fix.` needs a regression test under `tests/` in the same commit. See `git log` for examples.
- `.gitconfig` enables SSH signing for commits.
- Record a non-obvious design choice in the Design decisions section of [`docs/architecture/overview.md`](docs/architecture/overview.md).
