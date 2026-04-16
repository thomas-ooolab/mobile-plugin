# Unit Testing

## Table of Contents
- [Cubit Testing](#cubit-testing)
- [Repository Testing](#repository-testing)

---

## Cubit Testing

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
    
    test('initial state has status initial', () {
      expect(featureCubit.state.status, equals(DataLoadStatus.initial));
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

---

## Repository Testing

Test repositories in their respective packages:

```dart
void main() {
  group('FeatureRepository', () {
    late FeatureRepository repository;
    late MockFeatureRemoteDataSource mockRemoteDataSource;
    late MockLocalStorage mockStorage;
    
    setUp(() {
      mockRemoteDataSource = MockFeatureRemoteDataSource();
      mockStorage = MockLocalStorage();
      repository = FeatureRepository(
        remoteDataSource: mockRemoteDataSource,
        storage: mockStorage,
      );
    });
    
    test('getFeatures returns features from remote data source', () async {
      // Arrange
      final features = [Feature(id: 1, name: 'Test')];
      when(() => mockRemoteDataSource.getFeatures())
          .thenAnswer((_) async => features);
      
      // Act
      final result = await repository.getFeatures();
      
      // Assert
      expect(result, equals(features));
      verify(() => mockRemoteDataSource.getFeatures()).called(1);
    });
    
    test('throws exception when service fails', () async {
      // Arrange
      when(() => mockRemoteDataSource.getFeatures())
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
