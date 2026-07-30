# Agent rules

General, tool-agnostic rules for AI coding agents working in any project on
this machine. Claude Code reads this file via a `~/.claude/CLAUDE.md`
symlink; other tools (Cursor, Copilot, Codex CLI, Aider, etc.) read it
natively as `AGENTS.md` at a project root, or via the mirrored
`agents/cursor-general.mdc` for Cursor's global rules.

## Verification

- Don't answer questions about deprecations, APIs, config schemas, or CLI
  flags from memory alone — check the real source (official docs, the
  installed tool's own `--help`/config files, GitHub issues) before stating
  it as fact. Tooling and APIs change fast; a confident wrong answer is worse
  than admitting you need to check.

## Git and destructive actions

- Ask before anything hard to reverse or visible to others: force-push,
  `git reset --hard`, amending a pushed commit, `git push`, opening/closing
  PRs or issues, or deleting branches/files that weren't created this
  session.
- Commit or open a PR only when the user explicitly asks.
- Never invent a commit message that hides what changed; summarize the "why"
  in 1-2 sentences.
- Never add `Co-Authored-By`, `Signed-off-by`, or any AI/tool authorship
  trailer. Message body is user-facing only (why/what).
- Run `git status` before any command that could discard uncommitted work.

## Secrets

- Never run a command that prompts for a passphrase, PIN, biometric touch,
  or 2FA code through an automated shell tool — hand it to the user to run
  themselves in their own terminal.
- Don't paste secret values (tokens, keys, passwords) into chat, logs, or
  commit messages, even when quoting a file that contains one.

## Code changes

- Prefer editing existing files over creating new ones.
- Don't add abstractions, refactors, or defensive error handling beyond what
  the task requires. No speculative features or backwards-compatibility
  shims for hypothetical future needs.
- Comments explain non-obvious *why* (a constraint, a workaround, a subtle
  invariant) — not *what* the code does. Default to no comments.
- Match the surrounding code's existing style and conventions rather than
  introducing a new one.

## Scope

- Do only what was asked. If a task looks bigger than what was requested,
  say so and confirm before expanding scope.

## MCP servers (this machine)

Prefer these machine-global MCP servers over inventing token/curl workflows.
Do not print values returned from them (especially 1Password).

| Server | Use for |
|--------|---------|
| `1password` | Developer Environments / env vars — never echo secrets |
| `figma` | Design context / implement from Figma |
| `vercel` | Any Vercel project: deploys, build/runtime logs, project status, docs |
| `markitdown` | Convert PDF/Office/images/etc. → Markdown |

**Cursor:** `~/.dotfiles/agents/cursor-mcp.json` → `~/.cursor/mcp.json`.  
**Claude Code:** `~/.dotfiles/agents/mcp-servers.sh` (user scope; same four servers).  

Auth is per client (`cursor-agent mcp login <server>`, or Claude `/mcp`). Approvals persist across sessions — do not re-enable every time. If Cursor `mcp enable` fails with global-only config, symlink the central `cursor-mcp.json` into `<project>/.cursor/mcp.json`.

Destructive git (`git push`, `reset --hard`, `clean -f`, `branch -D`, etc.) is **hard-blocked** for both Cursor (`beforeShellExecution`) and Claude Code (`PreToolUse`) via `~/.dotfiles/agents/hooks/block-dangerous-git.sh`. Run those yourself in a real terminal when you mean them.

## Graphify (when a project has a graph)

CLI is global (`graphify`). Graphs live per repo in `graphify-out/`.

- If `graphify-out/graph.json` exists: prefer `graphify query` / `path` / `explain` /
  `affected` / `god-nodes` for symbol and architecture discovery before Grep.
- If missing: use normal search; build with `graphify update .` (or
  `graphify extract . --code-only`) when you want a graph.
- After substantive code edits in a graph’d repo: `graphify update .`.

Cursor also loads `agents/cursor-graphify.mdc` → `~/.cursor/rules/graphify.mdc`
(`alwaysApply`, guarded on graph presence).
