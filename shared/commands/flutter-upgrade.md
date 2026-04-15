---
title: Flutter Upgrade
description: Automated Flutter upgrade process — updates Flutter, Dart, deps, iOS, Android, CI
---

# Flutter Upgrade Instructions

> ⚠️ **IMPORTANT: Before running the upgrade script, always review the detailed guidelines in `.cursor/skills/flutter-upgrade-guidelines/SKILL.md`** for comprehensive information about the upgrade process, troubleshooting, best practices, and version management.

This project uses a fully automated Flutter upgrade process that updates Flutter, Dart, and all related dependencies. The upgrade process is automated through the `flutter_upgrade.sh` script and **must always use the latest stable Flutter version**.

## Automated Upgrade Process

### Step 1: Run Flutter Upgrade Script

**ALWAYS use the latest stable Flutter version when upgrading:**

```bash
# Run the upgrade script (automatically fetches latest stable)
./.cursor/commands/scripts/flutter_upgrade.sh
```

The script will:
- Automatically detect and use the latest stable Flutter version
- Update all Flutter and Dart versions across the project
- Update all configuration files
- Update Ruby and Fastlane dependencies
- Update iOS dependencies
- Update Android Gradle components
- Update all tools to latest versions

### Step 2: Generate Melos Configuration

**Note:** The upgrade script now automatically runs `fvm dart pub upgrade --major-versions` and removes all caret (^) symbols from dependencies as part of Step 1. You no longer need to do this manually.

After the Flutter upgrade script completes, regenerate the Melos configuration for the whole project, and **wait for it to finish completely** before formatting:

```bash
# Generate Melos configuration after package changes
fvm dart run melos generate --no-select
# When prompted, just press Enter to use the default option and
# wait until this command finishes completely.

# After melos generate has fully completed, format all Dart code
fvm dart format .
```

## What the Upgrade Script Does

The `flutter_upgrade.sh` script performs the following comprehensive updates:

### 1. Flutter and Dart Version Updates
- **Fetches latest stable Flutter version** automatically
- Updates Flutter version in all `pubspec.yaml` files (root and packages)
- Updates corresponding Dart SDK version automatically
- Sets the Flutter version in FVM for the project
- Runs `fvm dart pub get` to update dependencies

### 2. Dependency Upgrades (Automated)
- **Runs `fvm dart pub upgrade --major-versions`** to upgrade all dependencies
- **Automatically removes all caret (^) symbols** from dependency versions
- Ensures all dependencies use fixed versions (no version ranges)
- Updates `pubspec.lock` files with fixed versions
- Follows project guidelines for reproducible builds

### 3. Configuration File Updates
- Updates `.gitlab-ci.yml` with new Flutter version
- Updates `README.md` with new Flutter version
- Updates `.gitlab/ci_templates/build.gitlab-ci.yml` with Ruby and Bundler versions

### 4. Ruby and Fastlane Dependencies
- Installs/updates Ruby 3.2.2 via rbenv
- Updates Bundler to latest version
- Updates all fastlane plugins in `ios/fastlane/Pluginfile` and `android/fastlane/Pluginfile`
- Updates all gems in `ios/Gemfile` and `android/Gemfile`
- Runs `bundle update` for both platforms

### 5. iOS Dependencies
- Removes `ios/Podfile.lock` for clean install
- Runs `pod install --repo-update` to update CocoaPods dependencies

### 6. Android Gradle Components
- **Updates Android Gradle Plugin (AGP)** to latest stable version in `android/settings.gradle.kts`
- **Updates Kotlin Plugin** to latest stable version in `android/settings.gradle.kts`
- **Updates Google Services Plugin** to latest stable version in `android/settings.gradle.kts`
- **Updates Firebase Performance Plugin** to latest stable version in `android/settings.gradle.kts`
- **Updates Firebase Crashlytics Plugin** to latest stable version in `android/settings.gradle.kts`
- **Updates Gradle Wrapper** to version compatible with AGP in `android/gradle/wrapper/gradle-wrapper.properties`
- **Updates Firebase Analytics KTX** dependency to latest stable version in `android/app/build.gradle.kts`
- **Updates Desugar JDK Libs** dependency to latest stable version in `android/app/build.gradle.kts`
- **Updates AndroidX Window** dependencies (both `window` and `window-java` artifacts) to latest stable version in `android/app/build.gradle.kts`
- Fetches versions from Google Maven (for Android/Firebase artifacts) and Maven Central (for other artifacts)
- Automatically filters out pre-release versions (alpha, beta, rc, dev, snapshot, milestone, preview)
- Ensures Gradle version compatibility with AGP version using official compatibility mapping

### 7. Tool Updates
- Updates yq tool to latest version from GitHub
- Updates yq version in CI configuration
- **Updates Dart tool versions in GitLab CI:**
  - **FVM** (Flutter Version Management) - Latest stable version from pub.dev
  - **test_cov_console** - Test coverage reporting tool
  - **flutterfire_cli** - FlutterFire CLI for Firebase configuration
  - **bloc_tools** - Bloc state management tools
  - **junitreport** - JUnit report generator
- Fetches latest versions from pub.dev API
- **Smart version selection strategy:**
  - Prefers stable versions (filters out dev, alpha, beta, rc, pre)
  - If no stable version exists, uses latest pre-release version with warning
  - Ensures always using the most appropriate available version
- Updates variables in `.gitlab/ci_templates/environment_setup.gitlab-ci.yml` and `.gitlab/ci_templates/analyze_and_test.gitlab-ci.yml`

### 8. Cleanup
- Removes cached gem files for fresh installs

## Dependency Management Rules

### Fixed Version Strategy

**ALWAYS use fixed latest versions for all dependencies to ensure reproducible builds:**

```yaml
# ✅ Good - Fixed versions (no caret)
dependencies:
  flutter:
    sdk: flutter
  http: 1.1.0
  provider: 6.1.1
  shared_preferences: 2.2.2

# ❌ Bad - Version ranges with caret
dependencies:
  http: ^1.1.0  # Caret allows minor updates
  provider: ^6.1.1  # Caret allows minor updates
  shared_preferences: any  # No version constraint
```

### Dependency Update Process

#### 1. Check Latest Versions
```bash
# Check outdated packages
fvm dart pub outdated

# Check specific package versions
fvm dart pub deps --style=tree
```

#### 2. Update Dependencies Systematically
```bash
# Update all dependencies to latest compatible versions
fvm dart pub upgrade --major-versions

# Update specific package with exact version
fvm dart pub add package_name:1.2.3
```

#### 3. Verify No Conflicts
```bash
# Check for dependency conflicts
fvm dart pub deps --style=compact

# Verify all packages resolve correctly
fvm dart pub get
```

### Automated Dependency Updates Using Melos

```bash
# Update all packages simultaneously
fvm dart run melos exec -- "fvm dart pub upgrade --major-versions"

# Generate Melos configuration after package changes
fvm dart run melos generate --no-select
# When prompted, just press Enter to use the default option

# Format all Dart code after build_runner
fvm dart format .

# Check for outdated packages across all packages
fvm dart run melos exec -- "fvm dart pub outdated"
```

### Dependency Update Checklist

#### Before Update
- [ ] Backup current pubspec.lock
- [ ] Review breaking changes in package changelogs
- [ ] Check compatibility with current Flutter version
- [ ] Identify shared dependencies across packages

#### During Update
- [ ] Update root dependencies first
- [ ] Update package dependencies systematically
- [ ] Use fixed latest versions (no version ranges)
- [ ] Resolve conflicts with dependency overrides
- [ ] Analyze each package after updates

#### After Update
- [ ] Generate Melos configuration with `fvm dart run melos generate --no-select`
- [ ] Format all Dart code with `fvm dart format .`
- [ ] Run static analysis across all packages
- [ ] Verify no version conflicts in dependency tree
- [ ] Check build compatibility for all platforms
- [ ] Update documentation if needed

## Troubleshooting

### Common Issues

#### FVM Not Found
```bash
# Install FVM
dart pub global activate fvm

# Or via Homebrew
brew tap leoafarias/fvm
brew install fvm
```

#### yq Not Found
```bash
# Install via Homebrew
brew install yq
```

#### Ruby Version Issues
```bash
# Install rbenv
brew install rbenv

# Install Ruby 3.2.2
rbenv install 3.2.2
rbenv global 3.2.2
```

#### Pod Install Failures
```bash
# Clean and reinstall
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
```

#### Gradle Build Failures
```bash
# Clean Android build
cd android
./gradlew clean

# Update Gradle wrapper manually if needed
./gradlew wrapper --gradle-version=8.14.3

# Sync Gradle files
./gradlew --refresh-dependencies
```

#### AGP and Gradle Compatibility Issues
The script automatically ensures compatibility between AGP and Gradle versions:

| AGP Version | Compatible Gradle Version |
|-------------|--------------------------|
| 8.13-8.15   | 8.14.3                   |
| 8.10-8.12   | 8.10.2                   |
| 8.7-8.9     | 8.9                      |
| 8.4-8.6     | 8.6                      |
| 8.3         | 8.4                      |
| 8.2         | 8.2                      |
| 8.1         | 8.0                      |
| 8.0         | 8.0                      |
| Default     | 8.14.3                   |

If you encounter compatibility issues, the script will automatically select the correct Gradle version based on the AGP version. The compatibility mapping is based on the [official Android Gradle Plugin compatibility guide](https://developer.android.com/build/releases/gradle-plugin#updating-gradle).

### Rollback Procedure

If upgrade causes issues:

1. **Revert to previous Flutter version:**
   ```bash
   fvm use 3.34.0 --skip-pub-get # Previous stable version
   ```

2. **Restore pubspec.yaml files from git:**
   ```bash
   git checkout HEAD~1 -- pubspec.yaml packages/*/pubspec.yaml
   ```

3. **Restore CI configuration:**
   ```bash
   git checkout HEAD~1 -- .gitlab-ci.yml
   ```

4. **Restore Android Gradle files:**
   ```bash
   git checkout HEAD~1 -- android/settings.gradle.kts android/app/build.gradle.kts android/gradle/wrapper/gradle-wrapper.properties
   ```

5. **Clean and rebuild:**
   ```bash
   fvm flutter clean
   fvm flutter pub get
   cd android && ./gradlew clean
   cd ../ios && pod install --repo-update
   ```

## Best Practices

### Before Upgrade
- Create a backup branch before upgrading
- Review Flutter release notes for breaking changes
- Check package compatibility with new Flutter version
- Run full test suite to establish baseline

### During Upgrade
- Always use latest stable version - never beta/dev
- Run the complete upgrade script - don't skip steps
- Monitor for errors and address them immediately
- Update all related configurations (CI, docs, etc.)

### After Upgrade
- Verify CI/CD pipeline still works
- Update documentation if needed
- Commit all changes in a single upgrade commit

## Version Management

### Flutter Version Requirements
- **Always use the latest stable Flutter version**
- Never use beta or dev channels for production
- Verify version compatibility with all packages

### Dart Version Compatibility
- Dart version is automatically determined by Flutter version
- Ensure all packages support the Dart version
- Update package constraints if needed

### Package Version Updates
After Flutter upgrade, review and update:
- Package versions in `pubspec.yaml`
- Platform-specific dependencies (iOS/Android)
- Fastlane plugin versions
- Ruby gem versions
- Android Gradle plugin versions
- Android library dependency versions

### Android Gradle Version Management
The script automatically manages Android build system versions:

#### Gradle Plugins (settings.gradle.kts)
- **Android Gradle Plugin (AGP)** (`com.android.application`) - Build system plugin
- **Kotlin Plugin** (`org.jetbrains.kotlin.android`) - Kotlin language support
- **Google Services** (`com.google.gms.google-services`) - Firebase and Google Play services
- **Firebase Performance** (`com.google.firebase.firebase-perf`) - Performance monitoring
- **Firebase Crashlytics** (`com.google.firebase.crashlytics`) - Crash reporting

#### Gradle Dependencies (app/build.gradle.kts)
- **Firebase Analytics KTX** (`com.google.firebase:firebase-analytics-ktx`) - Analytics with Kotlin extensions
- **Desugar JDK Libs** (`com.android.tools:desugar_jdk_libs`) - Java 8+ API support for older Android versions
- **AndroidX Window** (`androidx.window:window` and `androidx.window:window-java`) - Window management and foldables support (both artifacts updated together)

#### Version Sources
- **Google Maven** (`https://dl.google.com/dl/android/maven2`) for Android/Firebase artifacts
  - Used for: AGP, Google Services, Firebase plugins, Firebase Analytics, Desugar JDK Libs
- **Maven Central** (`https://repo1.maven.org/maven2`) for other artifacts
  - Used for: AndroidX Window, Kotlin Plugin
- Automatically filters out pre-release versions (alpha, beta, rc, dev, snapshot, milestone, preview)
- Always selects the latest stable version available

## Version Conflict Resolution

### 1. Identify Conflicts
```bash
# Check for version conflicts
fvm dart pub deps --style=tree | grep -E "(conflict|overridden)"

# Analyze dependency tree
fvm dart pub deps --style=compact
```

### 2. Resolve Conflicts
- Use dependency overrides in root `pubspec.yaml` for conflicting versions
- Update packages to use compatible versions
- Remove duplicate dependencies across packages

```yaml
# Root pubspec.yaml - dependency overrides
dependency_overrides:
  # Force specific version for all packages
  http: 1.1.0
  dio: 5.4.0
```

### 3. Validate Resolution
```bash
# Ensure all packages resolve correctly
fvm dart pub get

# Verify no runtime conflicts
fvm flutter analyze
```

## Quick Reference

> 📖 **Before starting:** Review `.cursor/skills/flutter-upgrade-guidelines/SKILL.md` for detailed information.

```bash
# Complete upgrade process (2 steps):

# Step 1: Run upgrade script (automatically upgrades dependencies and removes carets)
./.cursor/commands/scripts/flutter_upgrade.sh

# Step 2: Generate Melos configuration and format code
fvm dart run melos generate --no-select  # Press Enter when prompted
fvm dart format .                        # Format all Dart code
```

## Important Notes

⚠️ **Always check `.cursor/skills/flutter-upgrade-guidelines/SKILL.md` before running the upgrade** - Contains detailed information, troubleshooting, and best practices

⚠️ **Always use the latest stable Flutter version** - the script automatically fetches it

⚠️ **Dependencies are automatically upgraded** - the script runs `fvm dart pub upgrade --major-versions`

⚠️ **Carets are automatically removed** - the script removes all (^) symbols from dependencies

⚠️ **Always press Enter when prompted** during `fvm dart run melos generate --no-select` to use the default option

⚠️ **Always run `fvm dart format .`** after `fvm dart run melos generate --no-select` to format generated code

⚠️ **Run the complete 2-step process** - don't skip any steps

---

**Remember: Always use the latest stable Flutter version and run the complete upgrade script to ensure all dependencies and configurations are properly updated.**

For detailed guidelines, see `.cursor/skills/flutter-upgrade-guidelines/SKILL.md`
