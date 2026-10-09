#!/usr/bin/env bash
#
# agents/mcp-servers.sh — register the MCP servers this machine's Claude Code
# uses, at user scope (available in every project on this machine).
#
# Homelab: only Markitdown (Office/HTML/audio → Markdown; Claude reads PDFs and
# images natively). Needs uv (`uvx`). The work box's Claude has its own config,
# so run the same `claude mcp add` inside it too. 1Password's MCP needs the
# desktop app, so it lives on the laptop (`windows` branch), never here.
# Figma/Vercel were dropped while unused; re-add with:
#   claude mcp add --transport http figma-remote-mcp https://mcp.figma.com/mcp --scope user
#   claude mcp add --transport http vercel https://mcp.vercel.com --scope user
#
# Idempotent: re-running is safe, `claude mcp add` failing because a server
# already exists is not treated as an error.

set -uo pipefail

add() {
  echo "==> $*"
  claude mcp add "$@" || echo "    (skipped — see message above, likely already exists)"
}

add --transport stdio markitdown --scope user -- uvx markitdown-mcp@0.0.1a7
