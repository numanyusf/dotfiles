#!/usr/bin/env bash
#
# agents/caveman-install.sh — install the "caveman" output-compression
# skill/plugin (github.com/JuliusBrussee/caveman) for Claude Code, Cursor,
# and Continue.
#
# Not wired into bootstrap.sh: the Claude Code step shells out to `npx
# github:...`, which this machine's Claude Code auto-mode classifier treats
# as risky enough to require interactive approval — so run this by hand.
#
# On Claude Code, compression is ON by default from message one (SessionStart
# hook). Toggle per-session with `/caveman` or by saying "normal mode".
#
# On Cursor, default-on is wired separately in agents/cursor-general.mdc
# (alwaysApply) + agents/hooks/cursor-caveman-session.sh (sessionStart),
# via agents/cursor-hooks.json — not by this install script alone.
#
# IMPORTANT: run the per-agent (`-a ...`) steps with `-g` (global scope) from
# any directory. Without `-g`, the `skills` CLI defaults to *project* scope
# and drops a `.continue/`, `.agents/`, and `skills-lock.json` into whatever
# directory you happen to be in — which is how these first landed inside
# ~/.dotfiles by accident. Multiple agents can't be comma-separated in one
# `-a` call; run one `skills add` per agent.

set -euo pipefail

log()  { printf '\033[1;33m==>\033[0m %s\n' "$*"; }

log "Claude Code (plugin marketplace + install)"
curl -fsSL https://raw.githubusercontent.com/JuliusBrussee/caveman/main/install.sh -o /tmp/caveman-install.sh
bash /tmp/caveman-install.sh -- --only claude
rm -f /tmp/caveman-install.sh

log "Cursor (global skill copy)"
npx -y skills add JuliusBrussee/caveman -a cursor --skill '*' -g -y

log "Continue (global skill copy)"
npx -y skills add JuliusBrussee/caveman -a continue --skill '*' -g -y

echo
echo "Done. Start any Claude Code session and say 'caveman mode', or run /caveman."
echo "Uninstall: npx -y github:JuliusBrussee/caveman -- --uninstall"
