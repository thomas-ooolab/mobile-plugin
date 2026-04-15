---
title: General Coding Rules
description: Core coding standards for all OOOLab projects
alwaysApply: true
---

## Code Style

- Write clean, readable code. Prefer clarity over cleverness.
- Use meaningful variable and function names.
- Keep functions small and focused — one function, one responsibility.
- Avoid deep nesting. Extract early returns and guard clauses.

## Error Handling

- Handle errors at the appropriate level. Don't swallow errors silently.
- Provide useful error messages that help debugging.
- Use typed errors where the language supports it.

## Security

- Never commit secrets, API keys, or credentials.
- Validate all external input (user input, API responses, file data).
- Use parameterized queries for database operations.
- Follow the principle of least privilege.

## Git

- Write clear commit messages: what changed and why.
- Keep commits atomic — one logical change per commit.
- Keep PRs focused and reviewable.
