---
title: Flutter Upgrade Reference
description: Reference docs for Flutter upgrade script — troubleshooting, dependency rules, rollback, version conflicts
---

# Flutter Upgrade – Reference

## What the script does (summary)

1. **Flutter/Dart** – Fetches latest stable, updates all `pubspec.yaml`, sets FVM, runs `fvm dart pub get`.
2. **Dependencies** – Runs `fvm dart pub upgrade --major-versions`, removes all `^` from versions.
3. **Config** – Updates `.gitlab-ci.yml`, `README.md`, `.gitlab/ci_templates/build.gitlab-ci.yml`.
4. **Ruby/Fastlane** – Ruby 3.2.2 via rbenv, Bundler, Pluginfile/Gemfile and `bundle update` for ios/android.
5. **iOS** – Removes `ios/Podfile.lock`, runs `pod install --repo-update`.
6. **Android** – AGP, Kotlin, Google Services, Firebase Perf/Crashlytics, Gradle wrapper, Firebase Analytics KTX, Desugar JDK Libs, AndroidX Window (stable only; Google Maven + Maven Central).
7. **Tools** – yq, and in CI: FVM, test_cov_console, flutterfire_cli, bloc_tools, junitreport (pub.dev stable preferred).
8. **Cleanup** – Removes cached gem files.

## Dependency rules

- Use **fixed** versions (no `^`). The script enforces this.
- Check: `fvm dart pub outdated`, `fvm dart pub deps --style=tree`.
- Resolve conflicts with `dependency_overrides` in root `pubspec.yaml` if needed.

## Troubleshooting

### FVM not found

```bash
dart pub global activate fvm
# or: brew tap leoafarias/fvm && brew install fvm
```

### yq not found

```bash
brew install yq
```

### Ruby

```bash
brew install rbenv
rbenv install 3.2.2
rbenv global 3.2.2
```

### Pod install failures

```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
```

### Gradle / Android

```bash
cd android
./gradlew clean
# If needed: ./gradlew wrapper --gradle-version=8.14.3
./gradlew --refresh-dependencies
```

### AGP ↔ Gradle compatibility (script uses this)

| AGP       | Gradle |
|----------|--------|
| 8.13–8.15 | 8.14.3 |
| 8.10–8.12 | 8.10.2 |
| 8.7–8.9   | 8.9    |
| 8.4–8.6   | 8.6    |
| 8.3       | 8.4    |
| 8.2       | 8.2    |
| 8.1       | 8.0    |
| 8.0       | 8.0    |
| Default   | 8.14.3 |

## Rollback

1. Revert Flutter: `fvm use 3.34.0 --skip-pub-get` (replace with your previous stable).
2. Restore files: `git checkout HEAD~1 -- pubspec.yaml packages/*/pubspec.yaml .gitlab-ci.yml android/settings.gradle.kts android/app/build.gradle.kts android/gradle/wrapper/gradle-wrapper.properties`
3. Clean: `fvm flutter clean && fvm flutter pub get`, then `cd android && ./gradlew clean`, `cd ../ios && pod install --repo-update`.

## Checklists

**Before:** Backup branch, review Flutter release notes, check package compatibility, run tests.

**During:** Use latest stable only, run full script, fix errors before continuing.

**After:** Run `fvm dart run melos generate --no-select` (Enter for default), `fvm dart format .`, verify CI and builds.

## Version conflicts

- Inspect: `fvm dart pub deps --style=tree | grep -E "(conflict|overridden)"`, `fvm dart pub deps --style=compact`.
- Fix with root `dependency_overrides` and compatible versions.
- Validate: `fvm dart pub get`, `fvm flutter analyze`.
