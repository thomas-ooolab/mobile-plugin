---
name: clean-architecture
description: "Clean Architecture guidelines covering layer separation, dependency rules, repositories, services, use cases, and data flow patterns"
---

# LearningOS Clean Architecture Guidelines

## Architecture Overview

This project follows **Clean Architecture** principles with a modular monorepo structure. The architecture is organized into distinct layers with clear separation of concerns and unidirectional dependency flow.

### Layer Structure

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  (lib/screens/, lib/widgets/, lib/components/)              │
│  - UI Components (Screens, Widgets)                         │
│  - State Management (Cubits/Blocs)                          │
│  - Routes                                                   │
└─────────────────────────────────────────────────────────────┘
                            ↓ depends on
┌─────────────────────────────────────────────────────────────┐
│                      Domain Layer                           │
│  (lib/use_case/, packages/entity/)                          │
│  - Use Cases (Business Logic)                               │
│  - Domain Entities                                          │
└─────────────────────────────────────────────────────────────┘
                            ↓ depends on
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                            │
│  (packages/domain/, packages/data/)                          │
│  - Repositories (Data Access Interfaces)                    │
│  - Remote Sources (API Services)                            │
│  - Local Sources (Persistence)                              │
│  - API (Remote Data Source)                                 │
└─────────────────────────────────────────────────────────────┘
```

## Layer Responsibilities

### 1. Presentation Layer (`lib/`)

**Location**: `lib/screens/`, `lib/widgets/`, `lib/components/`

**Responsibilities**:
- Display data to users
- Handle user interactions
- Manage UI state using BLoC/Cubit
- Navigate between screens
- NO business logic (delegate to use cases)
- NO direct repository calls (use through cubits and use cases)

**Structure**:
```
lib/screens/[feature_name]/
├── cubit/
│   ├── [feature]_cubit.dart      # State management logic
│   └── [feature]_state.dart      # State definitions
├── models/                        # View models (presentation layer only)
│   └── [model_name].dart
├── route/
│   └── [feature]_route.dart      # Navigation routes
├── views/
│   └── [feature]_screen.dart     # UI implementation
└── [feature].dart                # Barrel file
```

**Guidelines**:
- Screens should be stateless widgets when possible
- Cubits should extend `Cubit<State>` and use `CubitMixin` for safe emissions
- Always inject dependencies through constructor (repositories, use cases)
- Use `BlocProvider` to instantiate cubits at screen level
- Access dependencies via `context.repository`, `context.useCase`, etc.
- Cubits should call use cases or repositories, never services directly
- Handle UI state transitions using `FormStatus` and `DataLoadStatus`

**Example Cubit**:
```dart
class LoginCubit extends Cubit<LoginState> with CubitMixin<LoginState> {
  LoginCubit({
    required AuthenticationRepository authenticationRepository,
    required UserRepository userRepository,
    required DetermineAccountUseCase determineAccountUseCase,
  }) : _authenticationRepository = authenticationRepository,
       _userRepository = userRepository,
       _determineAccountUseCase = determineAccountUseCase,
       super(LoginState());

  final AuthenticationRepository _authenticationRepository;
  final UserRepository _userRepository;
  final DetermineAccountUseCase _determineAccountUseCase;

  Future<void> login() async {
    safeEmit(state.copyWith(status: FormStatus.submitting));
    try {
      await _authenticationRepository.login(
        email: state.email,
        password: state.password,
      );
      await _determineAccountUseCase();
      safeEmit(state.copyWith(status: FormStatus.success));
    } catch (e) {
      safeEmit(state.copyWith(
        status: FormStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
```

### 2. Domain Layer

#### Use Cases (`lib/use_case/`)

**Responsibilities**:
- Contain business logic and orchestration
- Coordinate between multiple repositories
- Single responsibility (one use case = one business operation)
- Platform-independent business rules
- NO UI dependencies
- NO direct service calls

**Structure**:
```
lib/use_case/[domain]/[feature]/
├── [use_case_name]_uc.dart       # Abstract interface
├── [use_case_name]_uc_impl.dart  # Implementation
└── [feature].dart                 # Barrel file
```

**Guidelines**:
- Define abstract interface with `call()` method
- Use `@Injectable(as: Interface)` for dependency injection
- Inject only repositories (never services or APIs)
- Keep use cases focused and composable
- Handle complex business logic and validations
- Coordinate multiple repository calls when needed

**Example Use Case**:
```dart
/// Abstract interface
abstract interface class DetermineAccountUseCase {
  Future<void> call();
}

/// Implementation
@Injectable(as: DetermineAccountUseCase)
final class DetermineAccountUseCaseImpl implements DetermineAccountUseCase {
  const DetermineAccountUseCaseImpl({
    required UserRepository userRepository,
    required SynchronizeInformationUseCase synchronizeInformationUseCase,
  }) : _userRepository = userRepository,
       _synchronizeInformationUseCase = synchronizeInformationUseCase;

  final UserRepository _userRepository;
  final SynchronizeInformationUseCase _synchronizeInformationUseCase;

  @override
  Future<void> call() async {
    final user = await _userRepository.getInformation();
    if (user.children.isNotEmpty) {
      await _userRepository.setMultipleUsersFlag(value: true);
      await _userRepository.removeCachedUser();
      return;
    }
    await _synchronizeInformationUseCase();
    await _userRepository.setMultipleUsersFlag(value: false);
  }
}
```

#### Entities (`packages/entity/`)

**Responsibilities**:
- Define domain models
- Pure Dart classes with business logic
- Immutable data structures
- NO dependencies on other layers
- Use with json_serializable for serialization

**Structure**:
```
packages/entity/lib/src/[domain]/
├── entity.dart                    # Barrel file
├── [entity_name].dart            # Domain entity
├── [enum_name].dart              # Domain enums
└── [type_name].dart              # Domain types
```

**Guidelines**:
- Keep entities immutable (use `@freezed` or `copyWith`)
- Define domain-specific types and enums
- Include entity-level business logic only
- Use `@JsonSerializable()` for JSON conversion
- Export through `entity.dart` package

### 3. Data Layer (`packages/`)

#### Repositories (`packages/domain/`)

**Responsibilities**:
- Abstract data access interface
- Coordinate between remote and local data sources
- Convert service exceptions to repository exceptions
- Handle data caching strategies
- Map service models to domain entities
- NO business logic

**Structure**:
```
packages/domain/lib/src/[domain]/
├── [domain]_repository.dart          # Abstract interface
├── [domain]_repository_impl.dart     # Implementation
├── [domain]_module.dart              # DI module
└── exception/
    └── exception.dart                 # Repository exceptions
```

**Guidelines**:
- Define abstract interface using `abstract interface class`
- Implementation uses `@Injectable(as: Interface)`
- Inject services (remote) and local sources from `packages/data`
- Convert `ServiceException` to domain-specific exceptions
- Document exceptions in interface method comments
- Keep repository focused on data access only

**Example Repository**:
```dart
/// Abstract interface
abstract interface class AuthenticationRepository {
  /// Login
  ///
  /// - Throws [LoginException] when logging in fails.
  /// - Throws [IncorrectCredentialException] when logging with incorrect credential.
  Future<void> login({required String email, required String password});
}

/// Implementation
@Injectable(as: AuthenticationRepository)
final class AuthenticationRepositoryImpl implements AuthenticationRepository {
  AuthenticationRepositoryImpl({
    required AuthenticationService authenticationService,
    required AuthenticationDatabaseService authenticationDatabaseService,
  }) : _authenticationService = authenticationService,
       _authenticationDatabaseService = authenticationDatabaseService;

  final AuthenticationService _authenticationService;
  final AuthenticationDatabaseService _authenticationDatabaseService;

  @override
  Future<void> login({required String email, required String password}) async {
    try {
      final tokens = await _authenticationService.login(
        email: email,
        password: password,
      );
      await _authenticationDatabaseService.save(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        tokenType: tokens.tokenType,
      );
    } on ServiceException catch (e) {
      if (e.error?.name == ErrorName.unauthorized) {
        throw IncorrectCredentialException('Incorrect credential error!');
      }
      throw LoginException(e.toString());
    }
  }
}
```

#### Data Package (`packages/data/`)

Unified data source package containing both remote (API) and local (persistence) sources.

**Responsibilities**:
- Handle remote API calls (remote source)
- Handle local data persistence (local source)
- Handle data transformations between API and domain
- Convert HTTP errors to ServiceExceptions
- Manage shared preferences, secure storage, Hive
- NO business logic
- NO direct entity exposure (use models)

**Structure**:
```
packages/data/lib/
├── data.dart                               # Barrel file (exports DataModule, local, remote)
└── src/
    ├── data_module.dart                    # Top-level DI module
    ├── remote/                             # Remote data sources
    │   ├── remote.dart                     # Remote barrel file
    │   ├── api/                            # Retrofit API definitions
    │   │   └── [domain]/
    │   │       └── [domain]_api.dart
    │   ├── service/
    │   │   └── [domain]/
    │   │       ├── [domain]_service.dart          # Abstract interface
    │   │       ├── [domain]_service_impl.dart     # Implementation
    │   │       ├── model/                          # Request/Response models
    │   │       │   └── [model_name].dart
    │   │       └── service.dart                    # Barrel file
    │   └── network/                        # Network configuration
    └── local/                              # Local data sources
        ├── local.dart                      # Local barrel file
        ├── local_dependency_register.dart  # Local DI registration
        ├── authentication/                 # Token persistence
        ├── user/                           # User preferences/cache
        ├── workspace/                      # Workspace cache
        ├── biometric/                      # Biometric settings
        └── model/                          # Local storage models
```

**Remote Source Guidelines**:
- Define service interface with `abstract interface class`
- Implementation injects only API classes
- All methods throw `ServiceException` on failure
- Convert API models to entities
- Use Retrofit for API definitions
- Handle HTTP errors and convert to ServiceException

**Example Service** (remote):
```dart
/// Abstract interface
abstract interface class AuthenticationService {
  /// Login
  ///
  /// Throws [ServiceException] if the api fails for some reason.
  Future<Tokens> login({required String email, required String password});
}

/// Implementation
final class AuthenticationServiceImpl implements AuthenticationService {
  AuthenticationServiceImpl(this._api);

  final AuthenticationApi _api;

  @override
  Future<Tokens> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _api.login(
        LoginRequestModel(email: email, password: password).toJson(),
      );
      return TokensModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServiceException.from(e);
    }
  }
}
```

**Local Source Guidelines**:
- Define database service interface
- Implement using Hive, SharedPreferences, or SecureStorage
- Keep models separate from domain entities
- Handle serialization/deserialization
- Throw exceptions on storage failures

**Example Local Source**:
```dart
abstract interface class AuthenticationDatabaseService {
  /// Save the tokens to local storage.
  ///
  /// Throws [Exception] if failure happened for any reason.
  Future<void> save({
    required String tokenType,
    required String accessToken,
    required String refreshToken,
  });

  /// Get the tokens from local storage.
  ///
  /// Return [Null] if failure happened for any reason.
  Future<Tokens?> get();

  /// Delete the tokens which were saved in local storage.
  ///
  /// Throws [Exception] if failure happened for any reason.
  Future<void> delete();
}
```

## Dependency Injection

**Tool**: GetIt with Injectable

**Setup**:
- Use `@Injectable(as: Interface)` for implementations
- Define modules in each package (`module.dart`)
- Register external modules in `lib/locator/locator.dart`
- Use constructor injection only

**Access Pattern**:
```dart
// In screens via BuildContext extension
context.repository.authentication
context.repository.user
context.useCase.determineAccount
context.deviceUtil

// In use cases/repositories via constructor
class MyUseCase {
  MyUseCase({required MyRepository repository});
}
```

## State Management

**Pattern**: BLoC (using Cubit)

**Guidelines**:
- Use Cubit for simpler state management (most cases)
- Use Bloc for complex event-driven scenarios
- Mix in `CubitMixin` for safe emissions
- Use `safeEmit` instead of `emit` to prevent closed cubit errors
- Define state as immutable class with `copyWith`
- Use `FormStatus` for form submissions
- Use `DataLoadStatus` for data loading states

**State Status Types**:
```dart
enum FormStatus { initial, submitting, success, failure }
enum DataLoadStatus { initial, loading, loaded, failure }
```

## Naming Conventions

### Files
- Screens: `[feature]_screen.dart`
- Cubits: `[feature]_cubit.dart`
- States: `[feature]_state.dart`
- Use Cases: `[action]_uc.dart` and `[action]_uc_impl.dart`
- Repositories: `[domain]_repository.dart` and `[domain]_repository_impl.dart`
- Services: `[domain]_service.dart` and `[domain]_service_impl.dart`
- Entities: `[entity_name].dart`
- Routes: `[feature]_route.dart`

### Classes
- Screens: `[Feature]Screen`
- Cubits: `[Feature]Cubit`
- States: `[Feature]State`
- Use Cases: `[Action][Domain]UseCase` / `[Action][Domain]UseCaseImpl`
- Repositories: `[Domain]Repository` / `[Domain]RepositoryImpl`
- Services: `[Domain]Service` / `[Domain]ServiceImpl`
- Entities: `[EntityName]`

### Variables
- Private fields: `_fieldName`
- Repository instances: `_[domain]Repository`
- Service instances: `_[domain]Service`
- Use case instances: `_[action][Domain]UseCase`

## Data Flow Example

```dart
// 1. User taps login button in UI
LoginScreen (Widget)
  ↓
// 2. Screen calls cubit method
LoginCubit.login()
  ↓
// 3. Cubit orchestrates through use case (optional) or repository
_authenticationRepository.login()
  ↓
// 4. Repository calls remote service and local source
AuthenticationRepositoryImpl
  ├→ _authenticationService.login()  // Remote API (packages/data/src/remote/)
  └→ _authenticationDatabaseService.save()  // Local storage (packages/data/src/local/)
  ↓
// 5. Service makes API call
AuthenticationServiceImpl
  └→ _api.login()  // Retrofit API call
  ↓
// 6. Data flows back up through layers
API Response → Service → Repository → Use Case → Cubit → UI
```

## Best Practices

### General
1. **Dependency Rule**: Dependencies always point inward (Data → Domain ← Presentation)
2. **Single Responsibility**: Each class/file has one clear purpose
3. **Interface Segregation**: Define interfaces at each layer boundary
4. **Dependency Inversion**: Depend on abstractions, not concretions
5. **Testability**: Each layer can be tested independently

### Package Dependencies
- `entity` package: NO dependencies on other packages
- `data` package: depends on `entity` only (contains both remote and local sources)
- `domain` package: depends on `entity`, `data`
- `lib/use_case`: depends on `domain` package
- `lib/screens`: depends on `domain`, `use_case`, `entity`

### Error Handling
- Services throw `ServiceException`
- Repositories throw domain-specific exceptions
- Use cases throw use-case-specific exceptions or propagate repository exceptions
- Cubits catch all exceptions and emit failure states

### Testing
- Test each layer independently
- Mock dependencies using abstract interfaces
- Use `mocktail` for mocking
- Aim for high coverage

## Common Patterns

### Creating New Feature
1. Define entity in `packages/entity/`
2. Create remote service in `packages/data/src/remote/service/`
3. Create local source in `packages/data/src/local/` (if persistence needed)
4. Create repository in `packages/domain/lib/src/<domain>/`
5. Create use case in `lib/use_case/` (if complex logic needed)
6. Create screen with cubit in `lib/screens/`
7. Register dependencies in modules

### Adding New Endpoint
1. Update Retrofit API definition in `packages/data/src/remote/api/`
2. Add service method in corresponding service under `packages/data/src/remote/service/`
3. Add repository method in corresponding repository
4. Use in cubit or create use case if orchestration needed

### Handling Authentication
- Always goes through `AuthenticationRepository`
- Tokens stored via `AuthenticationDatabaseService` (in `packages/data/src/local/`)
- Token refresh handled by network interceptor
- Use `context.repository.authentication` in cubits

## Package Structure

```
packages/
├── entity/                        # Domain entities (no dependencies)
├── data/                          # Unified data sources (remote + local)
│   ├── src/remote/                # API services, Retrofit, network
│   └── src/local/                 # Hive, SharedPreferences, SecureStorage
├── domain/                        # Repository interfaces & implementations
├── vle_ui/                       # Reusable UI components
└── shared_lint/                   # Shared lint rules
```

## Key Files

- `lib/locator/locator.dart` - Dependency injection configuration
- `lib/vle_application.dart` - App initialization and setup
- `lib/core/state_management/` - State management utilities
- `packages/data/lib/src/remote/network/` - Network configuration
- `packages/data/lib/src/local/` - Local persistence
- `packages/entity/` - All domain models

## Tools & Commands

**Note**: This project uses FVM (Flutter Version Management). Always prefix Flutter/Dart commands with `fvm`.

- **Create new package**: `fvm dart pub global run very_good_cli:very_good create dart_package [name]`
- **Generate code**: `fvm dart run build_runner build -d`
- **Run tests**: `fvm flutter test --coverage --branch-coverage --fail-fast -r failures-only --test-randomize-ordering-seed random`
- **Generate translations**: `fvm dart run melos generate-translation`
- **Run app**: `fvm flutter run --flavor development`

## References

- Clean Architecture: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- BLoC Library: https://bloclibrary.dev
- Project README: `/README.md`

