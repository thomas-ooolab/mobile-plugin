---
description: Build plugin artifacts (rules, commands, skills, agents) for AI tools under plugins/**
---

/caveman:caveman ultra

Build plugin artifacts for a reusable AI tool plugin under `plugins/`.

User requirements: $ARGUMENTS

## Step 1 — Identify target plugin

Run:
`!ls plugins/`

- Single dir found → use it automatically, no prompt
- Multiple dirs found → ask user once: "Which plugin? [list them]"

## Step 2 — Plan artifacts

Scan existing files under the target plugin dir to avoid duplicating what already exists:
`!find plugins/<name> -type f -name "*.md" | sort`

From requirements + existing structure, determine what to create or update:

| Artifact | Path | When |
|----------|------|------|
| Rule | `plugins/<name>/rules/<rule-name>.md` | Always-applied constraints, project-wide behavior |
| Command | `plugins/<name>/commands/<cmd-name>.md` | User-invocable slash commands |
| Skill | `plugins/<name>/skills/<skill-name>/SKILL.md` | Reusable multi-step workflows |
| Agent | `plugins/<name>/agents/<agent-name>.md` | Specialized subagent with defined persona/role |

Present plan to user:
- List each artifact: type, path, create/update, one-line purpose

Simple plan (auto-proceed): 1-2 new files, no existing files modified, requirements unambiguous.
Complex plan (wait for confirm): 3+ files, any existing file updated, or requirements have unclear scope.

## Step 3 — Implement

After user confirms, create each artifact. Load only the guide for the artifact type(s) in the plan:

- Creating or modifying a Rule → @create-rule
- Creating or modifying a Command → @create-command
- Creating or modifying a Skill → @create-skill
- Creating or modifying an Agent → @create-agent

Do not load guides for artifact types not in the plan.

## Step 4 — Update README

If any artifact was created or modified under `plugins/`, update `README.md`:

- Counts in the ASCII box (skills, agents, commands) if changed
- Skills/agents/commands listing table — add, remove, or update description rows to match current `plugins/mobile/{skills,agents,commands}/`
- Any new stack additions update the Stacks table

Skip this step if no `plugins/` files were changed.

## Step 5 — Self-review

After all artifacts created, apply each guide's checklist to its artifact type.

If violations found:
- Simple fix (rename, frontmatter tweak, remove emoji) → auto-fix, no prompt
- Complex fix (restructure content, split file, rethink scope) → show issue + proposed fix, wait for confirm

If violations remain → repeat Step 4 until clean.

Once all checks pass: notify user "All clean — running /commit in 30s. Reply to cancel.", wait 30 seconds, then run `/commit`.
