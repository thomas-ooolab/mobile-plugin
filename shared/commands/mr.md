---
title: Merge Request
description: Create GitLab MR with conventional title format and ticket ID from release-notes.txt
---

# Merge Request

Run the project's MR workflow: create a Merge Request on GitLab using the glab CLI. The script pushes the current branch, then creates an MR with a generated title and the default description template.

**Execute the script:**

```bash
./.cursor/commands/scripts/merge_request.sh
```

The user can provide the MR title (the description part). Pass it via:

- **Environment variable:** `MR_TITLE="Your title" ./.cursor/commands/scripts/merge_request.sh`
- **CLI argument:** `./.cursor/commands/scripts/merge_request.sh -t "Your title"` or `./.cursor/commands/scripts/merge_request.sh --title "Your title"`

**Optional:** Set target branch with `MR_TARGET_BRANCH=feat/LOE-6156`. Use `--draft` for a draft MR, or `-l "label1,label2"` for labels.

---

## MR title format (same as commit message)

The script **generates** the full MR title so it adheres to the same convention as [push.md](push.md) (lines 16–41):

```
<type>: [TICKET-ID]: <description>
```

- **User-provided title** is used as the `<description>` part (e.g. "Course Completion Pop-up & Recommendation Prompt").
- **Type** is derived from the current branch prefix (`feat/`, `fix/`, `refactor/`, etc.); unknown prefixes default to `feat`.
- **Ticket ID** is read from `release-notes.txt` (e.g. `LOE-6156`). If present, the generated title **must** include it.

**Example:** User passes title `"Course Completion Pop-up & Recommendation Prompt"`, branch is `feat/LOE-6156`, and `release-notes.txt` contains `LOE-6156`. The script produces:

```
feat: LOE-6156: Course Completion Pop-up & Recommendation Prompt
```

**Type of change** (align with [.gitlab/merge_request_templates/Default.md](.gitlab/merge_request_templates/Default.md)) — same as push:

| Type       | Use for |
| ---------- | ------- |
| `feat`     | New feature (non-breaking change which adds functionality) |
| `fix`      | Bug fix (non-breaking change which fixes an issue) |
| `!`        | Breaking change |
| `refactor` | Code refactor |
| `test`     | Unit test |
| `ci`       | Build / CI configuration change |
| `docs`     | Documentation |
| `chore`    | Chore (tooling, scripts, housekeeping) |

If `release-notes.txt` exists and contains a ticket ID, the final MR title will include that ID (the script enforces this, same as [push.sh](scripts/push.sh) for commit messages).

---

## Steps performed by the script

1. Read user title from `MR_TITLE` or `-t`/`--title` (optional).
2. Generate full MR title: `<type>: [TICKET-ID]: <user title>` (type from branch, ticket from `release-notes.txt`).
3. Push current branch to `origin` if needed.
4. Create Merge Request with glab using the generated title, default description template (Default.md), and optional target branch/labels/draft.

When the user runs `/mr` and provides a title (e.g. "Course Completion Pop-up & Recommendation Prompt"):

1. **Ticket ID** is read from `release-notes.txt` if present.
2. **Type** is derived from the current branch name (e.g. `feat/LOE-6156` → `feat`).
3. **Build the MR title** as `type: TICKET-ID: user title` (e.g. `feat: LOE-6156: Course Completion Pop-up & Recommendation Prompt`).
4. Run:

```bash
MR_TITLE="Course Completion Pop-up & Recommendation Prompt" ./.cursor/commands/scripts/merge_request.sh
```

or with target branch:

```bash
MR_TARGET_BRANCH=feat/LOE-6156 MR_TITLE="Course Completion Pop-up & Recommendation Prompt" ./.cursor/commands/scripts/merge_request.sh
```

or via CLI:

```bash
./.cursor/commands/scripts/merge_request.sh -t "Course Completion Pop-up & Recommendation Prompt"
```
