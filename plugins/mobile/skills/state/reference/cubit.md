# Cubit Patterns

## Contents
- [CubitMixin and safeEmit](#cubitmixin-and-safeemit)
- [Refresh Pattern](#refresh-pattern)
- [Form Cubit Pattern](#form-cubit-pattern)
- [Multiple Cubits on One Screen](#multiple-cubits-on-one-screen)
- [App-Wide Singleton Cubit](#app-wide-singleton-cubit)

---

## CubitMixin and safeEmit

Use `CubitMixin<State>` from `core/state_management` to get `safeEmit` — guards against emitting after `close()`.

```dart
@injectable
class FeatureCubit extends Cubit<FeatureState> with CubitMixin<FeatureState> {
  FeatureCubit(this._repository) : super(const FeatureState());

  final FeatureRepository _repository;

  Future<void> load() async {
    safeEmit(state.copyWith(status: .loading));
    try {
      final data = await _repository.getData();
      safeEmit(state.copyWith(status: .success, data: data));
    } catch (e) {
      safeEmit(state.copyWith(status: .failure, errorMessage: e.toString()));
    }
  }
}
```

Use `safeEmit` instead of `emit` whenever the cubit performs async work — prevents warnings when the widget tree disposes the cubit before the future resolves.

---

## Refresh Pattern

Use `refreshing` status for background reloads that should show stale data while fetching.

```dart
Future<void> refresh() async {
  // Show stale data + loading indicator, not full loading spinner
  safeEmit(state.copyWith(status: .refreshing));
  try {
    final data = await _repository.getData();
    safeEmit(state.copyWith(status: .success, data: data));
  } catch (e) {
    // Keep existing data visible, show error
    safeEmit(state.copyWith(status: .failure, errorMessage: e.toString()));
  }
}
```

UI switch — show content for both `refreshing` and `success`:

```dart
switch (state.status) {
  .initial    => const SizedBox.shrink(),
  .loading    => const CircularProgressIndicator(),
  .refreshing => Stack(children: [
      FeatureList(features: state.features),
      const LinearProgressIndicator(),  // subtle reload indicator
    ]),
  .success    => FeatureList(features: state.features),
  .failure    => ErrorView(message: state.errorMessage ?? ''),
}
```

---

## Form Cubit Pattern

Use `FormStatus` for form submission state — separate from `DataLoadStatus` (which is for data loading).

```dart
// lib/core/state_management/form_status.dart
enum FormStatus { initial, submitting, success, failure }
```

```dart
// feature_state.dart
@freezed
class LoginState with _$LoginState {
  const factory LoginState({
    @Default('') String email,
    @Default('') String password,
    @Default(FormStatus.initial) FormStatus status,
    String? errorMessage,
  }) = _LoginState;
}

// login_cubit.dart
@injectable
class LoginCubit extends Cubit<LoginState> with CubitMixin<LoginState> {
  LoginCubit(this._authRepository) : super(const LoginState());

  final AuthenticationRepository _authRepository;

  void emailChanged(String email) =>
      safeEmit(state.copyWith(email: email, status: .initial));

  void passwordChanged(String password) =>
      safeEmit(state.copyWith(password: password, status: .initial));

  Future<void> submit() async {
    safeEmit(state.copyWith(status: .submitting));
    try {
      await _authRepository.login(email: state.email, password: state.password);
      safeEmit(state.copyWith(status: .success));
    } catch (e) {
      safeEmit(state.copyWith(status: .failure, errorMessage: e.toString()));
    }
  }
}
```

---

## Multiple Cubits on One Screen

Use `MultiBlocProvider` when a screen needs more than one cubit. Each cubit handles a separate concern.

```dart
// route.dart
class FeatureRoute extends AppPageRoute<void, void> {
  FeatureRoute() : super(
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<FeatureCubit>()..load()),
        BlocProvider(create: (_) => sl<FilterCubit>()),
      ],
      child: const FeatureScreen(),
    ),
  );
}
```

```dart
// feature_screen.dart — consume each cubit independently
class FeatureScreen extends StatelessWidget {
  const FeatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<FeatureCubit, FeatureState>(
      listenWhen: (prev, curr) => curr.status == .failure,
      listener: (context, state) => _showError(context, state.errorMessage),
      child: BlocBuilder<FilterCubit, FilterState>(
        builder: (context, filterState) {
          return BlocBuilder<FeatureCubit, FeatureState>(
            builder: (context, state) => FeatureView(
              state: state,
              filter: filterState,
            ),
          );
        },
      ),
    );
  }
}
```

---

## App-Wide Singleton Cubit

Use `@singleton` for cubits that live for the entire app lifetime and are shared globally.

```dart
// navigation_cubit.dart
@singleton
class NavigationCubit extends Cubit<NavigationState> with CubitMixin<NavigationState> {
  NavigationCubit() : super(const NavigationState());

  void selectTab(int index) =>
      safeEmit(state.copyWith(selectedIndex: index));
}

// app_cubit.dart
@singleton
class AppCubit extends Cubit<AppState> with CubitMixin<AppState> {
  AppCubit(this._authRepository) : super(const AppState());

  final AuthenticationRepository _authRepository;

  Future<void> checkAuth() async { ... }
}
```

Provide app-wide cubits at the root:

```dart
// app.dart
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AppCubit>()..checkAuth()),
        BlocProvider(create: (_) => sl<NavigationCubit>()),
      ],
      child: const MaterialApp(...),
    );
  }
}
```
