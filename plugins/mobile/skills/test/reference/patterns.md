# Testing Best Practices and Common Patterns

## Table of Contents
- [Test Organization](#1-test-organization)
- [Test Naming Conventions](#2-test-naming-conventions)
- [Mock Strategy](#3-mock-strategy)
- [setUp and tearDown](#4-setup-and-teardown)
- [Test Coverage](#5-test-coverage)
- [Async Testing](#6-async-testing)
- [Localization Testing](#7-localization-testing)
- [Testing with Orientation](#8-testing-with-orientation)
- [Testing with Custom Repositories](#9-testing-with-custom-repositories)
- [Testing Error States](#testing-error-states)
- [Testing Loading States](#testing-loading-states)
- [Testing Empty States](#testing-empty-states)
- [Testing User Interactions](#testing-user-interactions)
- [Testing Text Input](#testing-text-input)
- [Testing Scrolling](#testing-scrolling)

---

## 1. Test Organization

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

---

## 2. Test Naming Conventions

- Start with action: "should render...", "should call...", "should display..."
- Be specific about expected behavior
- Include relevant conditions

```dart
testWidgets('should render loading indicator when state is loading', ...);
testWidgets('should call cubit.loadMore when scroll reaches bottom', ...);
testWidgets('should display error message when state is failure', ...);
```

---

## 3. Mock Strategy

- **DO**: Mock external dependencies (repositories, services, APIs)
- **DO**: Use private mock classes with `_` prefix in test files
- **DO**: Only add mocks to `test_helpers.dart` if used globally
- **DON'T**: Mock the code under test
- **DON'T**: Mock value objects or entities

---

## 4. setUp and tearDown

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

---

## 5. Test Coverage

- Aim for >80% test coverage
- Focus on critical business logic
- Test happy path and error scenarios
- Test edge cases and boundary conditions
- Test state transitions in Cubits

---

## 6. Async Testing

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

---

## 7. Localization Testing

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

---

## 8. Testing with Orientation

```dart
testWidgets('renders correctly in landscape', (tester) async {
  await tester.pumpWidgetWithMaterialApp(
    child: FeatureWidget(),
    orientation: Orientation.landscape,
  );
  
  expect(find.byType(FeatureWidget), findsOneWidget);
});
```

---

## 9. Testing with Custom Repositories

```dart
testWidgets('uses custom repository', (tester) async {
  final mockCustomRepository = _MockCustomRepository();
  when(() => mockCustomRepository.getData())
      .thenAnswer((_) async => testData);
  
  await tester.pumpWidgetWithMaterialApp(
    child: FeatureScreen(),
    userRepository: mockCustomRepository,
  );
  
  verify(() => mockCustomRepository.getData()).called(1);
});
```

---

## Testing Error States

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

---

## Testing Loading States

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
  
  expect(find.byType(AppCircleLoadingIndicator), findsOneWidget);
});
```

---

## Testing Empty States

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

---

## Testing User Interactions

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

---

## Testing Text Input

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

---

## Testing Scrolling

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
