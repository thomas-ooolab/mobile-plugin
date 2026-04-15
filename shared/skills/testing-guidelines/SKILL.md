---
name: testing-guidelines
description: "Testing guidelines and best practices for unit, widget, and integration tests"
---

# Testing Guidelines

## Testing Strategy

The project follows a comprehensive testing strategy with multiple testing layers:
- **Unit Tests**: Test individual functions, classes, and Cubits
- **Widget Tests**: Test UI components and widgets
- **Integration Tests**: Test complete user flows
- **Repository Tests**: Test data access layer in packages

## Test Structure

### Directory Organization
```
test/
├── components/          # Component tests (broadcast, pagination, etc.)
├── core/               # Core functionality tests
├── localization/       # Localization tests
├── mixin/             # Mixin tests
├── mocks/             # Shared mock objects
├── screens/           # Screen tests
├── test_helpers/      # Testing utilities and extensions
├── use_case/          # Use case tests
├── utils/             # Utility tests
└── widgets/           # Reusable widget tests
```

## Test Helpers and Utilities

### `test_helpers.dart` - Core Testing Utilities

The project provides a comprehensive testing infrastructure in `test/test_helpers/test_helpers.dart`:

#### WidgetTesterExtension
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
  courseRepository: mockCourseRepository,
  // ... and many more repositories/cubits
);
```

#### Helper Functions

**Pagination Testing**:
```dart
mockPaginationViewMixin<Model>(
  controller: mockCubit,
  items: [item1, item2],
  isLoading: false,
  isInitialLoading: false,
  isError: false,
);
```

**Timezone Initialization**:
```dart
setUpAll(() {
  initTimezone();  // Sets timezone to Asia/Saigon
});
```

**Translation Initialization**:
```dart
setUpAll(() {
  initTranslations({
    'key': 'value',
    'another_key': 'another value',
  });
});
```

**InAppWebView Setup**:
```dart
setUpAll(() {
  initInAppWebViewPlatform();
});
```

**Disable EasyLogger**:
```dart
setUpAll(() {
  disableEasyLogger();  // Reduces log noise in tests
});
```

## Unit Testing

### Cubit Testing
Use `bloc_test` package for testing Cubits:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

// Define private mock classes in the test file
class _MockFeatureRepository extends Mock implements FeatureRepository {}

void main() {
  group('FeatureCubit', () {
    late FeatureCubit featureCubit;
    late _MockFeatureRepository mockRepository;
    
    setUp(() {
      mockRepository = _MockFeatureRepository();
      featureCubit = FeatureCubit(mockRepository);
    });
    
    tearDown(() {
      featureCubit.close();
    });
    
    test('initial state is FeatureState.initial()', () {
      expect(
        featureCubit.state,
        equals(FeatureState.initial()),
      );
    });
    
    blocTest<FeatureCubit, FeatureState>(
      'emits [loading, success] when loadFeatures succeeds',
      build: () {
        when(() => mockRepository.getFeatures())
            .thenAnswer((_) async => []);
        return featureCubit;
      },
      act: (cubit) => cubit.loadFeatures(),
      expect: () => [
        FeatureState(status: DataLoadStatus.loading),
        FeatureState(status: DataLoadStatus.success),
      ],
    );
    
    blocTest<FeatureCubit, FeatureState>(
      'emits [loading, failure] when repository throws exception',
      build: () {
        when(() => mockRepository.getFeatures())
            .thenThrow(Exception('Network error'));
        return featureCubit;
      },
      act: (cubit) => cubit.loadFeatures(),
      expect: () => [
        FeatureState(status: DataLoadStatus.loading),
        FeatureState(status: DataLoadStatus.failure),
      ],
    );
  });
}
```

### Repository Testing
Test repositories in their respective packages:

```dart
void main() {
  group('FeatureRepository', () {
    late FeatureRepository repository;
    late MockFeatureService mockService;
    late MockLocalStorage mockStorage;
    
    setUp(() {
      mockService = MockFeatureService();
      mockStorage = MockLocalStorage();
      repository = FeatureRepository(
        service: mockService,
        storage: mockStorage,
      );
    });
    
    test('getFeatures returns features from service', () async {
      // Arrange
      final features = [Feature(id: 1, name: 'Test')];
      when(() => mockService.getFeatures())
          .thenAnswer((_) async => features);
      
      // Act
      final result = await repository.getFeatures();
      
      // Assert
      expect(result, equals(features));
      verify(() => mockService.getFeatures()).called(1);
    });
    
    test('throws exception when service fails', () async {
      // Arrange
      when(() => mockService.getFeatures())
          .thenThrow(Exception('Network error'));
      
      // Act & Assert
      expect(
        () => repository.getFeatures(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

## Widget Testing

### Screen Testing with Cubit
```dart
import '../../../test_helpers/test_helpers.dart';

// Define private mock cubits in the test file
class _MockFeatureCubit extends MockCubit<FeatureState>
    implements FeatureCubit {}

void main() {
  group(FeatureScreen, () {
    late _MockFeatureCubit mockFeatureCubit;
    
    setUp(() {
      mockFeatureCubit = _MockFeatureCubit();
      final state = FeatureState(status: DataLoadStatus.success);
      whenListen(
        mockFeatureCubit,
        Stream.value(state),
        initialState: state,
      );
    });
    
    testWidgets('can be instantiated', (tester) async {
      await tester.pumpWidgetWithMaterialApp(
        child: FeatureScreen(),
      );
      
      expect(find.byType(FeatureView), findsOneWidget);
    });
    
    testWidgets('should render the layout as design expectation', (
      tester,
    ) async {
      await tester.pumpWidgetWithMaterialApp(
        child: BlocProvider<FeatureCubit>(
          create: (context) => mockFeatureCubit,
          child: FeatureScreen(),
        ),
      );
      
      expect(find.text('Expected Text'), findsOneWidget);
      expect(find.byType(FeatureWidget), findsWidgets);
    });
    
    testWidgets('should call cubit method when button tapped', (
      tester,
    ) async {
      when(() => mockFeatureCubit.loadMore()).thenAnswer((_) async {});
      
      await tester.pumpWidgetWithMaterialApp(
        child: BlocProvider<FeatureCubit>(
          create: (context) => mockFeatureCubit,
          child: FeatureScreen(),
        ),
      );
      
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      
      verify(() => mockFeatureCubit.loadMore()).called(1);
    });
  });
}
```

### Widget Testing with Pagination
```dart
testWidgets('should render pagination items', (tester) async {
  final items = List.generate(
    5,
    (index) => Feature(id: index, name: 'Feature $index'),
  );
  
  mockPaginationViewMixin(
    controller: mockFeatureCubit,
    items: items,
    isLoading: false,
  );
  
  await tester.pumpWidgetWithMaterialApp(
    child: BlocProvider<FeatureCubit>(
      create: (context) => mockFeatureCubit,
      child: FeatureListView(),
    ),
  );
  
  expect(find.text('Feature 0'), findsOneWidget);
  expect(find.text('Feature 4'), findsOneWidget);
});
```

### Simple Widget Test (No Cubit)
```dart
void main() {
  group(SimpleWidget, () {
    testWidgets('displays correct text', (tester) async {
      await tester.pumpWidgetWithMaterialApp(
        child: SimpleWidget(text: 'Hello World'),
      );
      
      expect(find.text('Hello World'), findsOneWidget);
    });
  });
}
```

## Mock Objects

### Creating Mock Classes

**Location**: Define private mock classes directly in test files using `_` prefix:

```dart
// In your_feature_test.dart
class _MockFeatureRepository extends Mock implements FeatureRepository {}

class _MockFeatureCubit extends MockCubit<FeatureState>
    implements FeatureCubit {}

class _MockDeviceUtil extends Mock implements DeviceUtil {}
```

**Global Mocks**: Only add mocks to `test_helpers.dart` if they're used as default global mocks across many tests.

### Registering Fallback Values
For classes used as method parameters in mocks:

```dart
setUpAll(() {
  registerFallbackValue(FakeFeature());
  registerFallbackValue(FakeCallback());
});

class FakeFeature extends Fake implements Feature {}
class FakeCallback extends Fake implements Callback {}
```

### Mocking with `when` and `thenAnswer`
```dart
// Async methods
when(() => mockRepository.getFeatures())
    .thenAnswer((_) async => [feature1, feature2]);

// Synchronous methods
when(() => mockDeviceUtil.isTabletLayout)
    .thenReturn(false);

// Void methods
when(() => mockCubit.loadData())
    .thenAnswer((_) async {});

// Throwing exceptions
when(() => mockRepository.getFeatures())
    .thenThrow(Exception('Network error'));
```

### Mocking Cubits with `whenListen`
```dart
final mockCubit = _MockFeatureCubit();
final state = FeatureState(status: DataLoadStatus.success);

whenListen(
  mockCubit,
  Stream.value(state),
  initialState: state,
);
```

### Verifying Mock Calls
```dart
verify(() => mockRepository.getFeatures()).called(1);
verifyNever(() => mockRepository.deleteFeature(any()));
```

## Testing Best Practices

### 1. Test Organization
- Use `group()` to organize related tests
- Use descriptive test names that describe behavior
- Follow AAA pattern: Arrange, Act, Assert
- Group name should be the class/feature being tested

```dart
void main() {
  group(FeatureScreen, () {  // Use Type, not string
    group('success state', () {
      // tests for success state
    });
    
    group('error state', () {
      // tests for error state
    });
  });
}
```

### 2. Test Naming Conventions
- Start with action: "should render...", "should call...", "should display..."
- Be specific about expected behavior
- Include relevant conditions

```dart
testWidgets('should render loading indicator when state is loading', ...);
testWidgets('should call cubit.loadMore when scroll reaches bottom', ...);
testWidgets('should display error message when state is failure', ...);
```

### 3. Mock Strategy
- **DO**: Mock external dependencies (repositories, services, APIs)
- **DO**: Use private mock classes with `_` prefix in test files
- **DO**: Only add mocks to `test_helpers.dart` if used globally
- **DON'T**: Mock the code under test
- **DON'T**: Mock value objects or entities

### 4. setUp and tearDown
```dart
void main() {
  group('FeatureTest', () {
    late FeatureCubit cubit;
    late MockRepository mockRepository;
    
    setUpAll(() {
      // One-time setup for all tests in group
      initTimezone();
      registerFallbackValue(FakeFeature());
    });
    
    setUp(() {
      // Setup before each test
      mockRepository = MockRepository();
      cubit = FeatureCubit(mockRepository);
    });
    
    tearDown(() {
      // Cleanup after each test
      cubit.close();
    });
  });
}
```

### 5. Test Coverage
- Aim for >80% test coverage
- Focus on critical business logic
- Test happy path and error scenarios
- Test edge cases and boundary conditions
- Test state transitions in Cubits

### 6. Async Testing
```dart
testWidgets('loads data on init', (tester) async {
  await tester.pumpWidgetWithMaterialApp(child: FeatureScreen());
  
  // Wait for initial render
  await tester.pump();
  
  // Wait for all animations to complete
  await tester.pumpAndSettle();
  
  expect(find.text('Loaded'), findsOneWidget);
});
```

### 7. Localization Testing
```dart
setUpAll(() {
  initTranslations({
    'feature.title': 'Feature Title',
    'feature.description': 'Feature Description',
  });
});

testWidgets('displays translated text', (tester) async {
  await tester.pumpWidgetWithMaterialApp(
    child: FeatureWidget(),
  );
  
  expect(find.text('Feature Title'), findsOneWidget);
});
```

### 8. Testing with Orientation
```dart
testWidgets('renders correctly in landscape', (tester) async {
  await tester.pumpWidgetWithMaterialApp(
    child: FeatureWidget(),
    orientation: Orientation.landscape,
  );
  
  expect(find.byType(FeatureWidget), findsOneWidget);
});
```

### 9. Testing with Custom Repositories
```dart
testWidgets('uses custom repository', (tester) async {
  final mockCustomRepository = _MockCustomRepository();
  when(() => mockCustomRepository.getData())
      .thenAnswer((_) async => testData);
  
  await tester.pumpWidgetWithMaterialApp(
    child: FeatureScreen(),
    courseRepository: mockCustomRepository,
  );
  
  verify(() => mockCustomRepository.getData()).called(1);
});
```

## Common Testing Patterns

### Testing Error States
```dart
testWidgets('displays error message when state is failure', (
  tester,
) async {
  final errorState = FeatureState(
    status: DataLoadStatus.failure,
    errorMessage: 'Something went wrong',
  );
  
  whenListen(
    mockFeatureCubit,
    Stream.value(errorState),
    initialState: errorState,
  );
  
  await tester.pumpWidgetWithMaterialApp(
    child: BlocProvider<FeatureCubit>(
      create: (context) => mockFeatureCubit,
      child: FeatureScreen(),
    ),
  );
  
  expect(find.text('Something went wrong'), findsOneWidget);
  expect(find.byType(ErrorGeneralView), findsOneWidget);
});
```

### Testing Loading States
```dart
testWidgets('displays loading indicator when loading', (tester) async {
  final loadingState = FeatureState(status: DataLoadStatus.loading);
  
  whenListen(
    mockFeatureCubit,
    Stream.value(loadingState),
    initialState: loadingState,
  );
  
  await tester.pumpWidgetWithMaterialApp(
    child: BlocProvider<FeatureCubit>(
      create: (context) => mockFeatureCubit,
      child: FeatureScreen(),
    ),
  );
  
  expect(find.byType(VleCircleLoadingIndicator), findsOneWidget);
});
```

### Testing Empty States
```dart
testWidgets('displays empty message when no items', (tester) async {
  mockPaginationViewMixin(
    controller: mockFeatureCubit,
    items: [],
  );
  
  await tester.pumpWidgetWithMaterialApp(
    child: BlocProvider<FeatureCubit>(
      create: (context) => mockFeatureCubit,
      child: FeatureListView(),
    ),
  );
  
  expect(find.text('No items found'), findsOneWidget);
});
```

### Testing User Interactions
```dart
testWidgets('navigates to detail screen when item tapped', (
  tester,
) async {
  final mockRouter = _MockRouter();
  when(() => mockRouter.push(any())).thenAnswer((_) async => null);
  
  await tester.pumpWidgetWithMaterialApp(
    child: FeatureListItem(
      item: testItem,
      onTap: () => mockRouter.push('/detail'),
    ),
  );
  
  await tester.tap(find.byType(FeatureListItem));
  await tester.pumpAndSettle();
  
  verify(() => mockRouter.push('/detail')).called(1);
});
```

### Testing Text Input
```dart
testWidgets('updates text field value', (tester) async {
  await tester.pumpWidgetWithMaterialApp(
    child: FeatureForm(),
  );
  
  await tester.enterText(
    find.byType(TextField),
    'Test input',
  );
  await tester.pumpAndSettle();
  
  expect(find.text('Test input'), findsOneWidget);
});
```

### Testing Scrolling
```dart
testWidgets('loads more items when scrolled to bottom', (tester) async {
  when(() => mockFeatureCubit.loadMore()).thenAnswer((_) async {});
  
  await tester.pumpWidgetWithMaterialApp(
    child: BlocProvider<FeatureCubit>(
      create: (context) => mockFeatureCubit,
      child: FeatureListView(),
    ),
  );
  
  // Scroll to bottom
  await tester.drag(
    find.byType(ListView),
    Offset(0, -500),
  );
  await tester.pumpAndSettle();
  
  verify(() => mockFeatureCubit.loadMore()).called(1);
});
```

## Running Tests

**Note**: This project uses FVM (Flutter Version Management). Always prefix Flutter/Dart commands with `fvm`.

### Command Line
```bash
# Run all tests
fvm flutter test

# Run specific test file
fvm flutter test --coverage --branch-coverage --fail-fast -r failures-only --test-randomize-ordering-seed random test/screens/feature/feature_screen_test.dart

# Run tests with coverage
fvm flutter test --coverage --branch-coverage --fail-fast -r failures-only --test-randomize-ordering-seed random

# Run tests with coverage and additional options (recommended)
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

## Troubleshooting

### Common Issues

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

## Additional Resources

### Key Testing Packages
- `flutter_test`: Flutter's testing framework
- `bloc_test`: Testing utilities for Bloc/Cubit
- `mocktail`: Modern mocking library for Dart
- `mocktail_image_network`: Mock network images in tests

### Useful Commands
```bash
# Analyze code for issues
fvm flutter analyze

# Format code
fvm dart format .

# Run custom lint
fvm dart run custom_lint
```

