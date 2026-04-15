---
name: state-management
description: "State management guidelines for Cubit and State files following bloc_lint rules"
---

# Cubit State Management Guidelines

## State Management Overview

The project uses Cubit (a simplified BLoC) with `flutter_bloc` for state management. **Cubit is the recommended approach** for most use cases as it provides a simpler API while maintaining clear separation between UI and business logic. Use BLoC only when you need explicit event handling and complex event transformations.

### Dependency Injection Pattern

**CRITICAL**: This project uses a **service locator pattern** via `GetIt` (see `lib/locator/locator.dart`).

**ALWAYS use `context.repository.xxx` instead of `context.read<Repository>()`** for dependency injection.

```dart
// ✅ GOOD - Service locator pattern
BlocProvider(
  create: (context) => UserCubit(
    userRepository: context.repository.user,           // ✅ Correct!
    analyticsRepository: context.repository.analytics,  // ✅ Correct!
  ),
  child: const UserView(),
);

// ❌ BAD - Don't use context.read()
BlocProvider(
  create: (context) => UserCubit(
    userRepository: context.read<UserRepository>(),          // ❌ Wrong!
    analyticsRepository: context.read<AnalyticsRepository>(), // ❌ Wrong!
  ),
  child: const UserView(),
);
```

**Available repositories through service locator:**
```dart
context.repository.user              // UserRepository
context.repository.authentication    // AuthenticationRepository
context.repository.session          // SessionRepository
context.repository.course           // CourseRepository
context.repository.assignments      // AssignmentRepository
context.repository.notification     // NotificationRepository
context.repository.crashlytics      // CrashlyticsRepository
context.repository.point            // PointRepository
context.repository.report           // ReportRepository
context.repository.resource         // ResourceRepository
context.repository.reward           // RewardRepository
context.repository.children         // ChildrenRepository
context.repository.banner           // BannerRepository
context.repository.analytics        // AnalyticsRepository
context.repository.configuration    // ConfigurationRepository
context.repository.instructor       // InstructorRepository
context.repository.booking          // BookingRepository
context.repository.learningGroup    // LearningGroupRepository
context.repository.workspace        // WorkspaceRepository
context.repository.progress         // ProgressRepository
context.repository.cart             // CartRepository
context.repository.invoice          // InvoiceRepository
context.repository.credit           // CreditRepository
context.repository.creditAccount    // CreditAccountRepository
context.repository.skill            // SkillRepository
```

**Other dependencies available:**
```dart
context.useCase                  // UseCaseProvider
context.deviceUtil              // DeviceUtil
context.appLink                 // AppLinkHandler
context.timezone                // TimezoneHandler
context.webViewManager          // WebViewManager
context.permission              // AppPermission
context.firebaseAnalytics       // FirebaseAnalytics
context.firebasePerformance     // FirebasePerformance
context.localNotification       // LocalNotification
context.quickActions            // QuickActions
context.internetConnection      // InternetConnection
context.googleSignIn            // GoogleSignIn
```

## BLoC Lint Configuration

This project follows the official BLoC lint rules from [bloclibrary.dev/lint](https://bloclibrary.dev/lint/). 

### Setup
Ensure `bloc_lint` is included in your `analysis_options.yaml`:

```yaml
include: package:bloc_lint/recommended.yaml
```

### Key Lint Rules
- **Use sealed classes for states**: Enables exhaustive pattern matching
- **Make state fields final and immutable**: Prevents state mutation
- **Use named parameters**: All constructor parameters must be named
- **Avoid public mutable properties**: Keep state immutable
- **Use const constructors**: Make states const when possible

## State Management Structure

### File Organization
- **Cubits** (Recommended): State management - `feature_cubit.dart`
- **States**: Immutable state classes - `feature_state.dart`
- **BLoCs** (Use only when needed): Complex event handling - `feature_bloc.dart`
- **Events** (BLoC only): Immutable event classes - `feature_event.dart`

### Naming Conventions
- Cubit: `FeatureCubit`
- State: `FeatureState`
- BLoC: `FeatureBloc` (when needed)
- Event: `FeatureEvent` (BLoC only)

## State Management Patterns

### Cubit Pattern (Recommended)
Cubit is simpler than BLoC and is recommended for most use cases. It provides direct methods instead of events.

**Important**: Use `CubitMixin` and `safeEmit` to prevent "Cubit already closed" errors:

```dart
// feature_cubit.dart
class FeatureCubit extends Cubit<FeatureState> with CubitMixin<FeatureState> {
  FeatureCubit({
    required FeatureRepository repository,
  }) : _repository = repository,
       super(const FeatureInitial());
  
  final FeatureRepository _repository;
  
  Future<void> loadFeature() async {
    try {
      safeEmit(const FeatureLoading());
      final features = await _repository.getFeatures();
      safeEmit(FeatureLoaded(features: features));
    } catch (e) {
      safeEmit(FeatureError(message: e.toString()));
    }
  }
  
  void updateFeature({required String id}) {
    safeEmit(const FeatureLoading());
    // Business logic
    safeEmit(FeatureLoaded(features: updatedData));
  }
}
```

**Key Points**:
- Mix in `CubitMixin<YourState>` to your Cubit
- Use `safeEmit` instead of `emit` to handle closed Cubit scenarios
- Always use named parameters in constructor
- Initialize with const state when possible


## State Classes

### Best Practices
- Use `equatable` for state classes to enable proper comparison
- Make states immutable
- Include all necessary data in state
- Use sealed classes for better type safety
- **Always use named parameters** in state constructors

```dart
// feature_state.dart
sealed class FeatureState extends Equatable {
  const FeatureState();
}

class FeatureInitial extends FeatureState {
  const FeatureInitial();
  
  @override
  List<Object?> get props => [];
}

class FeatureLoading extends FeatureState {
  const FeatureLoading();
  
  @override
  List<Object?> get props => [];
}

class FeatureLoaded extends FeatureState {
  const FeatureLoaded({
    required this.features,
  });
  
  final List<Feature> features;
  
  @override
  List<Object?> get props => [features];
}

class FeatureError extends FeatureState {
  const FeatureError({
    required this.message,
  });
  
  final String message;
  
  @override
  List<Object?> get props => [message];
}
```


## UI Integration

### Dependency Injection with Service Locator

This project uses a **service locator pattern** via `GetIt` (see `lib/locator/locator.dart`). 

**ALWAYS use `context.repository.xxx` instead of `context.read<Repository>()`** for dependency injection.

```dart
// Available through BuildContext extension:
context.repository.user           // UserRepository
context.repository.authentication  // AuthenticationRepository
context.repository.session        // SessionRepository
context.repository.course         // CourseRepository
context.repository.notification   // NotificationRepository
context.repository.analytics      // AnalyticsRepository
// ... and all other repositories

// Also available:
context.useCase                   // UseCaseProvider
context.deviceUtil                // DeviceUtil
context.firebaseAnalytics        // FirebaseAnalytics
context.permission               // AppPermission
```

### Using Cubit in Widgets

Always use named parameters and inject dependencies via service locator:

```dart
// feature_screen.dart
class FeatureScreen extends StatelessWidget {
  const FeatureScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FeatureCubit(
        repository: context.repository.feature, // ✅ Use service locator
      ),
      child: const FeatureView(),
    );
  }
}

class FeatureView extends StatelessWidget {
  const FeatureView({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeatureCubit, FeatureState>(
      builder: (context, state) {
        return switch (state) {
          FeatureLoading() => const CircularProgressIndicator(),
          FeatureLoaded(:final features) => FeatureList(features: features),
          FeatureError(:final message) => ErrorWidget(message: message),
          FeatureInitial() => const SizedBox.shrink(),
        };
      },
    );
  }
}
```

**Real-world example with multiple dependencies:**

```dart
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserProfileCubit(
        userRepository: context.repository.user,         // ✅ Service locator
        analyticsRepository: context.repository.analytics, // ✅ Service locator
      )..loadProfile(userId),
      child: const UserProfileView(),
    );
  }
}
```

**Example with use cases:**

```dart
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(
        authenticationRepository: context.repository.authentication,
        userRepository: context.repository.user,
        determineAccountUseCase: context.useCase.determineAccount,
      ),
      child: const LoginView(),
    );
  }
}
```

### BlocListener and MultiBlocListener

When you need **more than two** BlocListeners (i.e. three or more), use **MultiBlocListener** instead of nesting multiple `BlocListener` widgets. For exactly two listeners, prefer **MultiBlocListener** as well for a flatter tree and consistent style.

```dart
// ✅ GOOD – MultiBlocListener when you have two or more listeners
MultiBlocListener(
  listeners: [
    BlocListener<CourseBroadcastCubit, CourseBroadcastState>(
      listenWhen: (previous, current) => current.event == CourseBroadcastEvent.jumpToRecommendationTab,
      listener: (_, _) => _homeCubit.changeTab(HomeTabTypes.myLearning),
    ),
    BlocListener<HomeCubit, HomeState>(
      listenWhen: (previous, current) => previous.shouldEnableFreshChat != current.shouldEnableFreshChat,
      listener: (_, state) {
        if (state.shouldEnableFreshChat) FreshChatButton.show(context);
      },
    ),
  ],
  child: BlocConsumer<HomeCubit, HomeState>(...),
);

// ❌ AVOID – Nesting many BlocListeners
BlocListener<A, AState>(
  listener: ...,
  child: BlocListener<B, BState>(
    listener: ...,
    child: BlocListener<C, CState>(
      listener: ...,
      child: ...,
    ),
  ),
),
```

## Error Handling

### Cubit Error Handling
- Always handle errors in Cubit methods
- Emit error states with meaningful messages
- Log errors for debugging
- Provide user-friendly error messages
- Use try-catch blocks in all async operations

```dart
Future<void> loadFeature() async {
  try {
    emit(const FeatureLoading());
    final features = await _repository.getFeatures();
    emit(FeatureLoaded(features: features));
  } catch (e, stackTrace) {
    // Log error for debugging
    logger.error('Failed to load features', error: e, stackTrace: stackTrace);
    // Emit user-friendly error state
    emit(FeatureError(message: 'Failed to load features. Please try again.'));
  }
}
```

## Testing Cubits

### Unit Testing with bloc_test

Use the `bloc_test` package for testing Cubits.

**IMPORTANT**: Mock classes MUST be private (prefixed with underscore).

```dart
// feature_cubit_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ✅ GOOD - Private mock class
class _MockFeatureRepository extends Mock implements FeatureRepository {}

void main() {
  group('FeatureCubit', () {
    late FeatureCubit featureCubit;
    late _MockFeatureRepository mockRepository;
    
    setUp(() {
      mockRepository = _MockFeatureRepository();
      featureCubit = FeatureCubit(
        repository: mockRepository,
      );
    });
    
    tearDown(() {
      featureCubit.close();
    });
    
    test('initial state is FeatureInitial', () {
      expect(featureCubit.state, equals(const FeatureInitial()));
    });
    
    group('loadFeature', () {
      final mockFeatures = [
        Feature(id: '1', name: 'Feature 1'),
        Feature(id: '2', name: 'Feature 2'),
      ];
      
      blocTest<FeatureCubit, FeatureState>(
        'emits [FeatureLoading, FeatureLoaded] when loadFeature succeeds',
        build: () {
          when(() => mockRepository.getFeatures())
              .thenAnswer((_) async => mockFeatures);
          return featureCubit;
        },
        act: (cubit) => cubit.loadFeature(),
        expect: () => [
          const FeatureLoading(),
          FeatureLoaded(features: mockFeatures),
        ],
        verify: (_) {
          verify(() => mockRepository.getFeatures()).called(1);
        },
      );
      
      blocTest<FeatureCubit, FeatureState>(
        'emits [FeatureLoading, FeatureError] when loadFeature fails',
        build: () {
          when(() => mockRepository.getFeatures())
              .thenThrow(Exception('Failed to load'));
          return featureCubit;
        },
        act: (cubit) => cubit.loadFeature(),
        expect: () => [
          const FeatureLoading(),
          isA<FeatureError>(),
        ],
      );
    });
  });
}
```

**Why private mocks?**
- Prevents accidental usage outside test file
- Follows encapsulation best practices
- Makes it clear mocks are test-only
- Aligns with Dart's privacy conventions

## Best Practices

### General Guidelines
1. **Prefer Cubits over BLoCs**: Use Cubit for most use cases; only use BLoC when you need explicit event handling
2. **Keep Cubits focused**: Each Cubit should handle one feature or screen
3. **Avoid business logic in UI**: Keep all business logic in Cubits
4. **Handle all states**: Always handle loading, success, and error states
5. **Use proper error handling**: Implement try-catch blocks in all async operations
6. **Test thoroughly**: Write comprehensive tests for all Cubits
7. **Follow naming conventions**: Use consistent naming across the project
8. **Use CubitMixin and safeEmit**: Always mix in `CubitMixin` and use `safeEmit` instead of `emit`

### Testing Guidelines
9. **Mock classes MUST be private**: Prefix all mock classes with underscore
   ```dart
   // ✅ GOOD
   class _MockUserRepository extends Mock implements UserRepository {}
   
   // ❌ BAD
   class MockUserRepository extends Mock implements UserRepository {}
   ```

### Dependency Injection Guidelines
10. **ALWAYS use service locator**: Use `context.repository.xxx` instead of `context.read<Repository>()`
   ```dart
   // ✅ GOOD - Service locator pattern
   BlocProvider(
     create: (context) => UserCubit(
       userRepository: context.repository.user,
       analyticsRepository: context.repository.analytics,
     ),
     child: const UserView(),
   );
   
   // ❌ BAD - Don't use context.read()
   BlocProvider(
     create: (context) => UserCubit(
       userRepository: context.read<UserRepository>(), // ❌ Wrong!
       analyticsRepository: context.read<AnalyticsRepository>(), // ❌ Wrong!
     ),
     child: const UserView(),
   );
   ```

11. **Use BuildContext extensions**: Access dependencies through context extensions
    ```dart
    // Repositories
    context.repository.user
    context.repository.authentication
    context.repository.course
    context.repository.notification
    
    // Use Cases
    context.useCase.determineAccount
    context.useCase.synchronizeInformation
    
    // Utilities
    context.deviceUtil
    context.permission
    context.firebaseAnalytics
    ```

12. **Inject dependencies through constructor**: All Cubit dependencies must be injected via constructor
    ```dart
    // ✅ GOOD - Constructor injection with named parameters
    class UserProfileCubit extends Cubit<UserProfileState> 
        with CubitMixin<UserProfileState> {
      UserProfileCubit({
        required UserRepository userRepository,
        required AnalyticsRepository analyticsRepository,
      }) : _userRepository = userRepository,
           _analyticsRepository = analyticsRepository,
           super(const UserProfileInitial());
      
      final UserRepository _userRepository;
      final AnalyticsRepository _analyticsRepository;
    }
    
    // ❌ BAD - Don't use getIt directly in Cubit
    class UserProfileCubit extends Cubit<UserProfileState> {
      UserProfileCubit() : super(const UserProfileInitial());
      
      final _userRepository = getIt<UserRepository>(); // ❌ Wrong!
    }
    ```

### BLoC Lint Compliance
13. **Always use named parameters**: All constructor parameters must be named
    ```dart
    // ✅ Good
    FeatureCubit({required FeatureRepository repository})
    
    // ❌ Bad
    FeatureCubit(FeatureRepository repository)
    ```

14. **Use sealed classes for states**: Enables exhaustive pattern matching
    ```dart
    // ✅ Good
    sealed class FeatureState extends Equatable {}
    
    // ❌ Bad
    abstract class FeatureState extends Equatable {}
    ```

15. **Make state fields final and immutable**: All state properties must be final
    ```dart
    // ✅ Good
    class FeatureLoaded extends FeatureState {
      const FeatureLoaded({required this.features});
      final List<Feature> features;
    }
    
    // ❌ Bad
    class FeatureLoaded extends FeatureState {
      FeatureLoaded({required this.features});
      List<Feature> features;
    }
    ```

16. **Use const constructors**: Make states const when possible for better performance
    ```dart
    // ✅ Good
    safeEmit(const FeatureLoading());
    
    // ❌ Bad
    safeEmit(FeatureLoading());
    ```

17. **Use pattern matching**: Leverage Dart 3 pattern matching with sealed classes
    ```dart
    // ✅ Good
    return switch (state) {
      FeatureLoading() => const CircularProgressIndicator(),
      FeatureLoaded(:final features) => FeatureList(features: features),
      FeatureError(:final message) => ErrorWidget(message: message),
      FeatureInitial() => const SizedBox.shrink(),
    };
    ```

### Running BLoC Linter
To check compliance with bloc_lint rules:
```bash
# Install bloc_tools globally (with FVM if applicable)
fvm dart pub global activate bloc_tools

# Run the linter
bloc lint .
```

## Common Mistakes to Avoid

### ❌ Don't: Use context.read() for dependency injection
```dart
// ❌ BAD - Don't use context.read()
class UserScreen extends StatelessWidget {
  const UserScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserCubit(
        userRepository: context.read<UserRepository>(), // ❌ Wrong!
      ),
      child: const UserView(),
    );
  }
}
```

### ✅ Do: Use service locator (context.repository.xxx)
```dart
// ✅ GOOD - Use service locator
class UserScreen extends StatelessWidget {
  const UserScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserCubit(
        userRepository: context.repository.user, // ✅ Correct!
      ),
      child: const UserView(),
    );
  }
}
```

### ❌ Don't: Use getIt directly in Cubit
```dart
// ❌ BAD - Direct getIt usage in Cubit
class UserCubit extends Cubit<UserState> {
  UserCubit() : super(const UserInitial());
  
  final _userRepository = getIt<UserRepository>(); // ❌ Wrong!
}
```

### ✅ Do: Inject dependencies through constructor
```dart
// ✅ GOOD - Constructor injection
class UserCubit extends Cubit<UserState> with CubitMixin<UserState> {
  UserCubit({
    required UserRepository userRepository,
  }) : _userRepository = userRepository,
       super(const UserInitial());
  
  final UserRepository _userRepository;
}
```

### ❌ Don't: Use positional parameters
```dart
// ❌ BAD - Positional parameters
class FeatureCubit extends Cubit<FeatureState> {
  FeatureCubit(this._repository) : super(const FeatureInitial());
  final FeatureRepository _repository;
}
```

### ✅ Do: Use named parameters
```dart
// ✅ GOOD - Named parameters
class FeatureCubit extends Cubit<FeatureState> {
  FeatureCubit({
    required FeatureRepository repository,
  }) : _repository = repository,
       super(const FeatureInitial());
  
  final FeatureRepository _repository;
}
```

### ❌ Don't: Use public mock classes
```dart
// ❌ BAD - Public mock class
class MockUserRepository extends Mock implements UserRepository {} // ❌ Wrong!

void main() {
  late MockUserRepository mockRepository;
  // ...
}
```

### ✅ Do: Use private mock classes
```dart
// ✅ GOOD - Private mock class
class _MockUserRepository extends Mock implements UserRepository {} // ✅ Correct!

void main() {
  late _MockUserRepository mockRepository;
  // ...
}
```

### ❌ Don't: Use mutable state properties
```dart
// ❌ BAD - Mutable state property
class FeatureLoaded extends FeatureState {
  FeatureLoaded({required this.features});
  List<Feature> features; // Not final
}
```

### ✅ Do: Make state properties final and immutable
```dart
// ✅ GOOD - Final and immutable
class FeatureLoaded extends FeatureState {
  const FeatureLoaded({required this.features});
  final List<Feature> features;
}
```

### ❌ Don't: Use abstract class for states
```dart
// ❌ BAD - Abstract class
abstract class FeatureState extends Equatable {}
```

### ✅ Do: Use sealed class for states
```dart
// ✅ GOOD - Sealed class
sealed class FeatureState extends Equatable {}
```

### ❌ Don't: Use emit after async gap without checking if closed
```dart
// ❌ BAD - Using emit directly
Future<void> loadFeature() async {
  emit(const FeatureLoading());
  final features = await _repository.getFeatures();
  emit(FeatureLoaded(features: features)); // May throw if cubit is closed
}
```

### ✅ Do: Use safeEmit with CubitMixin
```dart
// ✅ GOOD - Using safeEmit with CubitMixin
class FeatureCubit extends Cubit<FeatureState> with CubitMixin<FeatureState> {
  Future<void> loadFeature() async {
    safeEmit(const FeatureLoading());
    final features = await _repository.getFeatures();
    safeEmit(FeatureLoaded(features: features));
  }
}
```

