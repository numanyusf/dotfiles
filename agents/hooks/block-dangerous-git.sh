#!/bin/bash
# Shared git guardrail for Claude Code (PreToolUse/Bash) and Cursor
# (beforeShellExecution). Blocks destructive git commands even if the agent
# was told to run them — run those yourself in a real terminal when you mean it.
#
# Claude: reads .tool_input.command; on block prints to stderr and exits 2.
# Cursor: reads .command; on block/allow returns JSON permission on stdout.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.command // .tool_input.command // empty')
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // empty')

is_cursor=0
if [[ "$EVENT" == "beforeShellExecution" ]] || echo "$INPUT" | jq -e 'has("command") and (has("tool_input") | not)' >/dev/null 2>&1; then
  is_cursor=1
fi

DANGEROUS_PATTERNS=(
  "git push"
  "git reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \."
  "git restore \."
  "push --force"
  "reset --hard"
)

allow() {
  if [[ "$is_cursor" -eq 1 ]]; then
    echo '{"permission":"allow"}'
  fi
  exit 0
}

deny() {
  local pattern="$1"
  local msg="BLOCKED: '$COMMAND' matches dangerous pattern '$pattern'. The user has prevented you from doing this. Run it yourself in a terminal if you really mean it."
  if [[ "$is_cursor" -eq 1 ]]; then
    jq -n \
      --arg um "$msg" \
      --arg am "$msg" \
      '{permission:"deny", user_message:$um, agent_message:$am}'
    exit 0
  fi
  echo "$msg" >&2
  exit 2
}

if [[ -z "$COMMAND" ]]; then
  allow
fi

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    deny "$pattern"
  fi
done

allow
