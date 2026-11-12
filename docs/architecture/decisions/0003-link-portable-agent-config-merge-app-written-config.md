# 0003. Link portable agent config and merge config that apps write

- Status: accepted
- Date: 2026-11-12

## Context

One `./install.sh` on a new Mac should reproduce the agent setup for Claude Code, Codex and the Cursor CLI, with agent attribution in commits and PRs turned off. The agent config files are of two kinds:

- `~/.claude/settings.json`, `~/.claude/CLAUDE.md` and `~/.claude/pstack-models.md` hold only settings and instructions that are the same on every machine. Claude Code writes changes through a symlinked `settings.json` and keeps the link.
- `~/.codex/config.toml` and `~/.cursor/cli-config.json` mix user preferences with state the apps write themselves. Codex adds `notify`, `[projects."…"]`, `[marketplaces.*]`, `[plugins.*]`, `[mcp_servers.*]` and `[tui]`, several with absolute paths under `/Users/`. The Cursor CLI adds `version`, `hasChangedDefaultModel` and `runEverythingSettingsPromptStreak`. A linked file would put that state in `git status` and commit host paths.

## Decision

- **Link the Claude Code files.** `install.sh` symlinks `claude/settings.json`, `claude/CLAUDE.md` and `claude/pstack-models.md` into `~/.claude/` with the same `link` helper as the shell files.
- **Merge the Codex and Cursor CLI files.** The repo tracks only the user preferences: in `codex/config.toml`, `model`, `model_reasoning_effort`, `commit_attribution` and the `[desktop]` table; in `cursor/cli-config.json`, every user preference including `attribution`. `install.sh` puts each tracked top-level key and table in place of the live one of the same name and keeps everything else. When there is no live file, it copies the tracked one. It writes only when the result differs, and moves the old file to `<name>.<timestamp>.bak` first.
- **No Python.** The TOML merge is table-granular `awk`, because the Python 3.9 in the Command Line Tools has no `tomllib`. The JSON merge is a shallow `jq` merge. Without `jq`, `install.sh` skips an existing Cursor file with a warning, as it does for `--tools` without Homebrew.
- **Not tracked:** `~/.claude/settings.local.json`, `~/.cursor/mcp.json`, `~/.agents/skills` and the Cursor app's settings. The Cursor app keeps its attribution switch in its own storage, so [Getting started](../../getting-started.md) has a manual step for it.

## Consequences

- A change to a tracked Codex or Cursor CLI key made in the app is reverted by the next `./install.sh`, unless the repo file is changed too.
- A change to `claude/settings.json`, through `/config` or a permission prompt, shows in `git status`, as `git config --global` does for `git/.gitconfig`.
- `claude/settings.json` is the live permission and sandbox config of every Claude Code agent on the machine, so a merged change to it changes what agents may do there.
- The TOML merge is line-based: a value that continues onto a line that looks like `key =` or `[table]` is misread. The tracked file keeps single-line values.
