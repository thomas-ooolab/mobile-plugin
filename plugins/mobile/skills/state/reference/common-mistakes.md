# Common Mistakes

## BAD: Manual GetIt call inside Cubit

```dart
// BAD
class FeatureCubit extends Cubit<FeatureState> {
  FeatureCubit() : super(const FeatureState());

  final _repository = sl<FeatureRepository>(); // BAD: hidden dep
}
```

## GOOD: Constructor injection with `@injectable`

```dart
// GOOD
@injectable
class FeatureCubit extends Cubit<FeatureState> {
  FeatureCubit({required FeatureRepository repository})
      : _repository = repository,
        super(const FeatureState());
  final FeatureRepository _repository;
}
```

---

## BAD: Resolving cubit outside `create`

```dart
// BAD - resolved every build
Widget build(BuildContext context) {
  final cubit = sl<FeatureCubit>();
  return BlocProvider.value(value: cubit, child: ...);
}
```

## GOOD: Resolve inside `BlocProvider.create`

```dart
// GOOD
BlocProvider(
  create: (_) => sl<FeatureCubit>()..loadFeature(),
  child: const FeatureView(),
);
```

---

## BAD: Positional constructor params

```dart
// BAD
FeatureCubit(FeatureRepository repository) : _repository = repository, super(...);
```

## GOOD: Named params

```dart
// GOOD — named params always, even single-param
FeatureCubit({required FeatureRepository repository})
    : _repository = repository,
      super(...);
```

---

## BAD: Union/sealed state — loses data on transition

```dart
// BAD — switching from loaded→loading discards features
@freezed
sealed class FeatureState with _$FeatureState {
  const factory FeatureState.initial() = FeatureInitial;
  const factory FeatureState.loading() = FeatureLoading;
  const factory FeatureState.loaded({required List<Feature> features}) = FeatureLoaded;
  const factory FeatureState.error({required String message}) = FeatureError;
}
// emit(FeatureLoading()) → features gone, can't show stale data
```

## GOOD: Single state class + DataLoadStatus — data persists

```dart
// GOOD — copyWith preserves features across re-loads
import 'package:app/core/state-management/state_management.dart';

@freezed
class FeatureState with _$FeatureState {
  const factory FeatureState({
    @Default(DataLoadStatus.initial) DataLoadStatus status,
    @Default([]) List<Feature> features,
    String? errorMessage,
  }) = _FeatureState;
}
// emit(state.copyWith(status: DataLoadStatus.loading)) → features still there
```

---

## BAD: Cubit with no DI annotation

```dart
// BAD — not registered in DI graph
class FeatureCubit extends Cubit<FeatureState> {
  FeatureCubit(this._repository) : super(const FeatureState());
```

## GOOD: Cubit annotated for DI

```dart
// GOOD — @injectable for feature cubits, @singleton for app-wide
@injectable
class FeatureCubit extends Cubit<FeatureState> {
  FeatureCubit({required FeatureRepository repository})
      : _repository = repository,
        super(const FeatureState());
  final FeatureRepository _repository;
```

---

## BAD: Public mock classes

```dart
// BAD
class MockFeatureRepository extends Mock implements FeatureRepository {}
```

## GOOD: Private mock classes

```dart
// GOOD
class _MockFeatureRepository extends Mock implements FeatureRepository {}
```
