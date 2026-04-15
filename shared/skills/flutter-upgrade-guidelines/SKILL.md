---
name: flutter-upgrade
description: Runs the project's automated Flutter upgrade using the latest stable version, then Melos and format. Use when the user runs /flutter-upgrade, asks to upgrade Flutter, or wants to update Flutter/Dart and related dependencies.
---

# Flutter Upgrade

This project uses an automated upgrade via `.cursor/commands/scripts/flutter_upgrade.sh`. **Always use the latest stable Flutter version.**

## Quick process (2 steps)

**Step 1: Run the upgrade script**

```bash
./.cursor/commands/scripts/flutter_upgrade.sh
```

The script fetches the latest stable Flutter, updates all `pubspec.yaml` files, runs `fvm dart pub upgrade --major-versions`, removes carets (^) from dependencies, and updates CI, Ruby/Fastlane, iOS (CocoaPods), and Android (Gradle, AGP, Kotlin, Firebase, etc.).

**Step 2: Melos and format**

After the script finishes:

```bash
fvm dart run melos generate --no-select
# When prompted, press Enter for the default option

fvm dart format .
```

## Important

- Use **latest stable** Flutter only; the script fetches it automatically.
- Run the **full 2-step process**; do not skip Melos generate or format.
- During `melos generate`, press **Enter** to accept the default.
- Dependencies are upgraded and carets removed by the script; no need to run `pub upgrade` or remove carets manually before or after Step 1.

## When to use this skill

- User runs **/flutter-upgrade** or asks to **upgrade Flutter**.
- User wants to **update Flutter, Dart, and related tooling** (FVM, CI, Ruby, Fastlane, iOS, Android).

## Additional reference

- Troubleshooting (FVM, yq, Ruby, Pods, Gradle, AGP compatibility), rollback steps, dependency checklists, and version conflict resolution: [reference.md](reference.md).
