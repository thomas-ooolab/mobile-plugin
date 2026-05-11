---
title: Commit & Push
description: Format, stage, commit with conventional message, and push to origin
---

# Commit

Run the project's commit workflow: format, stage, commit, and push with the given message.

**Execute the script:**

```bash
scripts/push.sh
```

> Script source in this repo: `plugins/mobile/commands/scripts/push.sh`

The script requires a commit message. Pass it via:

- **Environment variable:** `COMMIT_MESSAGE="Your message" scripts/push.sh`
- **CLI argument:** `scripts/push.sh -m "Your message"` or `scripts/push.sh --message "Your message"`

**Commit message format:**

Use a conventional type prefix, then ticket ID (if required), then a short description:

```
<type>: [TICKET-ID]: <description>
```

Example: `feat: LOE-6144: add dark mode toggle`

**Type of change** (align with [.gitlab/merge_request_templates/Default.md](.gitlab/merge_request_templates/Default.md)):

| Type       | Use for |
| ---------- | ------- |
| `feat`     | New feature (non-breaking change which adds functionality) |
| `fix`      | Bug fix (non-breaking change which fixes an issue) |
| `!`        | Breaking change (fix or feature that changes existing functionality) |
| `refactor` | Code refactor |
| `test`     | Unit test |
| `ci`       | Build / CI configuration change |
| `docs`     | Documentation |
| `chore`    | Chore (tooling, scripts, housekeeping) |

When generating the message, **infer the type from the changes** (e.g. new screens or APIs → `feat`, corrected logic → `fix`, CI/config edits → `ci`, docs only → `docs`).

If `release-notes.txt` exists and contains a ticket ID (e.g. `LOE-6144`), the commit message must include that ID (e.g. `feat: LOE-6144: description`).

**Steps performed by the script:**

1. If every changed file is under `lib/`, `test/`, `<pkg>/lib/`, or `<pkg>/test/` (e.g. `data/lib/`, `domain/test/`), format code with `fvm dart format .` (or `dart format .` if `fvm` is not installed). Changes outside those directories skip formatting entirely. **If formatting fails, the script exits immediately** and does not stage, commit, or push. Fix the reported issues, then run the push command again.
2. Read commit message from `COMMIT_MESSAGE` or `-m`/`--message`
3. Stage all changes, commit, and push (set upstream if needed)

When the user runs `/commit`:

1. **Determine the type of change** from the diff (feat, fix, refactor, test, ci, docs, chore, or `!` for breaking).
2. **Read ticket ID** from `release-notes.txt` if present (e.g. LOE-6144).
3. **Build the message** in the form `type: [TICKET-ID]: short description` (e.g. `feat: LOE-6144: add dark mode toggle`).
4. Run:

```bash
COMMIT_MESSAGE="<generated message>" scripts/push.sh
```

or

```bash
scripts/push.sh -m "<generated message>"
```
