# Mock Objects

## Table of Contents
- [Creating Mock Classes](#creating-mock-classes)
- [Registering Fallback Values](#registering-fallback-values)
- [Mocking with when and thenAnswer](#mocking-with-when-and-thenanswer)
- [Mocking Cubits with whenListen](#mocking-cubits-with-whenlisten)
- [Verifying Mock Calls](#verifying-mock-calls)

---

## Creating Mock Classes

**Location**: Define private mock classes directly in test files using `_` prefix:

```dart
// In your_feature_test.dart
class _MockFeatureRepository extends Mock implements FeatureRepository {}

class _MockFeatureCubit extends MockCubit<FeatureState>
    implements FeatureCubit {}

class _MockDeviceUtil extends Mock implements DeviceUtil {}
```

**Global Mocks**: Only add mocks to `test_helpers.dart` if they're used as default global mocks across many tests.

---

## Registering Fallback Values

For classes used as method parameters in mocks:

```dart
setUpAll(() {
  registerFallbackValue(FakeFeature());
  registerFallbackValue(FakeCallback());
});

class FakeFeature extends Fake implements Feature {}
class FakeCallback extends Fake implements Callback {}
```

---

## Mocking with when and thenAnswer

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

---

## Mocking Cubits with whenListen

```dart
final mockCubit = _MockFeatureCubit();
final state = FeatureState(status: DataLoadStatus.success);

whenListen(
  mockCubit,
  Stream.value(state),
  initialState: state,
);
```

---

## Verifying Mock Calls

```dart
verify(() => mockRepository.getFeatures()).called(1);
verifyNever(() => mockRepository.deleteFeature(any()));
```
