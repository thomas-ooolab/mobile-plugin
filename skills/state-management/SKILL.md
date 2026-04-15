---
name: state-management
description: "State management guidelines for Cubit with flutter_bloc and injectable-based dependency injection"
---

# Cubit State Management Guidelines

## Overview

Use `flutter_bloc` + `bloc` for state management. **Cubit is the default** — simpler API, adequate for most screens. Use BLoC only when explicit events/transforms are needed.

DI uses `injectable` (annotation-based) + `get_it` (container). Cubits, repositories, services, and use cases are registered via annotations; no manual service locator wrappers.

## Packages

```yaml
# pubspec.yaml
dependencies:
  bloc: ^8.0.0
  flutter_bloc: ^8.0.0
  equatable: ^2.0.0
  get_it: ^7.0.0
  injectable: ^2.0.0

dev_dependencies:
  bloc_test: ^9.0.0
  mocktail: ^1.0.0
  build_runner: ^2.0.0
  injectable_generator: ^2.0.0
```

## Dependency Injection with injectable

### Setup

1. Create DI configuration file:

```dart
// lib/locator/locator.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'locator.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();
```

2. Initialize before `runApp`:

```dart
void main() {
  configureDependencies();
  runApp(const App());
}
```

3. Generate DI code:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

### Annotations

| Annotation | Use |
|------------|-----|
| `@injectable` | Register class (new instance per resolve) |
| `@singleton` | Single shared instance |
| `@lazySingleton` | Singleton created on first resolve |
| `@Injectable(as: Interface)` | Register implementation against abstract interface |
| `@module` | Third-party/external registrations |
| `@factoryMethod` | Factory constructor registration |

### Registering a Cubit

```dart
@injectable
class FeatureCubit extends Cubit<FeatureState> {
  FeatureCubit(this._repository) : super(const FeatureInitial());

  final FeatureRepository _repository;

  Future<void> loadFeature() async {
    emit(const FeatureLoading());
    try {
      final features = await _repository.getFeatures();
      emit(FeatureLoaded(features: features));
    } catch (e) {
      emit(FeatureError(message: e.toString()));
    }
  }
}
```

### Registering a Repository (against abstract interface)

```dart
// Abstract
abstract interface class FeatureRepository {
  Future<List<Feature>> getFeatures();
}

// Implementation
@Injectable(as: FeatureRepository)
final class FeatureRepositoryImpl implements FeatureRepository {
  FeatureRepositoryImpl(this._service);

  final FeatureService _service;

  @override
  Future<List<Feature>> getFeatures() => _service.fetchAll();
}
```

### External Modules

```dart
@module
abstract class AppModule {
  @lazySingleton
  SharedPreferences get sharedPreferences => throw UnimplementedError();
}
```

## Cubit Pattern

### File Organization

| File | Purpose |
|------|---------|
| `feature_cubit.dart` | Cubit class |
| `feature_state.dart` | Sealed state classes |
| `feature_bloc.dart` | BLoC (only when events needed) |
| `feature_event.dart` | Events (BLoC only) |

### Cubit Implementation

```dart
// feature_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class FeatureCubit extends Cubit<FeatureState> {
  FeatureCubit(this._repository) : super(const FeatureInitial());

  final FeatureRepository _repository;

  Future<void> loadFeature() async {
    emit(const FeatureLoading());
    try {
      final features = await _repository.getFeatures();
      emit(FeatureLoaded(features: features));
    } catch (e) {
      emit(FeatureError(message: e.toString()));
    }
  }

  void reset() => emit(const FeatureInitial());
}
```

**Rules:**
- Extend `Cubit<State>` from `bloc` package
- Inject dependencies via constructor; `@injectable` handles wiring
- `emit()` is safe after `close()` in `bloc` ^8 — framework ignores emissions on closed cubit (logs warning). No custom `safeEmit` mixin needed.
- For explicit guard, check `isClosed` before async emit if desired.

### State Classes (sealed + equatable)

```dart
// feature_state.dart
import 'package:equatable/equatable.dart';

sealed class FeatureState extends Equatable {
  const FeatureState();

  @override
  List<Object?> get props => [];
}

final class FeatureInitial extends FeatureState {
  const FeatureInitial();
}

final class FeatureLoading extends FeatureState {
  const FeatureLoading();
}

final class FeatureLoaded extends FeatureState {
  const FeatureLoaded({required this.features});

  final List<Feature> features;

  @override
  List<Object?> get props => [features];
}

final class FeatureError extends FeatureState {
  const FeatureError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
```

**Rules:**
- `sealed` parent → exhaustive pattern matching
- All fields `final`
- Named constructor params
- `const` constructors where possible
- Override `props` from `Equatable`

## UI Integration

### Providing a Cubit

Resolve via `getIt` inside `BlocProvider`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/locator/locator.dart';

class FeatureScreen extends StatelessWidget {
  const FeatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FeatureCubit>()..loadFeature(),
      child: const FeatureView(),
    );
  }
}
```

### Consuming State

```dart
class FeatureView extends StatelessWidget {
  const FeatureView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeatureCubit, FeatureState>(
      builder: (context, state) {
        return switch (state) {
          FeatureInitial() => const SizedBox.shrink(),
          FeatureLoading() => const CircularProgressIndicator(),
          FeatureLoaded(:final features) => FeatureList(features: features),
          FeatureError(:final message) => ErrorView(message: message),
        };
      },
    );
  }
}
```

### Calling Cubit Methods

```dart
// Trigger from widget
context.read<FeatureCubit>().loadFeature();

// With param
context.read<FeatureCubit>().selectFeature(id: '1');
```

### BlocListener and MultiBlocListener

Two+ listeners → `MultiBlocListener` (flatter tree):

```dart
MultiBlocListener(
  listeners: [
    BlocListener<AuthCubit, AuthState>(
      listenWhen: (prev, curr) => prev.isLoggedIn != curr.isLoggedIn,
      listener: (context, state) {
        if (!state.isLoggedIn) Navigator.of(context).pushReplacementNamed('/login');
      },
    ),
    BlocListener<NotificationCubit, NotificationState>(
      listenWhen: (prev, curr) => curr.hasNew,
      listener: (context, state) => _showSnackBar(context, state.message),
    ),
  ],
  child: BlocBuilder<AuthCubit, AuthState>(builder: ...),
);
```

### Multiple Providers

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => getIt<FeatureCubit>()),
    BlocProvider(create: (_) => getIt<AnotherCubit>()),
  ],
  child: const FeatureView(),
);
```

## BLoC (when events needed)

Use BLoC when:
- Debouncing / throttling events (`EventTransformer`)
- Multiple event types compose into one state stream
- Complex event ordering

```dart
@injectable
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._repository) : super(const SearchInitial()) {
    on<QueryChanged>(_onQueryChanged, transformer: debounce(const Duration(milliseconds: 300)));
    on<SearchCleared>(_onSearchCleared);
  }

  final SearchRepository _repository;

  Future<void> _onQueryChanged(QueryChanged event, Emitter<SearchState> emit) async {
    emit(const SearchLoading());
    try {
      final results = await _repository.search(event.query);
      emit(SearchLoaded(results: results));
    } catch (e) {
      emit(SearchError(message: e.toString()));
    }
  }

  void _onSearchCleared(SearchCleared event, Emitter<SearchState> emit) {
    emit(const SearchInitial());
  }
}
```

Event transformer example:

```dart
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:stream_transform/stream_transform.dart';

EventTransformer<T> debounce<T>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}
```

## Testing

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

    test('initial state is FeatureInitial', () {
      expect(cubit.state, equals(const FeatureInitial()));
    });

    blocTest<FeatureCubit, FeatureState>(
      'emits [FeatureLoading, FeatureLoaded] on success',
      build: () {
        when(() => repository.getFeatures()).thenAnswer((_) async => const [Feature(id: '1', name: 'A')]);
        return cubit;
      },
      act: (c) => c.loadFeature(),
      expect: () => [
        const FeatureLoading(),
        const FeatureLoaded(features: [Feature(id: '1', name: 'A')]),
      ],
      verify: (_) => verify(() => repository.getFeatures()).called(1),
    );

    blocTest<FeatureCubit, FeatureState>(
      'emits [FeatureLoading, FeatureError] on failure',
      build: () {
        when(() => repository.getFeatures()).thenThrow(Exception('boom'));
        return cubit;
      },
      act: (c) => c.loadFeature(),
      expect: () => [
        const FeatureLoading(),
        isA<FeatureError>(),
      ],
    );
  });
}
```

### Testing with injectable

For widget/integration tests, override registrations:

```dart
setUp(() {
  getIt.reset();
  getIt.registerFactory<FeatureRepository>(() => _MockFeatureRepository());
  configureDependencies(); // or manual registers
});
```

## BLoC Lint

Include `bloc_lint` in `analysis_options.yaml`:

```yaml
include: package:bloc_lint/recommended.yaml
```

Key rules:
- Sealed state classes → exhaustive pattern matching
- `final` state fields → immutability
- Named constructor params
- Const constructors where possible

Run linter:

```bash
fvm dart pub global activate bloc_tools
bloc lint .
```

## Error Handling

- Wrap async body in `try/catch`
- Emit error state with message
- Log via `logger` or `developer.log` for debugging
- Map exceptions → user-friendly messages

```dart
Future<void> loadFeature() async {
  emit(const FeatureLoading());
  try {
    final features = await _repository.getFeatures();
    emit(FeatureLoaded(features: features));
  } catch (e, stack) {
    log('Failed to load features', error: e, stackTrace: stack);
    emit(const FeatureError(message: 'Failed to load. Try again.'));
  }
}
```

## Best Practices

1. **Cubit by default, BLoC when needed** — prefer simpler API
2. **One Cubit per feature/screen** — keep focused
3. **No business logic in widgets** — delegate to Cubit
4. **Handle all states** — initial, loading, loaded, error
5. **Named constructor params** — required by `bloc_lint`
6. **Sealed state + `final` fields** — enables pattern matching + immutability
7. **`@injectable` on cubits/repos** — constructor injection auto-wired
8. **Resolve via `getIt<Cubit>()` inside `BlocProvider.create`** — never call `getIt` inside widget `build` except in `create` callback
9. **Private mocks in tests** — `_MockXxx extends Mock`
10. **`const` state constructors** — reduce rebuilds

## Common Mistakes

### ❌ Manual GetIt call inside Cubit

```dart
// ❌ BAD
class FeatureCubit extends Cubit<FeatureState> {
  FeatureCubit() : super(const FeatureInitial());

  final _repository = getIt<FeatureRepository>(); // ❌ hidden dep
}
```

### ✅ Constructor injection with `@injectable`

```dart
// ✅ GOOD
@injectable
class FeatureCubit extends Cubit<FeatureState> {
  FeatureCubit(this._repository) : super(const FeatureInitial());
  final FeatureRepository _repository;
}
```

### ❌ Resolving cubit outside `create`

```dart
// ❌ BAD - resolved every build
Widget build(BuildContext context) {
  final cubit = getIt<FeatureCubit>();
  return BlocProvider.value(value: cubit, child: ...);
}
```

### ✅ Resolve inside `BlocProvider.create`

```dart
// ✅ GOOD
BlocProvider(
  create: (_) => getIt<FeatureCubit>()..loadFeature(),
  child: const FeatureView(),
);
```

### ❌ Positional constructor params

```dart
// ❌ BAD
FeatureCubit(FeatureRepository repository) : _repository = repository, super(...);
```

### ✅ Named or single-positional with field init

```dart
// ✅ GOOD (named — required by bloc_lint for multi-param)
FeatureCubit({required FeatureRepository repository}) : _repository = repository, super(...);

// ✅ GOOD (single-param positional with @injectable field)
FeatureCubit(this._repository) : super(...);
```

### ❌ Abstract state class

```dart
// ❌ BAD
abstract class FeatureState extends Equatable {}
```

### ✅ Sealed state class

```dart
// ✅ GOOD
sealed class FeatureState extends Equatable {
  const FeatureState();
}
```

### ❌ Mutable state fields

```dart
// ❌ BAD
class FeatureLoaded extends FeatureState {
  FeatureLoaded({required this.features});
  List<Feature> features; // not final
}
```

### ✅ Final fields, const constructor

```dart
// ✅ GOOD
final class FeatureLoaded extends FeatureState {
  const FeatureLoaded({required this.features});
  final List<Feature> features;

  @override
  List<Object?> get props => [features];
}
```

### ❌ Public mock classes

```dart
// ❌ BAD
class MockFeatureRepository extends Mock implements FeatureRepository {}
```

### ✅ Private mock classes

```dart
// ✅ GOOD
class _MockFeatureRepository extends Mock implements FeatureRepository {}
```
