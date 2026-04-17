---
name: pubspec
description: >
  Manages pubspec.yaml dependencies for Flutter/Dart projects. Enforces using
  the latest published version from pub.dev when adding or updating packages.
  Use when adding a dependency, updating pubspec.yaml, or asked "what version
  of X should I use".
---

## Rule

Always use latest stable version from pub.dev. Never pin exact versions or copy
version strings from docs/examples without verifying.

## Fetching Latest Version

Use pub.dev JSON API:

```
GET https://pub.dev/api/packages/<package-name>
```

Read `latest.version` from response. That is the version to use.

## Version Constraint Format

Write as `^<latest>` (caret = compatible releases, allows patch + minor updates).

```yaml
# GOOD
dependencies:
  http: ^1.2.1
  provider: ^6.1.2
  dio: ^5.7.0

# BAD — pinned, blocks patches
dependencies:
  http: 1.2.1

# BAD — unconstrained, breaks on major bumps
dependencies:
  http: any
```

## Workflow

1. For each package being added: fetch `https://pub.dev/api/packages/<name>`
2. Extract `latest.version`
3. Write `^<version>` in pubspec.yaml
4. Run `fvm flutter pub get` after editing

## Edge Cases

- Package marked **discontinued**: warn user, suggest replacement listed on pub.dev page
- Package has **no stable release** (only pre-release): use latest pre-release with comment explaining why
- **Flutter-only** packages (need Flutter SDK): goes under `dependencies:`, not `dev_dependencies:`
- **Dev tools** (build_runner, lints, etc.): goes under `dev_dependencies:`
