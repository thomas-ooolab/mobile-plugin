---
description: Development workflow (FVM, git, quality) and when to delegate to subagents
alwaysApply: true
---

# Development Workflow

## Codebase understanding (GitNexus)

This repository is **indexed by GitNexus**. For anything that depends on understanding the codebase—where code lives, how flows connect, impact of a change, debugging “where does this come from?”, or safe refactors—**use GitNexus first** (MCP server and CLI), not only text search or guesswork.

- **MCP:** Prefer GitNexus tools (`query`, `context`, `cypher`, `impact`, `route_map`, and related) over generic exploration when they fit the question.
- **CLI:** `npx gitnexus analyze` refreshes the index; `npx gitnexus status` checks freshness.
- **Skills:** `gitnexus-guide`, `gitnexus-exploring`, `gitnexus-debugging`, `gitnexus-impact-analysis`, `gitnexus-refactoring`, `gitnexus-cli`.

---

**When to run this process:** Only when the developer provides a **ticket ID** and **requirements**. Then follow steps 1–5 in order. (If there is no ticket ID or no requirements, do not assume or invent them.)

1. **Update `release-notes.txt`**  
   Set the content to the issue tracker URL for the ticket (e.g. `https://<your-tracker>/browse/<ticket_ID>`).

2. **Create a new branch**  
   Follow branch naming and type conventions in `@workflow`. Example: new feature → branch `feat/PROJ-123` from the target branch.

3. **Implement the requirements**  
   Based on the provided requirements and your analysis, implement the work (delegate to subagents when the task matches the table below).

4. **After finishing code changes: MUST use `/test-writer`**  
   Invoke the test-writer subagent to add or update the test suite for the changes. Do not consider the task complete until tests have been written or updated for the modified code.

5. **After finishing development (including writing unit tests): MUST use `/code-reviewer`**  
   Invoke the code-reviewer subagent to run format, analyze, bloc lint, and review all changed code. Do not consider the task complete until the code review is done and any required fixes are applied.

---

Follow the project's development workflow (see `${CLAUDE_PLUGIN_ROOT}/skills/workflow/SKILL.md`). Summary:

- **FVM required**: Prefix all Flutter/Dart commands with `fvm` (e.g. `fvm flutter run`, `fvm dart run build_runner build -d`).
- **Quality**: Format with `fvm dart run melos dart-format` (or `fvm dart format .`), run `fvm dart analyze`, use localization for user-visible strings, follow Clean Architecture.

When a task matches one of the following, **delegate to the corresponding subagent**. Use [explicit invocation](https://cursor.com/docs/context/subagents#explicit-invocation): **`/name`** in the prompt (e.g. `/data-implementor add the new endpoint`) or natural mention (e.g. “Use the presentation-implementor subagent to implement this screen”).

| Task | Invoke with | When to use |
|------|-------------|-------------|
| **Data layer (remote + local)** | `/data-implementor` | New or changed endpoints, API contracts, Retrofit APIs, request/response models, local persistence (Hive/SharedPreferences/SecureStorage), or any work in `packages/data`. (`${CLAUDE_PLUGIN_ROOT}/agents/data-implementor.md`) |
| **Domain layer (repositories + use cases)** | `/domain-implementor` | New or changed repository interfaces/impls in `packages/domain`, use cases in `lib/use_case`, domain exceptions, or business-logic orchestration across data sources. (`${CLAUDE_PLUGIN_ROOT}/agents/domain-implementor.md`) |
| **Presentation layer** | `/presentation-implementor` | Adding or changing screens, cubits, routes, or views in `lib/screens/`, `lib/widgets/`, or `lib/components/`. (`${CLAUDE_PLUGIN_ROOT}/agents/presentation-implementor.md`) |
| **Tests** | `/test-writer` | **MANDATORY** after finishing code changes: add or update unit, widget, or integration tests for the changes. (`${CLAUDE_PLUGIN_ROOT}/agents/test-writer.md`) |
| **Code review** | `/code-reviewer` | **MANDATORY** after finishing development (including unit tests): run format, analyze, bloc lint, and review all changed code. (`${CLAUDE_PLUGIN_ROOT}/agents/code-reviewer.md`) |

**Do not ask the user which subagent to use.** Analyze the task yourself and either invoke the matching subagent or tell the user to run **`/name`** (e.g. “Run `/presentation-implementor` to implement this screen”). Decide based on the table above; never prompt the user to choose.
