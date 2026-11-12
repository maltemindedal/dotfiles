#!/bin/sh
# The PreToolUse hook in claude/settings.json must block an Agent call that asks
# for Claude Code's own worktree in a T3 Code session, and allow every other call.
#
#   sh tests/claude_hooks_test.sh
set -eu

REPO="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
fails=0

pass() { printf 'ok   %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }

if ! command -v jq > /dev/null 2>&1; then
  echo "skip jq not on PATH, hook not tested"
  exit 0
fi

HOOK="$(jq -r '.hooks.PreToolUse[] | select(.matcher == "Agent|Task") | .hooks[0].command' "$REPO/claude/settings.json")"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

expect() { # expect <name> <entrypoint> <tool input json> <exit code>
  set +e
  printf '{"tool_name":"Agent","tool_input":%s}' "$3" |
    CLAUDE_CODE_ENTRYPOINT="$2" sh -c "$HOOK" > /dev/null 2> "$TMP/err"
  code=$?
  set -e
  if [ "$code" -eq "$4" ]; then pass "$1: exits $4"; else fail "$1: exits $4, got $code"; sed 's/^/     |/' "$TMP/err"; fi
}

expect "t3 worktree" t3-code '{"isolation":"worktree","prompt":"x"}' 2
if grep -q delegate_task "$TMP/err"; then pass "t3 worktree: names delegate_task"; else fail "t3 worktree: names delegate_task"; fi
expect "t3 no isolation" t3-code '{"prompt":"x"}' 0
expect "t3 remote isolation" t3-code '{"isolation":"remote","prompt":"x"}' 0
expect "cli worktree" cli '{"isolation":"worktree","prompt":"x"}' 0
expect "no entrypoint worktree" '' '{"isolation":"worktree","prompt":"x"}' 0

echo
if [ "$fails" -eq 0 ]; then echo "all claude hook tests passed"; else echo "$fails claude hook test(s) failed"; exit 1; fi
