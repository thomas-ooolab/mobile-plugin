---
title: Help
description: List all available commands and skills in this plugin
---

# Help

Quick reference for all commands and skills available in this mobile plugin.

---

## Commands

| Command   | Description |
| --------- | ----------- |
| `/commit` | Format, stage, commit with conventional message, and push to origin |
| `/mr`     | Create GitLab MR with conventional title format and ticket ID from `release-notes.txt` |
| `/specs`  | Accept ticket ID + requirements, execute full 5-step development workflow |
| `/help`   | Show this reference |

---

## Skills

Skills are loaded automatically when relevant. Reference them explicitly with `/[skill-name]`.

| Skill          | Use for |
| -------------- | ------- |
| `bash`         | Shell scripts, CI/CD bash automation, Fastlane scripts — syntax, error handling, ShellCheck |
| `clean`        | Clean Architecture layers, dependency rules, repositories, data sources, use cases |
| `dart`         | Dart naming, syntax, docs, null safety, async patterns, design principles |
| `data`         | Retrofit API, remote/local data sources, models, DI in `packages/data` |
| `di`           | `get_it` + `injectable` DI: `sl` instance, annotations, modules, test overrides |
| `domain`       | Repository interfaces, use cases, domain exceptions in `packages/domain` |
| `flutter`      | Widget architecture, composition rules, performance patterns |
| `git`          | Commits, branches, merges, rebases, conflict resolution, recovery |
| `presentation` | Screens, cubits, routes, views, barrel files in `lib/screens/` |
| `ruby`         | Fastlane Ruby — lane/helper design, env vars, shell safety, CI patterns |
| `state`        | Cubit/BLoC, `@freezed` states, `DataLoadStatus`, `flutter_bloc` integration |
| `test`         | Unit, widget, integration tests with `bloc_test` and `mocktail` |
| `workflow`     | Git branching, feature dev process, PR creation, dev environment setup |
