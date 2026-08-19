# Contributing

This is a personal configuration, so there is no formal process — but these conventions keep the repo coherent.

## Making a change

1. Edit the file under `shell/` or `git/`. Because the macOS files are symlinked, the change is live immediately.
2. Check it:

   ```sh
   zsh -n shell/.zshrc             # syntax check
   git config -f git/.gitconfig -l # parse check; lists every key
   reload                          # alias for exec zsh — reload the live shell
   ```

3. Re-run `./install.sh` if you added a new file that needs a symlink (and add it to the script).
4. Update the docs that describe what you changed — [`docs/reference/zsh.md`](reference/zsh.md) or [`docs/reference/git.md`](reference/git.md) — and [`docs/README.md`](README.md) if you added a document.

## Conventions

- Anything machine-specific (secrets, absolute paths, host-specific keys) goes in `~/.zshrc.local` / `~/.gitconfig.local`, never in tracked files. See [Machine-specific overrides](guides/machine-specific-overrides.md).
- Optional tools in `.zshrc` must be guarded with `command -v …` so the shell works without them.
- Commit messages: imperative subject, optionally prefixed with the area (`shell:`, `git:`, `docs:`), body explaining *why* when it isn't obvious — see `git log`.
- Commits are SSH-signed (enforced by `.gitconfig`).
- Record non-obvious design choices as an ADR in [`docs/architecture/decisions/`](architecture/decisions/).
