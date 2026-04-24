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

**When to run this process:** Only when the developer provides **requirements**. Then follow steps 0–5 in order. (If there are no requirements, do not assume or invent them.)

0. **Determine task type**
   Analyze the requirements and classify the task using the type conventions in `@workflow` (Branch Naming Convention). Use the type to name the branch (step 2), pick subagents (step 3), and frame the implementation approach.
   If the type is ambiguous from the requirements, ask the user before proceeding.

1. **Update `release-notes.txt`**
   - If a ticket ID was provided, set the content to the issue tracker URL (e.g. `https://<your-tracker>/browse/<ticket_ID>`).
   - If no ticket ID was provided, show an interactive selection prompt the user navigates with arrow keys and confirms with Enter:
     ```
     No ticket ID provided. What would you like to do?
     > Enter ticket ID
       Skip (also skips branch creation in step 2)
     ```
     - If the user selects "Enter ticket ID", prompt for text input, then set `release-notes.txt` to the corresponding issue tracker URL.
     - If the user selects "Skip", leave `release-notes.txt` unchanged and skip step 2 — proceed directly to step 3.

2. **Create a new branch**  
   Follow branch naming and type conventions in `@workflow`. Example: new feature → branch `feat/PROJ-123` from the target branch.
   (Skip this step if step 1 was skipped.)

3. **Implement the requirements**  
   Based on the provided requirements and your analysis, implement the work (delegate to subagents when the task matches the table below).
   - Before starting implementation, if you have any concerns (ambiguous requirements, conflicting constraints, unclear scope, risky changes), pause and present your suggestions as an interactive selection prompt: display the options as a list the user can navigate with arrow keys and confirm with Enter. Do not proceed until the user has selected an option.

4. **After finishing code changes: MUST use `/test-writer`**  
   Invoke the test-writer subagent to add or update the test suite for the changes. Do not consider the task complete until tests have been written or updated for the modified code.

5. **After finishing development (including writing unit tests): MUST use `/code-reviewer`**  
   Invoke the code-reviewer subagent to run format, analyze, bloc lint, and review all changed code. Do not consider the task complete until the code review is done and any required fixes are applied.

---

Follow the project's development workflow (see `../skills/workflow/SKILL.md`). Summary:

- **FVM detection**: Before running any Flutter/Dart command, check if `.fvmrc` exists in the project root AND `fvm` command is available. If both are true, prefix commands with `fvm` (e.g. `fvm flutter run`, `fvm dart run build_runner build -d`). Otherwise use `flutter`/`dart` directly.
- **Quality**: Format with `fvm dart format .` (or `dart format .`), run `fvm dart analyze` (or `dart analyze`), use localization for user-visible strings, follow Clean Architecture.

When a task matches one of the following, **delegate to the corresponding subagent**. Use [explicit invocation](https://cursor.com/docs/context/subagents#explicit-invocation): **`/name`** in the prompt (e.g. `/data-implementor add the new endpoint`) or natural mention (e.g. “Use the presentation-implementor subagent to implement this screen”).

| Task | Invoke with | When to use |
|------|-------------|-------------|
| **Data layer (remote + local)** | `/data-implementor` | New or changed endpoints, API contracts, Retrofit APIs, request/response models, local persistence (Hive/SharedPreferences/SecureStorage), or any work in `data`. (`../agents/data-implementor.md`) |
| **Domain layer (repositories + use cases)** | `/domain-implementor` | New or changed repository interfaces/impls in `domain`, use cases in `use_case`, domain exceptions, or business-logic orchestration across data sources. (`../agents/domain-implementor.md`) |
| **Presentation layer** | `/presentation-implementor` | Adding or changing screens, cubits, routes, or views in `screens/`, `widgets/`, or `components/`. (`../agents/presentation-implementor.md`) |
| **Tests** | `/test-writer` | **MANDATORY** after finishing code changes: add or update unit, widget, or integration tests for the changes. (`../agents/test-writer.md`) |
| **Code review** | `/code-reviewer` | **MANDATORY** after finishing development (including unit tests): run format, analyze, bloc lint, and review all changed code. (`../agents/code-reviewer.md`) |

**Do not ask the user which subagent to use.** Analyze the task yourself and either invoke the matching subagent or tell the user to run **`/name`** (e.g. “Run `/presentation-implementor` to implement this screen”). Decide based on the table above; never prompt the user to choose.
