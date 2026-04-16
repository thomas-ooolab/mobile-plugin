<p align="center">
  <img src="https://em-content.zobj.net/source/apple/391/electric-plug_1f50c.png" width="120" />
</p>

<h1 align="center">@ooolab/ooolab-plugin</h1>

<p align="center">
  <strong>one source of truth for AI rules across every project, every tool, every stack</strong>
</p>

<p align="center">
  <a href="#before--after">Before/After</a> •
  <a href="#install">Install</a> •
  <a href="#usage">Usage</a> •
  <a href="#stacks">Stacks</a> •
  <a href="#shared-content">Content</a> •
  <a href="#supported-tools">Tools</a> •
  <a href="#adding-new-content">Contribute</a> •
  <a href="#ci-integration">CI</a>
</p>

---

Internal plugin that registers the OOOLab marketplace in Claude Code, enabling native plugin loading by stack. No file copying — skills, agents, commands, and hooks load directly from the plugin source.

## Before / After

<table>
<tr>
<td width="50%">

### 😵 Without plugin

```
project-a/CLAUDE.md           ← hand-written, incomplete
project-a/.cursorrules         ← v3, outdated
project-b/CLAUDE.md           ← missing entirely
project-b/.cursorrules         ← v5, different from A
project-c/.cursor/rules/       ← someone's personal copy
```

Rules drift. New projects start from scratch. Onboarding is "copy from that other repo."

</td>
<td width="50%">

### ✅ With plugin

```bash
npx ooolab-plugin init --stack mobile
```

```jsonc
// .claude/settings.json — auto-written
{
  "extraKnownMarketplaces": {
    "ooolab": { "source": { "source": "github",
                            "repo": "thomas-ooolab/ooolab-plugin" } }
  },
  "enabledPlugins": { "mobile@ooolab": true }
}
```

Claude Code loads skills, agents, commands, and hooks natively. Always current — no sync needed.

</td>
</tr>
</table>

```
┌──────────────────────────────────────────┐
│  STACKS            ████████ mobile       │
│                    ░░░░░░░░ be (soon)    │
│                    ░░░░░░░░ fe (soon)    │
│  SHARED SKILLS     ████████ 13 skills   │
│  SHARED AGENTS     ████████ 5 agents    │
│  SHARED COMMANDS   ████████ 3 cmds      │
│  SUPPORTED TOOLS   ████████ 2 tools     │
│  FILES TO COPY     ░░░░░░░░ 0           │
└──────────────────────────────────────────┘
```

## Stacks

Content lives in `plugins/<stack>/`. Each stack is an independent plugin with its own rules, skills, agents, commands, and hooks.

| Stack | Status | Contents |
|-------|--------|----------|
| `mobile` | ✅ Active | Flutter/Dart — clean architecture, BLoC, Fastlane |
| `be` | 🔜 Soon | Backend — TBD |
| `fe` | 🔜 Soon | Frontend — TBD |

## Supported Tools

| Tool | Settings file | What gets registered |
|------|--------------|----------------------|
| **Claude Code** | `.claude/settings.json` | `extraKnownMarketplaces` + `enabledPlugins` |

More coming: Cursor, Windsurf, Copilot, Cline.

## Install

### As a Claude Code plugin (recommended — no CLI needed)

```
/plugin marketplace add thomas-ooolab/ooolab-plugin
/plugin install mobile@ooolab
```

Skills, agents, commands, and hooks load natively. Claude Code reads `plugins/mobile/` directly from the repo.

### Via CLI — register marketplace in project settings

```bash
# Run directly from GitHub, no install needed
npx github:thomas-ooolab/ooolab-plugin init --stack mobile

# Or install as devDependency
npm install --save-dev github:thomas-ooolab/ooolab-plugin
npx ooolab-plugin init --stack mobile

# Or install globally
npm install -g github:thomas-ooolab/ooolab-plugin
ooolab-plugin init --stack mobile
```

## Usage

### `init` — Register marketplace in project

```bash
# Mobile stack, both Claude + Cursor
npx ooolab-plugin init --stack mobile

# Preview only
npx ooolab-plugin init --stack mobile --dry-run

# Single tool
npx ooolab-plugin init --stack mobile -t claude
```

Output:

```
Initializing AI plugin (stack: mobile)...
  registered marketplace: ooolab (thomas-ooolab/ooolab-plugin)
  enabled plugin: mobile@ooolab
✓ claude configured

Done! AI configs installed.
```

Writes `.ooolab-plugin.json` (tracks stack + configured tools) and updates `.claude/settings.json`.

### `sync` — Re-register (idempotent)

```bash
npx ooolab-plugin sync                        # stack from .ooolab-plugin.json
npx ooolab-plugin sync --stack mobile         # explicit stack
npx ooolab-plugin sync --dry-run              # preview only
```

Since plugins load live from source, sync is mainly useful after switching stacks or adding tools.

### `list` — Browse available content

```bash
npx ooolab-plugin list                        # all stacks
npx ooolab-plugin list --stack mobile         # one stack
npx ooolab-plugin list --stack mobile -c skills
```

```
[mobile]

RULES
  development-workflow     — Development workflow (FVM, git, quality) and subagent delegation

SKILLS
  bash                     — Bash syntax, error handling, security, ShellCheck compliance
  clean                    — Layer separation, dependency rules, repositories, use cases
  dart                     — Naming, syntax, null safety, async, modern language features
  data                     — Retrofit API, remote/local data sources, models, DI (packages/data)
  di                       — get_it + injectable: annotations, modules, test overrides
  workflow                 — Git branching, feature development, CI/CD, code quality
  domain                   — Repository interfaces, use cases, domain exceptions (packages/domain)
  flutter                  — Widget architecture, composition rules, performance patterns
  git                      — Commits, branches, merges, rebases, conflict resolution, recovery
  presentation             — Screens, cubits, routes, barrel files (lib/screens/)
  ruby                     — Fastlane lane/helper design, env vars, shell safety, CI patterns
  state                    — Cubit/BLoC with flutter_bloc, @freezed states, DataLoadStatus
  test                     — Unit, widget, integration tests with bloc_test and mocktail

AGENTS
  code-reviewer            — Proactive Dart/Flutter + Clean Architecture code reviewer
  data-implementor         — Retrofit APIs, data sources, models, DI (packages/data)
  domain-implementor       — Repository interfaces, use cases, DI wiring (packages/domain)
  presentation-implementor — Screens, cubits, routes, views (lib/screens/)
  test-writer              — Write/update test suites after feature changes

COMMANDS
  mr                       — Create GitLab MR with conventional title + ticket ID
  push                     — Stage, commit (conventional message), push to origin
  specs                    — Accept ticket ID + requirements, run full 5-step dev workflow
```

## Shared Content

All shared content lives under `plugins/<stack>/` as Markdown with YAML frontmatter.

### Structure

```
plugins/
  mobile/                   # Flutter/Dart stack
    .claude-plugin/
      plugin.json           # Claude Code plugin manifest
    rules/                  # Coding standards (.md)
    skills/                 # Skill folders (each with SKILL.md)
    agents/                 # Agent definitions (.md)
    commands/               # Command templates (.md)
    hooks/
      hooks.json            # PostToolUse dart-format + SessionStart
    scripts/
      dart-format.sh        # Auto-format .dart files on edit
  be/                       # Backend stack (coming soon)
  fe/                       # Frontend stack (coming soon)
```

### File Format

```markdown
---
title: Human-readable title
description: One-line description (shown in `list`)
globs: "**/*.dart"        # Optional: file scope (Cursor)
alwaysApply: true          # Optional: auto-apply (Cursor)
---

Content here. Markdown supported.
```

### How It Works

```
npx ooolab-plugin init --stack mobile
        │
        └── .claude/settings.json ← extraKnownMarketplaces + enabledPlugins

Claude Code loads plugins natively:
  plugins/mobile/{skills,agents,commands,hooks}/  ← loaded directly from repo
```

| Command | What it does |
|---------|-------------|
| `init` | Write `.ooolab-plugin.json` + register marketplace in tool settings |
| `sync` | Re-register (idempotent — safe to run anytime) |
| `list` | Display available rules/skills/agents/commands per stack |

## Adding New Content

1. Create `.md` in the right dir under `plugins/<stack>/` (`rules/`, `skills/`, `agents/`, `commands/`)
2. Add frontmatter: `title` + `description` (minimum)
3. Write content
4. `npx ooolab-plugin list --stack <stack>` → verify it shows
5. Commit + push → all projects pick it up immediately (no re-sync needed)

## Adding a New Stack

1. Create `plugins/<stack>/` with `rules/`, `skills/`, `agents/`, `commands/` subdirs
2. Add `plugins/<stack>/.claude-plugin/plugin.json`
3. Register in `.claude-plugin/marketplace.json`
4. Add skills, agents, rules, commands

## Notes

- `.ooolab-plugin.json` tracks configured tools and active stack — commit this file
- No generated AI config files — Claude Code and Cursor read plugin content directly from the repo source

## License

Internal use only.
