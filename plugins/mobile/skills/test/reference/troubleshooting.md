# Troubleshooting and Additional Resources

## Table of Contents
- [Common Issues](#common-issues)
- [Key Testing Packages](#key-testing-packages)
- [Useful Commands](#useful-commands)

---

## Common Issues

**Issue**: Tests fail with "Bad state: No test data"
**Solution**: Ensure you're using `pumpWidgetWithMaterialApp()` which sets up EasyLocalization

**Issue**: Mock not working as expected
**Solution**: Ensure you've registered fallback values for complex types used in `any()`

**Issue**: Network images failing in tests
**Solution**: `pumpWidgetWithMaterialApp()` automatically handles this with `mockNetworkImages`

**Issue**: "Failed to load dynamic library" in tests
**Solution**: Run `initInAppWebViewPlatform()` in `setUpAll()` for WebView tests

**Issue**: Timezone-related test failures
**Solution**: Call `initTimezone()` in `setUpAll()` for tests dealing with dates/times

**Issue**: Translation keys showing instead of text
**Solution**: Call `initTranslations()` with required translations in `setUpAll()`

---

## Key Testing Packages

- `flutter_test`: Flutter's testing framework
- `bloc_test`: Testing utilities for Bloc/Cubit
- `mocktail`: Modern mocking library for Dart
- `mocktail_image_network`: Mock network images in tests

---

## Useful Commands

```bash
# Analyze code for issues
fvm flutter analyze

# Format code
fvm dart format .

# Run custom lint
fvm dart run custom_lint
```
