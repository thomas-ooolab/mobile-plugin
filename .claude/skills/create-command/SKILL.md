---
name: create-command
description: >
  Creates custom slash commands as markdown files in .claude/commands/ or
  .claude/skills/. Use when user says "create a slash command", "add a /command",
  "make a custom command", or "how do I make /X".
---

# Creating Custom Slash Commands

## File Locations

| Scope | Path | Notes |
|-------|------|-------|
| Project | `.claude/commands/<name>.md` | Only current project. Legacy — prefer skills |
| Personal | `~/.claude/commands/<name>.md` | All projects. Legacy — prefer skills |
| Project skill | `.claude/skills/<name>/SKILL.md` | Preferred for complex commands |
| Personal skill | `~/.claude/skills/<name>/SKILL.md` | Preferred for reusable personal commands |

**Rule of thumb:** Simple one-shot prompt → `.claude/commands/`. Multi-step workflow with references → `.claude/skills/`.

## Minimal Command

File: `.claude/commands/refactor.md`
```
Refactor the selected code to improve readability and maintainability.
Focus on clean code principles and best practices.
```

Invoked as `/refactor`.

## With Frontmatter

```yaml
---
allowed-tools: Read, Grep, Glob
description: Run security vulnerability scan
model: claude-opus-4-6
---

Analyze the codebase for security vulnerabilities including:
- SQL injection risks
- XSS vulnerabilities
- Exposed credentials
- Insecure configurations
```

**Frontmatter fields:**
- `allowed-tools` — restrict which tools Claude may use
- `description` — shown in command picker
- `model` — override default model for this command

## Dynamic Features

**Arguments** — positional placeholders `$1`, `$2`, etc:
```markdown
Review the $1 module and check for $2 issues.
```
Invoked as `/review auth security`.

**Bash execution** — backtick-wrapped `!` prefix:
```markdown
Current branch status:
`!git status`
`!git log --oneline -10`

Summarize recent changes and suggest next steps.
```

**File injection** — `@` prefix embeds file contents:
```markdown
Review @package.json and @src/config.ts for mismatches.
```

## Namespacing

Subdirectories create namespaced commands:
```
.claude/commands/
  frontend/
    component.md    → /frontend:component
  backend/
    migrate.md      → /backend:migrate
  review.md         → /review
```

## Workflow

- [ ] 1. Decide scope: project (`.claude/`) or personal (`~/.claude/`)
- [ ] 2. Decide type: simple prompt → `commands/`, complex workflow → `skills/`
- [ ] 3. Create file at correct path with `.md` extension
- [ ] 4. Add frontmatter if restricting tools, setting model, or adding description
- [ ] 5. Write prompt body — use `$1`/`$2` for args, `` `!cmd` `` for bash, `@file` for file refs
- [ ] 6. Test: type `/` in Claude Code to confirm command appears

## Checklist

```
- [ ] Filename is lowercase, hyphens only, no spaces
- [ ] Path is correct for intended scope
- [ ] Frontmatter YAML is valid (if present)
- [ ] Bash commands in backtick+! syntax: `!command`
- [ ] File refs use @ prefix: @path/to/file
- [ ] Command appears in / picker after creation
- [ ] No emoji — use plain words (GOOD/BAD, CRITICAL:, WARNING:) instead of ✅/❌/⚠️
```
