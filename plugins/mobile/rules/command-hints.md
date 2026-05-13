---
description: Proactive hints for mobile plugin slash commands — when to suggest each
alwaysApply: true
---

# Mobile Command Hints

Proactively suggest the appropriate slash command when the conditions below apply. Do not wait for the user to ask.

- When the user provides a **ticket ID and requirements**, suggest `/specs` — runs the full 5-step development workflow (`../commands/specs.md`).
- When development and tests are complete and there are uncommitted changes, suggest `/commit` — formats, stages, commits, and pushes (`../commands/push.md`).
- When the current branch has commits not yet in a Merge Request, suggest `/mr` — creates a GitLab MR with a conventional title (`../commands/mr.md`).
- When the user asks what commands or skills are available, run `/help` immediately — lists all commands and skills (`../commands/help.md`).
