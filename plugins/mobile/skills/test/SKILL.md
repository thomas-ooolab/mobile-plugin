---
name: test
description: "Unit, widget, and integration testing with bloc_test and mocktail. Use when writing or reviewing tests for cubits, widgets, repositories, or setting up test helpers."
---

## Related Guidelines

- `@dart` - Dart language patterns used in test code
- `@state` - Cubit/BLoC patterns being tested
- `@presentation` - Screen and widget structures under test
- `@domain` - Use case interfaces being mocked
- `@data` - Repository impls and data sources being tested
- `@clean` - Layer boundaries enforced by test isolation

# Testing Guidelines

## Testing Strategy

The project follows a comprehensive testing strategy with multiple testing layers:
- **Unit Tests**: Test individual functions, classes, and Cubits
- **Widget Tests**: Test UI components and widgets
- **Integration Tests**: Test complete user flows
- **Repository Tests**: Test data access layer in packages

## Test Structure

### Directory Organization

`test/` mirrors `lib/`. A test file lives at the same relative path as the code it tests — only the root changes from `lib/` to `test/` and the filename gains `_test`.

```
lib/screens/feature/feature_screen.dart
→ test/screens/feature/feature_screen_test.dart

lib/core/utils/date_utils.dart
→ test/core/utils/date_utils_test.dart
```

Test-only directories (no `lib/` counterpart) live at the root of `test/`:

```
test/
├── components/          # mirrors lib/components/
├── core/               # mirrors lib/core/
├── localization/       # mirrors lib/localization/
├── mixin/             # mirrors lib/mixin/
├── screens/           # mirrors lib/screens/
├── use_case/          # mirrors lib/use_case/
├── utils/             # mirrors lib/utils/
├── widgets/           # mirrors lib/widgets/
├── mocks/             # test-only: shared mock objects
└── test_helpers/      # test-only: utilities and extensions
```

## Reference Documentation

| Topic | File | What's inside |
|-------|------|---------------|
| `pumpWidgetWithMaterialApp`, pagination, timezone, translations, WebView setup | [`reference/test-helpers.md`](reference/test-helpers.md) | All test helper utilities with usage examples |
| Cubit testing → see `@state` skill; repository testing | [`reference/unit-testing.md`](reference/unit-testing.md) | Repository test patterns; cubit tests → `@state/reference/testing.md` |
| Screen tests with Cubit, pagination widgets, simple widget tests | [`reference/widget-testing.md`](reference/widget-testing.md) | Widget test patterns |
| Mock classes, fallback values, `when`/`thenAnswer`, `whenListen`, verify | [`reference/mocking.md`](reference/mocking.md) | Full mocking reference |
| Test organization, naming, AAA, setUp/tearDown, coverage, async, all state patterns | [`reference/patterns.md`](reference/patterns.md) | Best practices + common patterns (error, loading, empty, input, scroll) |
| Common failures and fixes, key packages, lint/format commands | [`reference/troubleshooting.md`](reference/troubleshooting.md) | Troubleshooting and resources |

## Running Tests

**Note**: This project uses FVM (Flutter Version Management). Always prefix Flutter/Dart commands with `fvm`.

### Command Line
```bash
# Run all tests
fvm flutter test

# Run specific test file
fvm flutter test --coverage --branch-coverage --fail-fast -r failures-only --test-randomize-ordering-seed random test/screens/feature/feature_screen_test.dart

# Run tests with coverage (recommended)
fvm flutter test --coverage --branch-coverage --fail-fast -r failures-only --test-randomize-ordering-seed random

# Run tests in specific directory
fvm flutter test --coverage --branch-coverage --fail-fast -r failures-only --test-randomize-ordering-seed random test/screens/

# Run tests with name pattern
fvm flutter test --coverage --branch-coverage --fail-fast -r failures-only --test-randomize-ordering-seed random --name "should render"
```

### IDE Integration
- Use VS Code Flutter extension for test running
- Click the "Run" link above test functions
- Use "Run All Tests" from the Testing panel
- Set breakpoints for debugging tests

### Viewing Coverage
```bash
# Generate coverage report
fvm flutter test --coverage --branch-coverage --fail-fast -r failures-only --test-randomize-ordering-seed random

# View coverage in browser (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Continuous Integration

### Test Automation
- Run tests on every pull request
- Generate coverage reports automatically
- Fail builds on test failures
- Maintain test quality metrics (>80% coverage target)

### CI Configuration Example
```yaml
test:
  script:
    - fvm flutter test --coverage --branch-coverage --fail-fast -r failures-only --test-randomize-ordering-seed random
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/lcov.info
```
