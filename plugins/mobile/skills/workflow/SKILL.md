---
name: workflow
description: "Git branching, feature development, and code quality processes for this project. Use when starting a feature branch, creating PRs, setting up the dev environment, or reviewing workflow conventions."
---

# Development Workflow

Guidelines for git workflow, CI/CD integration, and development processes specific to this project.


## Related Guidelines

This document covers development workflow and processes. For implementation details, see:
- `@clean` - Architecture patterns and implementation
- `@test` - Testing strategies and commands
- `@flutter` - Flutter implementation patterns
- `@state` - BLoC/Cubit implementation

## Prerequisites

### Required Tools

- **FVM (Flutter Version Management)** - MANDATORY for all Flutter/Dart commands
- Flutter SDK 3.38.7 or higher (managed via FVM)
- Dart SDK 3.10.7 or higher (managed via FVM)
- Android Studio / VS Code with Flutter extensions
- Git for version control
- Melos for monorepo management

### FVM Installation

```bash
# Install FVM globally via Dart
dart pub global activate fvm

# Or via Homebrew (macOS/Linux)
brew tap leoafarias/fvm
brew install fvm

# Verify installation
fvm --version
```

### ⚠️ CRITICAL: Always Use FVM

**ALL Flutter and Dart commands MUST be prefixed with `fvm`:**

```bash
# ✅ CORRECT - With FVM prefix
fvm flutter run
fvm flutter pub get
fvm dart run build_runner build

# ❌ WRONG - Without FVM prefix
flutter run           # DON'T DO THIS
flutter pub get       # DON'T DO THIS
dart run build_runner # DON'T DO THIS
```

**Why FVM is Required:**
- Ensures consistent Flutter/Dart versions across the team
- Prevents version mismatch issues
- Simplifies version management for multiple projects
- Required by project CI/CD pipelines

## Project Setup

### Initial Setup

```bash
# Clone the repository
git clone <repository-url>
cd learningos

# Install dependencies
fvm flutter pub get

# Run code generation
fvm dart run build_runner build -d

# Run tests to verify setup
fvm flutter test --coverage --branch-coverage --fail-fast -r failures-only --test-randomize-ordering-seed random
```

## Development Environment

### Run app (flavor and env config)

The project has 7 environments (see README §10. Run app). Use **Development** only while developing; do not use the other configurations for day-to-day development.

Each run must specify a flavor and all env files via `--dart-define-from-file`. Prefix with `fvm` and add `-d "iPhone"` (or another device) when needed.

**Development** (recommended for local work):

```bash
fvm flutter run --flavor development \
  --dart-define-from-file environment_configurations/api/.development.env \
  --dart-define-from-file environment_configurations/tenant/.development.env \
  --dart-define-from-file environment_configurations/.general.env \
  --dart-define-from-file environment_configurations/certificates/.trusted_certificates.env \
  --dart-define-from-file environment_configurations/certificates/.trusted_fingerprints.env
```

**Staging:**

```bash
fvm flutter run --flavor staging \
  --dart-define-from-file environment_configurations/api/.staging.env \
  --dart-define-from-file environment_configurations/tenant/.staging.env \
  --dart-define-from-file environment_configurations/.general.env \
  --dart-define-from-file environment_configurations/certificates/.trusted_certificates.env \
  --dart-define-from-file environment_configurations/certificates/.trusted_fingerprints.env
```

**Sandbox:**

```bash
fvm flutter run --flavor sandbox \
  --dart-define-from-file environment_configurations/api/.production.env \
  --dart-define-from-file environment_configurations/tenant/.sandbox.env \
  --dart-define-from-file environment_configurations/.general.env \
  --dart-define-from-file environment_configurations/certificates/.trusted_certificates.env \
  --dart-define-from-file environment_configurations/certificates/.trusted_fingerprints.env
```

**Other production-based flavors** (`--flavor <name>`): use `environment_configurations/api/.production.env` + `environment_configurations/tenant/.<name>.env` + `.general.env` + both certificate env files.

### Code Generation

```bash
# Generate dependency injection code
fvm dart run build_runner build -d

# Watch for changes and regenerate
fvm dart run build_runner watch -d

# Clean and regenerate
fvm dart run build_runner clean
fvm dart run build_runner build -d
```

## Git Workflow

### Branch Naming Convention

- **Target branch**: Use the target branch the user provides; if none, use the project's default integration branch.
- **Branch name**: `<type>/<ticket_ID>` (e.g. `feat/PROJ-123`).

| Type | Use for |
|------|--------|
| `feat` | New feature (non-breaking change which adds functionality) |
| `fix` | Bug fix (non-breaking change which fixes an issue) |
| `!` | Breaking change (fix or feature that would cause existing functionality to change) |
| `refactor` | Code refactor |
| `test` | Unit test |
| `ci` | Build configuration change |
| `docs` | Documentation |
| `chore` | Chore |

### Commit Message Format

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Build/tooling changes

**Examples:**
```
feat(auth): add biometric authentication

fix(course): resolve video playback issue

refactor(bloc): simplify state management logic
```

## Feature Development Process

### 1. Planning
- Create feature branch from main
- Define requirements and acceptance criteria
- Plan UI/UX design
- Identify dependencies and affected packages

### 2. Implementation
- Follow existing architecture patterns (see `@clean`)
- Implement BLoC/Cubit for state management (see `@state`)
- Add proper error handling
- Include localization support
- Write comprehensive tests (see `@test`)

### 3. Testing
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for user flows
- Test with different flavors

### 4. Code Review
- Self-review before submitting PR
- Ensure code follows project standards
- Verify test coverage
- Check for performance implications

## Code Quality

### Pre-commit Checks

```bash
# Format code
fvm dart format .

# Analyze code
fvm flutter analyze

# Run all tests
fvm flutter test --coverage --branch-coverage --fail-fast -r failures-only --test-randomize-ordering-seed random

# Check formatting (CI check)
fvm dart format --set-exit-if-changed .
```

### Quality Checklist

- [ ] Code formatted with `fvm dart format .`
- [ ] No analyzer warnings: `fvm flutter analyze`
- [ ] All tests pass: `fvm flutter test --coverage --branch-coverage --fail-fast -r failures-only --test-randomize-ordering-seed random`
- [ ] Test coverage maintained or improved
- [ ] Documentation updated if needed
- [ ] No hardcoded strings (use localization)
- [ ] Follows architecture patterns
- [ ] Widget classes used (not build methods)


## Tools and Commands

**⚠️ REMINDER:** All Flutter/Dart commands AND Melos commands require the `fvm` prefix.

### Common Commands

```bash
# Run melos scripts (defined in melos.yaml)
fvm dart run melos <script-name>

# Format code
fvm dart format .

# Fix linter issues
fvm dart fix --apply

# Generate translations (REQUIRED after updating translations/ files)

fvm dart run melos generate-translation

# Generate app icons
fvm dart run melos generate-app-icon

# Generate splash screens
fvm dart run melos generate-splash-screen
```

### Package Management

```bash
# Add dependency to main app
fvm flutter pub add package_name

# Add dependency to specific package
cd packages/package_name
fvm flutter pub add dependency_name

# Update all dependencies
fvm flutter pub upgrade

# Update specific package
fvm flutter pub upgrade package_name
```

## Development Best Practices

### 1. Code Organization
- Follow feature-based structure
- Keep functions and classes focused
- Use meaningful names
- Organize imports properly

### 2. Version Control
- Commit frequently with meaningful messages
- Keep commits atomic (single logical change)
- Review changes before committing
- Use branches for features/fixes

### 3. Documentation
- Document public APIs
- Update README for significant changes
- Maintain package READMEs
- Add code comments for complex logic

### 4. Writing Cursor Skills
- **Avoid duplication**: Don't write skills that are already covered by another skill file
- Check existing skill files before creating new guidelines
- Reference related skills using `@skill-name` syntax
- Keep skills focused on a single concern (workflow, architecture, testing, etc.)
- Update the "Related Guidelines" section to help users find relevant information

### 5. Testing
- Write tests alongside code
- Test happy path and error cases
- Maintain high test coverage
- Use mocks appropriately

### 6. Performance
- Profile app performance regularly
- Monitor memory usage
- Optimize build times
- Use code generation efficiently

## Troubleshooting

See [reference/troubleshooting.md](reference/troubleshooting.md) for FVM issues, build runner problems, and dependency conflicts.

## References

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- Project-specific skills: `@clean`, `@test`, `@flutter`, `@state`, `@dart`, `@bash`, `@add-whitelabel-guidelines`
