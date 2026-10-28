#!/usr/bin/env bash
#
# agents/claude-accounts-sync.sh — give both Claude Code accounts the same
# setup: personal-pro (~/.claude) and tuni-team (~/.claude-tuni-team, the
# `tuni-team` alias in bashrc). Re-run after adding or removing a skill or plugin.
#
# - tuni-team gets CLAUDE.md + settings.json from agents/ (same as ~/.claude)
# - every skill in ~/.claude/skills is linked into tuni-team; `synced/` stays
#   per account (claude.ai skills sync there for each login)
# - plugins install per account, so both get exactly the marketplaces and
#   enabledPlugins from agents/claude-settings.json; any other plugin is removed
#
# Project memory is shared separately: ~/.claude-memory/<project> via each
# project's .claude/settings.local.json autoMemoryDirectory.
set -euo pipefail

DOTFILES="$HOME/.dotfiles"
SETTINGS="$DOTFILES/agents/claude-settings.json"
TUNI="$HOME/.claude-tuni-team"

mkdir -p "$TUNI/skills"
ln -sfn "$DOTFILES/agents/AGENTS.md" "$TUNI/CLAUDE.md"
ln -sfn "$SETTINGS" "$TUNI/settings.json"

for skill in "$HOME/.claude/skills"/*/; do
  name=$(basename "$skill")
  [ "$name" = synced ] && continue
  ln -sfn "${skill%/}" "$TUNI/skills/$name"
done
find "$TUNI/skills" -maxdepth 1 -xtype l -delete   # skills removed from ~/.claude

# ~/.claude is the default config dir, so it runs without CLAUDE_CONFIG_DIR
for dir in "" "$TUNI"; do
  run() { if [ -n "$dir" ]; then CLAUDE_CONFIG_DIR="$dir" claude plugin "$@"; else claude plugin "$@"; fi; }
  echo "== ${dir:-$HOME/.claude}"
  jq -r '.extraKnownMarketplaces // {} | .[].source.repo' "$SETTINGS" | while read -r repo; do
    run marketplace add "$repo"
  done
  wanted=$(jq -r '.enabledPlugins // {} | to_entries[] | select(.value) | .key' "$SETTINGS")
  for plugin in $wanted; do run install "$plugin"; done
  run list --json | jq -r '.[].id' | while read -r plugin; do
    grep -qxF "$plugin" <<<"$wanted" || run uninstall "$plugin"
  done
done
