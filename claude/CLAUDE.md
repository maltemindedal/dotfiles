@~/.claude/pstack-models.md

Always use poteto mode: invoke the `pstack:poteto-mode` skill at the start of every task and follow its instructions, regardless of task size.

When you reach a design or technical decision, do not ask me to choose.
Take the option you recommend and continue.
In your final reply, list each such decision with one sentence on why and what the alternative was.
If the session model is not Fable, a Fable subagent makes the call: give it the options and the evidence, not your recommendation.

Still stop and ask in three cases.
The decision changes what the product does for its users.
The decision changes an issue's scope or conflicts with a rule in a project CLAUDE.md.
The action cannot be undone, such as a deploy, a production data change or a message sent for me.

When you merge a PR, choose the merge method by what its commits are.
A rule in a project CLAUDE.md, AGENTS.md or CONTRIBUTING.md takes precedence over these.
Merge only after you have checked that every CI check is green.

- Merge commit when the PR's commits are separate changes, or when a doc cites one of them by hash. It is the only method that keeps those hashes, so use it when unsure.
- Squash when the commits are fix-ups of one change. Write the combined commit message yourself, in the repo's commit format.
- Rebase for a single commit whose message already follows that format, such as a Dependabot bump.
