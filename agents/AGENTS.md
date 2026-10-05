## Merging

Every merge you do ends with the full cleanup below, whatever words I used to ask for it and whether the merge was the whole task or one step of a bigger one. Treat merge and cleanup as one action, so branches and worktrees from parallel agents don't pile up on my machine. Done means: PR merged, branch gone on remote and local, worktree removed, local `main` matching `origin/main`.

1. **Merge the PR** with `gh pr merge --squash`, then confirm `gh pr view --json state` reads `MERGED`.
2. **Check the worktree is clean**: `git status --porcelain` prints nothing. If it shows changes, stop and ask me.
3. **Remove the worktree** from the main checkout (the first path in `git worktree list`); `cd` there first, since the current directory is about to disappear.
   - Created by Claude Code's `EnterWorktree` in this session: `ExitWorktree` with `action: "remove"`. After a squash merge it reports unmerged commits; with a clean status and a `MERGED` PR, re-run with `discard_changes: true`.
   - Any other worktree: `git worktree remove <path>`, then `git worktree prune`.
4. **Delete the branch wherever it still exists**: locally with `git branch -D <branch>` (a squash merge makes `-d` refuse), and on the remote with `git push origin --delete <branch>` if `git ls-remote --heads origin <branch>` still lists it.
5. **Sync main** in the main checkout: `git fetch --prune`, then `git pull --ff-only` if it has `main` checked out, or `git fetch origin main:main` if it's on another branch.
