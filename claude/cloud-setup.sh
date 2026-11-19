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
  if mkdir -p "${file%/*}" && cat > "$file"; then
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
  if merged=$(jq '.attribution = {commit: "", pr: "", sessionUrl: false} | .includeCoAuthoredBy = false' "$file") &&
    printf '%s\n' "$merged" > "$file"; then
    echo "settings: turned off commit and PR attribution in $file"
  else
    echo "settings: could not update $file, skipping attribution"
  fi
}

install_zsh() {
  local log
  if command -v zsh >/dev/null 2>&1; then
    echo "zsh: already installed"
    return
  fi
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "zsh: apt-get not on PATH, skipping"
    return
  fi
  # The image ships its own /etc/zsh/zshrc, so dpkg would stop at a conffile prompt.
  if log=$({
    cap apt-get update &&
      DEBIAN_FRONTEND=noninteractive cap apt-get -o Dpkg::Options::=--force-confold install -y zsh
  } 2>&1); then
    echo "zsh: installed"
  else
    echo "zsh: could not install, skipping:"
    printf '%s\n' "$log" | tail -n 5 | sed 's/^/  /'
  fi
}

install_plugin cursor/plugins pstack@cursor-plugins
install_zsh
disable_attribution

write_file CLAUDE.md <<'EOF'
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
EOF

write_file rules/pstack-models.md <<'EOF'
# pstack model configuration. One line per role. Delete a line to fall back to the skill default.
# `inherit-parent` or `auto` as a value: the role runs on the parent chat model (omit Agent `model`). Alias entries in a panel list still count toward its fan-out.
# defaults: 3
# budget: large (xhigh)
feature, refactoring: opus xhigh
bug-fix: opus xhigh
perf-issue: opus xhigh
hillclimb: opus xhigh
judgment and prose: opus xhigh
arena runners: fable high, opus high, inherit-parent
arena cross-judge pool: opus high, inherit-parent
swarm workers: opus high
interrogate reviewers: fable high, opus high, inherit-parent
EOF

write_file rules/poteto-mode.md <<'EOF'
Invoke the `pstack:poteto-mode` skill and follow its instructions when a task meets any of these:

- it touches more than one file, or changes a signature other files call
- it involves a design or architecture choice
- it is a bug whose cause is not yet known, or a performance issue

For smaller tasks, such as a contained change to one file with an obvious test, a question, or a one-line edit, work directly and verify on the real artifact.

When the intent is already specific, enter that skill directly: `pstack:tdd`, `pstack:architect`, `pstack:how`, `pstack:why`, `pstack:arena`, `pstack:interrogate`.
EOF

exit 0
