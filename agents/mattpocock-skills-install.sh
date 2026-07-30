#!/usr/bin/env bash
#
# agents/mattpocock-skills-install.sh — install a curated subset of Matt
# Pocock's public skills collection (github.com/mattpocock/skills, 41 skills
# total) for Claude Code, Cursor, and Continue, at global scope.
#
# Curated for: solo software projects + research/ML work, with "jumps to
# code too fast" and "no tests" as the pain points to fix. See README.md's
# "Coding agents" section for the reasoning behind this specific subset and
# what was left out.
#
# IMPORTANT: always pass -g (global scope) — see the comment in
# caveman-install.sh for what happens without it (drops project-scoped
# .agents/.continue/skills-lock.json into whatever directory you're in).
#
# git-guardrails-claude-code is installed for Claude Code only — it's
# Claude-Code-hook-specific and has no Cursor/Continue equivalent. Once
# copied to ~/.claude/skills/, its hook + settings.json wiring already lives
# in agents/hooks/block-dangerous-git.sh + agents/claude-settings.json — this
# script does not re-run that setup, just re-fetches the skill files.

set -euo pipefail

CORE=(-s grill-with-docs -s tdd -s implement -s research -s diagnosing-bugs -s code-review)

echo "==> Claude Code"
npx -y skills add mattpocock/skills -a claude-code "${CORE[@]}" -s git-guardrails-claude-code -g -y

echo "==> Cursor"
npx -y skills add mattpocock/skills -a cursor "${CORE[@]}" -g -y

echo "==> Continue"
npx -y skills add mattpocock/skills -a continue "${CORE[@]}" -g -y
