@~/.claude/pstack-models.md

When you merge a PR, choose the merge method by what its commits are.
A rule in a project CLAUDE.md, AGENTS.md or CONTRIBUTING.md takes precedence over these.
Merge only after you have checked that every CI check is green.

- Merge commit when the PR's commits are separate changes, or when a doc cites one of them by hash. It is the only method that keeps those hashes, so use it when unsure.
- Squash when the commits are fix-ups of one change. Write the combined commit message yourself, in the repo's commit format.
- Rebase for a single commit whose message already follows that format, such as a Dependabot bump.

When you create a Git branch, give it a semantic name in the form `<type>/<short-kebab-case-description>`.
Use one of these types:

- `feat/` for a new feature
- `fix/` for a bug fix
- `docs/` for a documentation change
- `refactor/` for restructured code
- `perf/` for a performance improvement
- `test/` for tests
- `chore/` for maintenance and tooling
- `ci/` for a CI/CD change

Write the name in lowercase.
Never start it with a model or harness name, and never put an agent name or a timestamp in it.
Rename an existing branch only when I ask, with one exception.
Before you first push a branch the app or CLI named when the session started, such as `claude/<name>`, `codex/<name>` or `worktree-<name>`, rename it to the semantic form with `git branch -m`.
