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

   `tests/check.sh` runs `zsh -n` on `.zshrc`, parses `.gitconfig` and `.gitconfig.windows` with `git config -l`, runs every `tests/*_test.sh` suite (each in a temp `$HOME` with stubs and no network), and runs `tests/lint.sh`, which fails on commits made on `main`, checks the commit subjects on your branch and rejects `/Users/` and `/home/` paths under `shell/` and `git/`. It shows the output of any check that fails. Run a check on its own, such as `sh tests/zshrc_test.sh`, to see every case.

3. Re-run `./install.sh` if you added a new file that needs a symlink. Add the file to the script first.
4. When you change what `install.sh` or `.zshrc` does, add or update a case in `tests/`.
5. Update the docs that describe what you changed. Use [`docs/reference/zsh.md`](docs/reference/zsh.md) or [`docs/reference/git.md`](docs/reference/git.md). Also update [`docs/README.md`](docs/README.md) if you added a document. The docs tests fail when a reference doc, the getting started steps or the architecture layout misses a name the config defines, such as a new alias, Git key or link. They also fail when an alias row gives a different command from `.zshrc`. They do not check that a description is right.

## Conventions

- Anything machine-specific (secrets, absolute paths, host-specific keys) goes in `~/.zshrc.local` / `~/.gitconfig.local`, never in tracked files. See [Machine-specific overrides](docs/guides/machine-specific-overrides.md).
- Guard optional tools in `.zshrc` with `command -v …` or a file-existence check so the shell works without them.
- Commit subjects are `<area>: <imperative, lowercase, no final period>`; `tests/lint.sh` lists the areas and fails on any other subject. Include a body explaining *why* when it isn't obvious. A body that opens with `Bug fix.` needs a regression test under `tests/` in the same commit. See `git log` for examples.
- `.gitconfig` enables SSH signing for commits.
- A pull request says under `## Merge method` whether it should be merged with a merge commit, rebased or squashed, and why. Use a merge commit when another open PR builds on the branch, rebase when every commit passes the gate alone and has a message worth keeping, and squash otherwise.
- Record non-obvious design choices as an architecture decision record (ADR) in [`docs/architecture/decisions/`](docs/architecture/decisions/).
