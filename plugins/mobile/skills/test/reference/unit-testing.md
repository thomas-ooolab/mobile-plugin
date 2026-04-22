# Unit Testing

## Cubit Testing

See [`@state` → reference/testing.md](../../state/reference/testing.md) — canonical cubit test patterns (`bloc_test`, `mocktail`, private mocks, `blocTest`, `verify`).

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
      when(() => mockRemoteDataSource.getFeatures())
          .thenThrow(Exception('Network error'));
      
      expect(
        () => repository.getFeatures(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```
