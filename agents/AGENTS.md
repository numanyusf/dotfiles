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
- Never invent a commit message that hides what changed; summarize the "why"
  in 1-2 sentences.
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
