#!/usr/bin/env bash
#
# agents/mcp-servers.sh — register the standard MCP servers with Claude Code
# at user scope (available in every project on this machine).
#
# Not run automatically by bootstrap.sh: needs the `claude` CLI already
# installed, and 1Password's server needs Settings > Labs > "Enable local
# MCP server" turned on in the 1Password app first.
#
# Idempotent: re-running is safe, `claude mcp add` failing because a server
# already exists is not treated as an error.
#
# After running this, start `claude` and run `/mcp` to finish the OAuth
# login for figma-remote-mcp and vercel.

set -uo pipefail

add() {
  echo "==> $*"
  claude mcp add "$@" || echo "    (skipped — see message above, likely already exists)"
}

add --transport http figma-remote-mcp https://mcp.figma.com/mcp --scope user
add --transport stdio markitdown --scope user -- uvx markitdown-mcp@0.0.1a7
# WSL has no Linux 1password-mcp; run the Windows one through interop instead.
OP_MCP=1password-mcp
if ! command -v "$OP_MCP" >/dev/null 2>&1 && grep -qi microsoft /proc/version 2>/dev/null; then
  OP_MCP="$(wslpath "$(cmd.exe /c 'echo %LOCALAPPDATA%' 2>/dev/null | tr -d '\r')")/Microsoft/WindowsApps/1password-mcp.exe"
fi
add --transport stdio 1password --scope user -- "$OP_MCP"
add --transport http vercel https://mcp.vercel.com --scope user

echo
echo "Run 'claude' then '/mcp' to finish OAuth login for figma-remote-mcp and vercel."
