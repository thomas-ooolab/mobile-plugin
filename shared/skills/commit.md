---
title: Commit Message
description: Generate conventional commit messages from staged changes
---

Analyze staged changes and generate a commit message following Conventional Commits:

## Format

```
<type>(<scope>): <subject>

<body>
```

## Types
- `feat`: new feature
- `fix`: bug fix
- `refactor`: code change that neither fixes a bug nor adds a feature
- `docs`: documentation only
- `style`: formatting, missing semicolons, etc.
- `test`: adding or updating tests
- `chore`: maintenance tasks, dependency updates
- `perf`: performance improvement

## Rules
- Subject line ≤ 50 characters
- Use imperative mood: "add" not "added" or "adds"
- No period at end of subject
- Body explains **why**, not **what** (the diff shows what)
- Body only when the "why" isn't obvious from the subject
- Scope is optional — use when change is clearly scoped to one area
