# Test Helpers and Utilities

## Table of Contents
- [WidgetTesterExtension](#widgettesterextension)
- [Helper Functions](#helper-functions)

---

## WidgetTesterExtension

The project provides a comprehensive testing infrastructure in `test/test_helpers/test_helpers.dart`.

Use `pumpWidgetWithMaterialApp()` for all widget tests to ensure consistent test environment:

```dart
testWidgets('should render the layout', (tester) async {
  await tester.pumpWidgetWithMaterialApp(
    child: YourWidget(),
  );
  
  expect(find.byType(YourWidget), findsOneWidget);
});
```

**Benefits**:
- Automatically sets up MaterialApp, EasyLocalization, Sizer
- Provides all necessary repositories and cubits as mocks
- Handles orientation and screen size configuration
- Sets up GetIt locator with all dependencies
- Disables network image loading with `mockNetworkImages`
- Configures default currency for testing

**Optional Parameters**:
```dart
await tester.pumpWidgetWithMaterialApp(
  child: YourWidget(),
  orientation: Orientation.landscape,  // Default: portrait
  currencyCubit: mockCurrencyCubit,
  appCubit: mockAppCubit,
  userRepository: mockUserRepository,
  // ... and many more repositories/cubits
);
```

---

## Helper Functions

### Pagination Testing
```dart
mockPaginationViewMixin<Model>(
  controller: mockCubit,
  items: [item1, item2],
  isLoading: false,
  isInitialLoading: false,
  isError: false,
);
```

### Timezone Initialization
```dart
setUpAll(() {
  initTimezone();  // Sets timezone to Asia/Saigon
});
```

### Translation Initialization
```dart
setUpAll(() {
  initTranslations({
    'key': 'value',
    'another_key': 'another value',
  });
});
```

### InAppWebView Setup
```dart
setUpAll(() {
  initInAppWebViewPlatform();
});
```

### Disable EasyLogger
```dart
setUpAll(() {
  disableEasyLogger();  // Reduces log noise in tests
});
```
