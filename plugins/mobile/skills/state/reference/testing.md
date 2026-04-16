# Testing Cubits

Use `bloc_test` + `mocktail`. Mocks **must be private** (`_MockXxx`).

```dart
// feature_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFeatureRepository extends Mock implements FeatureRepository {}

void main() {
  group('FeatureCubit', () {
    late FeatureCubit cubit;
    late _MockFeatureRepository repository;

    setUp(() {
      repository = _MockFeatureRepository();
      cubit = FeatureCubit(repository);
    });

    tearDown(() => cubit.close());

    test('initial state has status initial', () {
      expect(cubit.state.status, equals(DataLoadStatus.initial));
    });

    blocTest<FeatureCubit, FeatureState>(
      'emits [loading, success] on success',
      build: () {
        when(() => repository.getFeatures()).thenAnswer((_) async => const [Feature(id: '1', name: 'A')]);
        return cubit;
      },
      act: (c) => c.loadFeature(),
      expect: () => [
        isA<FeatureState>().having((s) => s.status, 'status', DataLoadStatus.loading),
        isA<FeatureState>()
            .having((s) => s.status, 'status', DataLoadStatus.success)
            .having((s) => s.features, 'features', const [Feature(id: '1', name: 'A')]),
      ],
      verify: (_) => verify(() => repository.getFeatures()).called(1),
    );

    blocTest<FeatureCubit, FeatureState>(
      'emits [loading, failure] on failure',
      build: () {
        when(() => repository.getFeatures()).thenThrow(Exception('boom'));
        return cubit;
      },
      act: (c) => c.loadFeature(),
      expect: () => [
        isA<FeatureState>().having((s) => s.status, 'status', DataLoadStatus.loading),
        isA<FeatureState>().having((s) => s.status, 'status', DataLoadStatus.failure),
      ],
    );
  });
}
```

## Testing with injectable

For widget/integration tests, override registrations:

```dart
setUp(() {
  sl.reset();
  sl.registerFactory<FeatureRepository>(() => _MockFeatureRepository());
  configureDependencies(); // or manual registers
});
```
