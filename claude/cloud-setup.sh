#!/bin/bash

CLAUDE_DIR="$HOME/.claude"

cap() {
  if command -v timeout >/dev/null 2>&1; then timeout 120 "$@"; else "$@"; fi
}

install_plugin() {
  local repo="$1" plugin="$2" marketplace="${2#*@}" log
  if ! command -v claude >/dev/null 2>&1; then
    echo "plugins: claude CLI not on PATH, skipping $plugin"
    return
  fi
  if log=$({
    cap claude plugin marketplace add "$repo" ||
      cap claude plugin marketplace update "$marketplace"
    cap claude plugin install "$plugin" --scope user
  } 2>&1); then
    echo "plugins: installed $plugin"
  else
    echo "plugins: could not install $plugin, skipping:"
    printf '%s\n' "$log" | tail -n 5 | sed 's/^/  /'
  fi
}

write_file() {
  local file="$CLAUDE_DIR/$1"
  if mkdir -p "$CLAUDE_DIR" && cat > "$file"; then
    echo "setup: wrote $file"
  else
    echo "setup: could not write $file, skipping"
  fi
}

disable_attribution() {
  local file="$CLAUDE_DIR/settings.json" merged
  if ! command -v jq >/dev/null 2>&1; then
    echo "settings: jq not on PATH, skipping attribution"
    return
  fi
  mkdir -p "$CLAUDE_DIR" && [ -f "$file" ] || echo '{}' > "$file"
  if merged=$(jq '.attribution = {commit: "", pr: "", sessionUrl: false}' "$file") &&
    printf '%s\n' "$merged" > "$file"; then
    echo "settings: turned off commit and PR attribution in $file"
  else
    echo "settings: could not update $file, skipping attribution"
  fi
}

install_plugin michael-denyer/pstack-claude pstack@pstack-claude
disable_attribution

write_file CLAUDE.md <<'EOF'
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

@~/.claude/merge-rules.md
EOF

write_file pstack-models.md <<'EOF'
# pstack model configuration

Per-role model overrides for pstack skills. Each pstack SKILL.md names its defaults in a Models section; the values here override those defaults. Delete a line to fall back to the skill default. A value of `inherit-parent` or `auto` runs that role on the parent session's model (the `Agent` call omits `model`); an alias entry in a panel list still counts toward that panel's fan-out. A model may carry a reasoning effort, as in `opus @xhigh` (levels: low, medium, high, xhigh, max); the role's subagent then runs at that level, each entry of a panel list on its own. `default effort` sets the level for a value without one; `session` uses the runtime's platform mapping to start from the parent session's effort. On Codex this requires active-turn metadata or an explicit effort choice. `session hook: off` stops the Claude Code, Codex, or Muse SessionStart hook, or the pstack Pi extension, from injecting the poteto-mode mandate; any other value, or no line, leaves it on.

feature, refactoring: sonnet
bug-fix: opus
perf-issue: opus
hillclimb: opus
judgment and prose: opus
strongest judgment: fable
how explorer: opus
how explainer: opus
why investigators: opus
why synthesizer: opus
reflect tooling: opus
reflect judgment, divergent, synthesizer: opus
arena runners: opus, fable, sonnet, haiku
arena cross-judge pool: opus, fable, sonnet, haiku
swarm workers: opus
architect runners: opus, fable, sonnet, haiku
interrogate reviewers: opus, fable, sonnet, haiku

default effort: session
session hook: on
EOF

write_file merge-rules.md <<'EOF'
# Tests and merging

- CI is the normal gate for a pull request. When CI cannot run because the GitHub Actions minutes are used up (checks never start, or fail at once with a billing or spending-limit message), gate on local tests instead: run the project's full test suite locally and treat a pass as the gate. Do not wait for CI or retry it. Say in the pull request that it was gated on local tests.
- When I say "merge" and the local tests have already passed on the commit being merged, merge right away. Do not run them again. Run them again only if the code changed after that pass.
- Merge only after the gate has passed. When CI is the gate, check yourself that every check is green.

# Merge method

Choose the merge method by what the pull request's commits are.
A rule in a project CLAUDE.md, AGENTS.md or CONTRIBUTING.md takes precedence over these.

- Merge commit when the commits are separate changes, or when a doc cites one of them by hash. It is the only method that keeps those hashes, so use it when unsure.
- Squash when the commits are fix-ups of one change. Write the combined commit message yourself, in the repo's commit format.
- Rebase for a single commit whose message already follows that format, such as a Dependabot bump.
EOF

exit 0
