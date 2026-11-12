# 0004. One instructions file, linked to each agent's global path

- Status: accepted
- Date: 2026-11-12

## Context

Claude Code and Codex each read global instructions from their own path: Claude Code from `~/.claude/CLAUDE.md`, Codex from `~/.codex/AGENTS.md` (or `$CODEX_HOME/AGENTS.md`). The owner wants the same instructions in both. The repo tracked them as `claude/CLAUDE.md`, linked only for Claude Code, so Codex sessions got none.

## Decision

- **One source.** The instructions live in `agents/AGENTS.md`, a top-level directory that belongs to no single agent. The file keeps the `@~/.claude/pstack-models.md` import as its first line; Claude Code expands it, and Codex reads it as plain text.
- **Linked by `install.sh`.** The `link` helper links `agents/AGENTS.md` to `~/.claude/CLAUDE.md` and to `~/.codex/AGENTS.md`.
- **No symlink in the repo.** A `claude/CLAUDE.md` symlink to `../agents/AGENTS.md` would let each agent directory mirror its home path, but a Windows checkout without Developer Mode writes a symlink as a text file holding the target path.
- **The cloud copy stays a heredoc.** `claude/cloud-setup.sh` still writes `~/.claude/CLAUDE.md` from a heredoc, and `tests/claude_cloud_setup_test.sh` compares it byte for byte with `agents/AGENTS.md`.

## Consequences

- An edit to `agents/AGENTS.md` changes the instructions of both agents at once.
- One repo file has two link targets, so a target count is no longer a file count.
- A machine set up before this change keeps a `~/.claude/CLAUDE.md` link to the deleted `claude/CLAUDE.md` after `git pull`. Run `./install.sh` again to repoint it.
