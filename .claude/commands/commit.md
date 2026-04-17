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

**Step 3 — Bump plugin version** by running the script with the bump type you determined:
```
bash .claude/commands/scripts/commit.sh <major|minor|patch>
```
This updates the version in both `plugins/mobile/.claude-plugin/plugin.json` and `plugins/mobile/.cursor-plugin/plugin.json` and stages them. Print the new version to the user.

**Step 4 — Commit** with the generated message using a HEREDOC.

**Step 5 — Push.**
