# 0006 — Session handoff through docs/STATUS.md

- **Status:** accepted
- **Date:** 2026-10-01

## Context
The owner wants to resume the build from any new session (a new chat, Claude Code in VS Code, another agent) without starting over.

## Decision
The repos are the memory. `CLAUDE.md` in each repo points to `sotto-platform/docs/STATUS.md`, which every PR updates with: current phase, done, in progress, next step, blockers, open decisions.

## Consequences
STATUS updates are part of every PR's checklist. Chat history is never required.
