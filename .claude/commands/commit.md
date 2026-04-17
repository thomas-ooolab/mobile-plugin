---
description: Bump plugin version, commit staged changes, and push
---

Get current git state:
`!git diff`
`!git status --short`

Use /caveman:caveman-commit to generate a commit message from the changes above.

Then execute these steps in order:

**Step 1 — Determine version bump** from the commit `<type>`:
- `feat!` or body contains `BREAKING CHANGE` → `major`
- `feat` → `minor`
- `fix`, `docs`, `chore`, `refactor`, `perf`, `test`, `build`, `ci`, `style`, `revert` → `patch`

**Step 2 — Stage all changes:**
```
git add -A
```

**Step 3 — Bump version and commit** by running the script with the bump type and commit message:
```
bash .claude/commands/scripts/commit.sh <major|minor|patch> "<commit message>"
```
The script auto-detects change scope, bumps the correct version files, stages them, runs `git commit`, and pushes. Print the new version to the user.
- Changes only in `plugins/**` → bumps `plugins/mobile/.claude-plugin/plugin.json` and `plugins/mobile/.cursor-plugin/plugin.json`
- Any change outside `plugins/**` → bumps `.claude-plugin/marketplace.json` and `.cursor-plugin/marketplace.json`
