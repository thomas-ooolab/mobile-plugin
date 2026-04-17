---
name: create-skill
description: >
  Guides authoring of new Claude Code skills (SKILL.md files). Use when the user
  wants to create a skill, add a skill to the project, or asks "how do I make a
  skill" / "create a skill for X" / "/create-skill".
---

# Creating a Skill

## File Layout

```
.claude/skills/<skill-name>/
└── SKILL.md                  # required — loaded when triggered
    references/               # optional — loaded on demand
    scripts/                  # optional — executed, not loaded into context
```

For user-global skills: `~/.claude/skills/<skill-name>/`.

## Frontmatter

```yaml
---
name: my-skill-name           # lowercase, hyphens only, ≤64 chars
description: >                # ≤1024 chars, 3rd person, non-empty
  Describes what the Skill does and when to use it. Include trigger
  phrases: "Use when user says X or Y, or when Z context is present."
---
```

**Description rules:**
- 3rd person only: "Processes Excel files" not "I can help with Excel"
- Include both: **what it does** + **when to use it** (trigger phrases)
- Specific beats generic: bad → "Helps with documents", good → "Extracts text from PDFs. Use when user mentions PDFs, forms, or document extraction."
- This is Claude's selection signal when 100+ skills are loaded — make it unambiguous

**Name rules:** `feat-verb-noun` gerund form preferred (`processing-pdfs`, `managing-db`). Avoid: `helper`, `utils`, reserved words (`anthropic-*`, `claude-*`).

## Body Content

**Default assumption: Claude is smart.** Only add context Claude doesn't have.
Ask: "Does Claude really need this?" before every paragraph.

**Keep under 500 lines.** Overflow → separate reference files (one level deep only).

| Task | Level of freedom |
|------|-----------------|
| Multiple valid approaches, context-dependent | High: prose instructions |
| Preferred pattern exists, some variation OK | Medium: pseudocode/template |
| Fragile sequence, must not deviate | Low: exact commands, no options |

## Recommended Sections

```markdown
## When to Use
- Bullet examples of user requests that trigger this skill

## Workflow
Step-by-step. For complex tasks, provide a copyable checklist:
- [ ] Step 1: ...
- [ ] Step 2: ...

## Reference
Links to bundled reference files (one level deep from SKILL.md)
```

## Progressive Disclosure

Reference files are loaded only when needed — zero token cost until read:

```markdown
## Quick start
[core usage inline]

## Advanced
For form filling: See [FORMS.md](FORMS.md)
For API reference: See [REFERENCE.md](REFERENCE.md)
```

**Never nest references** (SKILL.md → a.md → b.md). Claude may partial-read nested files.

## Writing the Description Field — Examples

```yaml
# Good
description: >
  Generates git commit messages in Conventional Commits format by analyzing
  staged diffs. Use when user asks for a commit message, says "write a commit",
  or invokes /commit.

# Bad
description: Helps with commits
```

## Checklist Before Shipping

```
- [ ] name: lowercase + hyphens, ≤64 chars, matches folder name
- [ ] description: 3rd person, what + when, specific trigger phrases
- [ ] SKILL.md body < 500 lines
- [ ] No time-sensitive info ("before Aug 2025 use old API")
- [ ] Terminology consistent throughout
- [ ] References are one level deep only
- [ ] Workflows have numbered steps or checkboxes
- [ ] Scripts handle errors (no silent failures)
- [ ] Tested on a real task
```

## Anti-Patterns

| Avoid | Do instead |
|-------|-----------|
| Windows paths `scripts\run.py` | Forward slashes `scripts/run.py` |
| Listing 5 lib options | Pick one default, mention alternative only if meaningfully different |
| Explaining what PDFs are | Assume Claude knows; just show the code |
| Nested refs (A→B→C) | All refs link from SKILL.md directly |
| Time-based conditionals | "Current method" + collapsible "Old patterns" section |
| Emoji anywhere in content | Plain words — `// GOOD` / `// BAD`, `CRITICAL:`, `WARNING:` not `✅`/`❌`/`⚠️` |

## MCP Tool References

Always fully qualify: `ServerName:tool_name` (e.g. `BigQuery:bigquery_schema`).
Without prefix, Claude may fail to locate the tool when multiple servers are loaded.
