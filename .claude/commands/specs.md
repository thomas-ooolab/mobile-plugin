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

After user confirms, create each artifact following authoring guides:

- Rules → @.claude/skills/create-rule/SKILL.md
- Commands → @.claude/skills/create-command/SKILL.md
- Skills → @.claude/skills/create-skill/SKILL.md
- Agents → @.claude/skills/create-agent/SKILL.md

## Step 4 — Self-review

After all artifacts created, apply each guide's checklist to its artifact type.

If violations found:
- Simple fix (rename, frontmatter tweak, remove emoji) → auto-fix, no prompt
- Complex fix (restructure content, split file, rethink scope) → show issue + proposed fix, wait for confirm

If violations remain → repeat Step 4 until clean.

Once all checks pass: run `/commit` automatically.
