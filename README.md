<p align="center">
  <img src="https://em-content.zobj.net/source/apple/391/electric-plug_1f50c.png" width="120" />
</p>

<h1 align="center">@ooolab/mobile-plugin</h1>

<p align="center">
  <strong>one source of truth for AI rules across every project and every tool</strong>
</p>

<p align="center">
  <a href="#before--after">Before/After</a> •
  <a href="#install">Install</a> •
  <a href="#usage">Usage</a> •
  <a href="#shared-content">Content</a> •
  <a href="#supported-tools">Tools</a> •
  <a href="#adding-new-content">Contribute</a> •
  <a href="#ci-integration">CI</a>
</p>

---

Internal CLI plugin that distributes shared **rules**, **skills**, **agents**, and **commands** to Claude Code and Cursor from a single source. Define once in `shared/`, run `sync`, every project gets the same AI context — no copy-paste, no drift.

## Before / After

<table>
<tr>
<td width="50%">

### 😵 Without plugin

```
project-a/.cursorrules        ← v3, outdated
project-a/CLAUDE.md           ← hand-written, incomplete
project-b/.cursorrules        ← v5, different from A
project-b/CLAUDE.md           ← missing entirely
project-c/.cursor/rules/      ← someone's personal copy
```

Rules drift. New projects start from scratch. Onboarding is "copy from that other repo."

</td>
<td width="50%">

### ✅ With plugin

```bash
npx @ooolab/mobile-plugin init
```

```
project-a/CLAUDE.md           ← synced ✓
project-a/.cursorrules         ← synced ✓
project-b/CLAUDE.md           ← synced ✓
project-b/.cursorrules         ← synced ✓
project-c/CLAUDE.md           ← synced ✓
project-c/.cursorrules         ← synced ✓
```

One command. Every project. Always current.

</td>
</tr>
</table>

```
┌──────────────────────────────────────────┐
│  SHARED RULES          ████████ 3 rules  │
│  SHARED SKILLS         ████████ 2 skills │
│  SHARED AGENTS         ████████ 1 agent  │
│  SHARED COMMANDS       ████████ 1 cmd    │
│  SUPPORTED TOOLS       ████████ 2 tools  │
│  COPY-PASTE NEEDED     ░░░░░░░░ 0        │
└──────────────────────────────────────────┘
```

## Supported Tools

| Tool | Generated Files | Format |
|------|----------------|--------|
| **Claude Code** | `CLAUDE.md`, `.claude/skills/*.md`, `.claude/commands/*.md` | Markdown |
| **Cursor** | `.cursorrules`, `.cursor/rules/*.mdc` | MDC |

More coming: Windsurf, Copilot, Cline.

## Install

```bash
# From GitHub (internal)
npm install --save-dev git+ssh://git@github.com:thomas-ooolab/mobile-plugin.git
```

That's it. One line.

## Usage

### `init` — Set up a project

```bash
# Both Claude + Cursor
npx @ooolab/mobile-plugin init

# Single tool
npx @ooolab/mobile-plugin init -t claude
npx @ooolab/mobile-plugin init -t cursor
```

Output:

```
Initializing AI plugin...
  wrote: CLAUDE.md
  wrote: .claude/skills/code-review.md
  wrote: .claude/skills/commit.md
  wrote: .claude/commands/deploy.md
✓ claude configured
  wrote: .cursorrules
  wrote: .cursor/rules/general.mdc
  wrote: .cursor/rules/react-native.mdc
  wrote: .cursor/rules/typescript.mdc
  wrote: .cursor/rules/agent-reviewer.mdc
✓ cursor configured

Done! AI configs installed.
```

### `sync` — Update to latest

```bash
npx @ooolab/mobile-plugin sync            # update all
npx @ooolab/mobile-plugin sync --dry-run   # preview only
npx @ooolab/mobile-plugin sync -t claude   # one tool
```

### `list` — See what's available

```bash
npx @ooolab/mobile-plugin list

RULES
  general       — Core coding standards for all OOOLab projects
  react-native  — React Native development standards
  typescript    — TypeScript coding standards and best practices

SKILLS
  code-review   — Structured code review checklist and process
  commit        — Generate conventional commit messages from staged changes

AGENTS
  reviewer      — Automated code reviewer for quality, security, consistency

COMMANDS
  deploy        — Guide through deployment process with pre-flight checks
```

## Shared Content

All shared content lives in `shared/` as Markdown with YAML frontmatter.

### Structure

```
shared/
├── rules/              # Coding standards and guidelines
│   ├── general.md         — applies to all projects
│   ├── typescript.md      — TS-specific, scoped to *.ts/*.tsx
│   └── react-native.md   — RN-specific, scoped to *.tsx/*.jsx
├── skills/             # Reusable AI skill prompts
│   ├── code-review.md     — structured review checklist
│   └── commit.md          — conventional commit generator
├── agents/             # Agent role definitions
│   └── reviewer.md        — automated PR reviewer
└── commands/           # Command templates
    └── deploy.md          — deployment pre-flight guide
```

### File Format

```markdown
---
title: Human-readable title
description: One-line description (shown in `list`)
globs: "**/*.ts"          # Optional: file scope (Cursor)
alwaysApply: true          # Optional: auto-apply (Cursor)
---

Content here. Markdown supported.
```

### How It Works

```
shared/*.md  ──→  templates/*.hbs  ──→  project config files
                        │
                        ├── Claude: CLAUDE.md + .claude/skills/ + .claude/commands/
                        └── Cursor: .cursorrules + .cursor/rules/*.mdc
```

| Command | What it does |
|---------|-------------|
| `init` | Write `.ai-plugin.json` + generate all tool configs |
| `sync` | Re-read `shared/`, re-render templates, update files (skip unchanged) |
| `list` | Display available rules/skills/agents/commands |

## Adding New Content

1. Create `.md` in the right `shared/` subdirectory
2. Add frontmatter: `title` + `description` (minimum)
3. Write content
4. `npx @ooolab/mobile-plugin list` → verify it shows
5. Commit + push → all projects get it on next `sync`

## Adding a New AI Tool

<details>
<summary><strong>Create an installer in <code>src/installers/</code></strong></summary>

```js
// src/installers/windsurf.js
import { loadSharedFiles } from '../utils.js';
import { writeWithBackup } from './common.js';

export async function syncWindsurf(projectDir, opts = {}) {
  const rules = await loadSharedFiles('rules');
  // Transform and write to .windsurfrules format
}
```

Register in `src/cli.js`:

```js
import { syncWindsurf } from './installers/windsurf.js';

const TARGETS = {
  claude: syncClaude,
  cursor: syncCursor,
  windsurf: syncWindsurf,  // add here
};
```

</details>

## CI Integration

<details>
<summary><strong>Auto-sync via GitHub Actions</strong></summary>

```yaml
# .github/workflows/sync-ai.yml
name: Sync AI Plugin
on:
  schedule:
    - cron: '0 9 * * 1'  # Weekly Monday 9am
  workflow_dispatch:

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm install
      - run: npx @ooolab/mobile-plugin sync
      - uses: peter-evans/create-pull-request@v6
        with:
          title: 'chore: sync AI plugin rules'
          branch: chore/sync-ai-plugin
```

</details>

## Notes

- Generated files have `<!-- Auto-generated by @ooolab/mobile-plugin -->` header — don't edit directly, `sync` overwrites them
- `.ai-plugin.json` tracks configured tools — commit this file
- Generated AI configs (`.cursorrules`, `CLAUDE.md`, etc.) — your choice to gitignore or commit

## License

Internal use only.
