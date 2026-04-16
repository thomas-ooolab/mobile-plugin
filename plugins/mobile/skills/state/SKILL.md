---
name: state
description: "Cubit/BLoC patterns with flutter_bloc, @freezed states, DataLoadStatus enum, and injectable DI annotations. Use when implementing or reviewing cubits, state classes, BLoC patterns, or UI state integration."
---

# Cubit State Management Guidelines

## Overview

Use `flutter_bloc` + `bloc` for state management. **Cubit is the default** — simpler API, adequate for most screens. Use BLoC only when explicit events/transforms are needed.

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

## Dependency Injection

See `@di` for full setup: `sl` instance, `@InjectableInit`, annotations, micropackage modules, and external modules.

Quick reference for cubits:
- `@injectable` — feature cubits (new instance per resolve)
- `@singleton` — app-wide cubits (`AppCubit`, `NavigationCubit`)
- Resolve via `sl<FeatureCubit>()` inside `BlocProvider.create`

## Cubit Pattern

### File Organization

| File | Purpose |
|------|---------|
| `feature_cubit.dart` | Cubit class |
| `feature_state.dart` | State class + status enum |
| `feature_bloc.dart` | BLoC (only when events needed) |
| `feature_event.dart` | Events (BLoC only) |

### Cubit Implementation

```dart
// feature_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

@injectable  // use @singleton for app-wide cubits
class FeatureCubit extends Cubit<FeatureState> {
  FeatureCubit(this._repository) : super(const FeatureState());

  final FeatureRepository _repository;

  Future<void> loadFeature() async {
    emit(state.copyWith(status: DataLoadStatus.loading));
    try {
      final features = await _repository.getFeatures();
      emit(state.copyWith(status: DataLoadStatus.success, features: features));
    } catch (e) {
      emit(state.copyWith(status: DataLoadStatus.failure, errorMessage: e.toString()));
    }
  }

  void reset() => emit(const FeatureState());
}
```

**Rules:**
- Annotate with `@injectable` (feature cubits) or `@singleton` (app-wide cubits) — required for DI wiring
- Extend `Cubit<State>` from `bloc` package
- Inject dependencies via constructor; annotation handles wiring
- Use `state.copyWith(status: ...)` to transition — preserves all existing state data
- `emit()` is safe after `close()` in `bloc` ^8 — framework ignores emissions on closed cubit (logs warning). No custom `safeEmit` mixin needed.
- For explicit guard, check `isClosed` before async emit if desired.

### Shared Status Enum — DataLoadStatus

Use `DataLoadStatus` from `lib/core/state-management/` for all feature states. Never define feature-specific status enums.

```dart
// lib/core/state-management/data_load_status.dart

/// The status that's used for general state when calling api in bloc
enum DataLoadStatus {
  initial,
  loading,
  refreshing,
  success,
  failure,
}
```

```dart
// lib/core/state-management/state_management.dart  (barrel)
export 'data_load_status.dart';
```

Import: `import 'package:app/core/state-management/state_management.dart';`

### State Classes (freezed + DataLoadStatus)

Single state class with `DataLoadStatus`. Preserves all data across status transitions — e.g. `features` stays visible while re-loading or on failure.

```dart
// feature_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/state-management/state_management.dart';

part 'feature_state.freezed.dart';

@freezed
class FeatureState with _$FeatureState {
  const factory FeatureState({
    @Default(DataLoadStatus.initial) DataLoadStatus status,
    @Default([]) List<Feature> features,
    String? errorMessage,
  }) = _FeatureState;
}
```

Run `build_runner` after creating/editing state:
```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

Switch on enum in UI:
```dart
switch (state.status) {
  DataLoadStatus.initial    => const SizedBox.shrink(),
  DataLoadStatus.loading    => const CircularProgressIndicator(),
  DataLoadStatus.refreshing => FeatureList(features: state.features), // show stale while refreshing
  DataLoadStatus.success    => FeatureList(features: state.features),
  DataLoadStatus.failure    => ErrorView(message: state.errorMessage ?? ''),
}
```

**Rules:**
- `@freezed` single class — generates `copyWith`, equality, `toString`
- Use `DataLoadStatus` from `lib/core/state-management/` — never define feature-specific status enums
- `refreshing` = background reload while showing stale data; `loading` = initial/blocking load
- `@Default(...)` on all fields — enables `const FeatureState()` as initial state
- Use `state.copyWith(status: DataLoadStatus.loading)` — never emit a fresh state that discards existing data
- No `sealed` union — avoids data loss when switching between sub-states

## UI Integration

### Providing a Cubit

Resolve via `sl` inside `BlocProvider`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/core/di/di.dart';

class FeatureScreen extends StatelessWidget {
  const FeatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<FeatureCubit>()..loadFeature(),
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
        return switch (state.status) {
          DataLoadStatus.initial    => const SizedBox.shrink(),
          DataLoadStatus.loading    => const CircularProgressIndicator(),
          DataLoadStatus.refreshing => FeatureList(features: state.features),
          DataLoadStatus.success    => FeatureList(features: state.features),
          DataLoadStatus.failure    => ErrorView(message: state.errorMessage ?? ''),
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
    BlocProvider(create: (_) => sl<FeatureCubit>()),
    BlocProvider(create: (_) => sl<AnotherCubit>()),
  ],
  child: const FeatureView(),
);
```

## Error Handling

Wrap async body in `try/catch`, emit failure state, log, and map exceptions to user-friendly messages.

```dart
Future<void> loadFeature() async {
  emit(state.copyWith(status: DataLoadStatus.loading));
  try {
    final features = await _repository.getFeatures();
    emit(state.copyWith(status: DataLoadStatus.success, features: features));
  } catch (e, stack) {
    log('Failed to load features', error: e, stackTrace: stack);
    emit(state.copyWith(status: DataLoadStatus.failure, errorMessage: 'Failed to load. Try again.'));
  }
}
```

## Best Practices

1. **Cubit by default, BLoC when needed** — prefer simpler API
2. **One Cubit per feature/screen** — keep focused
3. **No business logic in widgets** — delegate to Cubit
4. **Handle all statuses** — initial, loading, refreshing, success, failure
5. **Named constructor params** — required by `bloc_lint`
6. **Single `@freezed` state + `DataLoadStatus`** — `copyWith` preserves data across transitions
7. **`@injectable` or `@singleton` on cubits** — feature cubits use `@injectable`, app-wide use `@singleton`
8. **Resolve via `sl<Cubit>()` inside `BlocProvider.create`** — never in widget `build`
9. **Private mocks in tests** — `_MockXxx extends Mock`
10. **`const` state constructors** — reduce rebuilds

## Reference

| Topic | File |
|-------|------|
| Advanced cubit patterns (safeEmit, refresh, form, multi, singleton) | [reference/cubit.md](reference/cubit.md) |
| Testing cubits with bloc_test | [reference/testing.md](reference/testing.md) |
| Common mistakes (❌/✅ pairs) | [reference/common-mistakes.md](reference/common-mistakes.md) |
```
