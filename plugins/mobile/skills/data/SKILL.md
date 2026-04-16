---
name: data
description: "Data package guidelines for Retrofit API, remote/local data sources, models, and DI in packages/data. Use when adding or modifying API endpoints, data sources, data models, or implementing the data layer."
---

## Related Guidelines

- `@clean` - Layer separation, dependency rules
- `@di` - get_it, injectable, micropackage setup

## Folder Structure

```
packages/data/lib/src/
├── di/
│   ├── di.dart                          # Barrel
│   ├── data_injection.dart              # @InjectableInit.microPackage()
│   └── data_injection.config.dart       # Generated
├── datasource/
│   ├── remote/
│   │   ├── remote.dart                      # Barrel — export interfaces only
│   │   ├── api/
│   │   │   ├── api.dart                     # Barrel — exports all feature barrels
│   │   │   └── <feature>/
│   │   │       ├── <feature>_api.dart       # Retrofit API
│   │   │       └── <feature>.dart           # Barrel
│   │   ├── datasource/
│   │   │   ├── datasource.dart              # Barrel — exports all feature barrels
│   │   │   └── <feature>/
│   │   │       ├── <feature>_remote_datasource.dart       # Interface
│   │   │       ├── <feature>_remote_datasource_impl.dart  # Implementation
│   │   │       ├── model/                                  # Request/Response DTOs
│   │   │       │   ├── <model_name>.dart
│   │   │       │   └── model.dart                          # Barrel
│   │   │       └── <feature>.dart                          # Barrel
│   │   └── network/                         # Dio, interceptors
│   └── local/
│       ├── local.dart                       # Barrel — export interfaces only
│       ├── datasource/
│       │   ├── datasource.dart              # Barrel — exports all feature barrels
│       │   └── <feature>/
│       │       ├── <feature>_local_datasource.dart       # Interface
│       │       ├── <feature>_local_datasource_impl.dart  # Implementation
│       │       └── <feature>.dart                         # Barrel
│       └── model/                           # Local storage models
└── repository/
    ├── repository.dart                  # Barrel — exports all domain barrels
    └── <domain>/
        ├── <domain>_repository_impl.dart   # Implementation
        └── <domain>.dart                   # Barrel
```

## Barrel Contents & Imports

```dart
// datasource/remote/remote.dart — interfaces only
export 'datasource/datasource.dart';

// datasource/remote/datasource/datasource.dart
export '<feature>/<feature>.dart';

// datasource/remote/datasource/<feature>/<feature>.dart
export '<feature>_remote_datasource.dart';  // interface only

// datasource/remote/api/api.dart
export '<feature>/<feature>.dart';

// datasource/remote/api/<feature>/<feature>.dart
export '<feature>_api.dart';

// repository/repository.dart
export '<domain>/<domain>.dart';

// repository/<domain>/<domain>.dart
export '<domain>_repository_impl.dart';
```

```dart
// Consume remote datasource interface:
import 'package:data/src/datasource/remote/remote.dart';

// Consume repository impl (internal DI only):
import 'package:data/src/repository/repository.dart';
```

## API Layer (`lib/src/datasource/remote/api/<feature>/`)

- Barrel: `<feature>.dart` — export `<feature>_api.dart`
- One Retrofit API per feature: `<feature>_api.dart`
- `abstract interface class FeatureApi` with `@RestApi()`
- Factory constructor: `factory FeatureApi(Dio dio) = _FeatureApi`
- Generated code: `part '../generated/<feature>/feature_api.g.dart';`
- Path constants: `const _path = '/feature';`
- Return `Future<HttpResponse<dynamic>>` for all methods
- Decorators: `@Body()`, `@Query()`, `@Path()`, `@Header()` as needed
- Doc comment: `/// Throws [DioException] if the api fails for some reason.`

```dart
@injectable
@RestApi()
abstract interface class FeatureApi {
  factory FeatureApi(Dio dio) = _FeatureApi;

  /// Throws [DioException] if the api fails for some reason.
  @GET(_path)
  Future<HttpResponse<dynamic>> getFeature(@Path('id') String id);
}
```

## Remote Data Source Layer (`lib/src/datasource/remote/datasource/<feature>/`)

**Interface** — return entity/domain types only; no Dio/Retrofit types:

```dart
abstract interface class FeatureRemoteDataSource {
  /// Throws [DataSourceException] if the api fails for some reason.
  Future<FeatureEntity> getFeature({required String id});
}
```

**Implementation** — inject API, call in try/catch, map, throw `DataSourceException.from(e)`:

```dart
@Injectable(as: FeatureRemoteDataSource)
final class FeatureRemoteDataSourceImpl implements FeatureRemoteDataSource {
  FeatureRemoteDataSourceImpl(this._api);

  final FeatureApi _api;

  @override
  Future<FeatureEntity> getFeature({required String id}) async {
    try {
      final response = await _api.getFeature(id);
      return FeatureModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw DataSourceException.from(e);
    }
  }
}
```

**Rules:**
- Never expose `DioException` or raw HTTP types
- All errors → `DataSourceException.from(e)`
- Map response to entity/model — no raw JSON upward

## Local Data Source Layer (`lib/src/datasource/local/datasource/<feature>/`)

**Interface:**

```dart
abstract interface class FeatureLocalDataSource {
  /// Throws [Exception] if storage fails.
  Future<void> save(FeatureEntity entity);

  /// Returns [null] if not found.
  Future<FeatureEntity?> get();

  /// Throws [Exception] if storage fails.
  Future<void> delete();
}
```

**Implementation** — use Hive, SharedPreferences, or SecureStorage:

```dart
@Injectable(as: FeatureLocalDataSource)
final class FeatureLocalDataSourceImpl implements FeatureLocalDataSource {
  FeatureLocalDataSourceImpl(this._box);

  final Box _box;

  @override
  Future<void> save(FeatureEntity entity) async => _box.put('key', entity.toJson());

  @override
  Future<FeatureEntity?> get() async {
    final data = _box.get('key');
    return data == null ? null : FeatureEntity.fromJson(data);
  }

  @override
  Future<void> delete() async => _box.delete('key');
}
```

**Rules:**
- Keep local models separate from domain entities
- Handle serialization/deserialization inside impl
- Throw `Exception` on storage failure — never swallow

## Models (`lib/src/datasource/remote/datasource/<feature>/model/`)

Request/response DTOs:

```dart
@JsonSerializable()
class FeatureModel {
  const FeatureModel({required this.id, required this.name});

  factory FeatureModel.fromJson(Map<String, dynamic> json) =>
      _$FeatureModelFromJson(json);

  final String id;
  final String name;

  Map<String, dynamic> toJson() => _$FeatureModelToJson(this);
}
```

**Rules:**
- `@JsonSerializable()` + `part 'feature_model.g.dart';`
- `fromJson` for responses, `toJson()` for requests
- Keep in data package — domain entities stay in `entity`

## Repository Layer (`lib/src/repository/<domain>/`)

Repository interfaces are defined in `packages/domain` — only implementations live here.

- `@Injectable(as: <Domain>Repository)` on `final class <Domain>RepositoryImpl`
- Inject only data source interfaces (remote/local) via named constructor params
- Catch `DataSourceException` → translate to domain exceptions (never leak upward)
- Coordinate remote + local for caching/persistence
- No business rules — data access only

```dart
@Injectable(as: AuthenticationRepository)
final class AuthenticationRepositoryImpl implements AuthenticationRepository {
  AuthenticationRepositoryImpl({
    required AuthenticationRemoteDataSource authenticationRemoteDataSource,
    required AuthenticationLocalDataSource authenticationLocalDataSource,
  })  : _authenticationRemoteDataSource = authenticationRemoteDataSource,
        _authenticationLocalDataSource = authenticationLocalDataSource;

  final AuthenticationRemoteDataSource _authenticationRemoteDataSource;
  final AuthenticationLocalDataSource _authenticationLocalDataSource;

  @override
  Future<void> login({required String email, required String password}) async {
    try {
      final tokens = await _authenticationRemoteDataSource.login(
        email: email,
        password: password,
      );
      await _authenticationLocalDataSource.save(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        tokenType: tokens.tokenType,
      );
    } on DataSourceException catch (e) {
      if (e.error?.name == ErrorName.unauthorized) {
        throw IncorrectCredentialException('Incorrect credential error');
      }
      throw LoginException(e.toString());
    }
  }
}
```

**Rules:**
- Barrel `<domain>.dart` exports impl only — interface stays in domain package

## Dependency Injection

Data package uses `@InjectableInit.microPackage()` — all `@Injectable`/`@injectable`/`@module` annotations auto-discovered.

## Network (`lib/src/remote/network/`)

- Shared Dio instance lives here
- Interceptors (auth token, retry, logging) added here — not in individual APIs
- Cross-cutting concerns only; feature-specific logic stays in data sources

## Error Handling

| Layer | Exception | Rule |
|-------|-----------|------|
| Remote data source | `DataSourceException.from(e)` | Wrap all caught errors |
| Local data source | `Exception` | Throw on storage failure |
| Domain (repo) | Domain exception | Catch `DataSourceException`, translate |

Never leak `DataSourceException` or `DioException` above the data package.

## NEVER

- Expose `DioException` or raw HTTP types from data source methods
- Put business logic in data sources — data access only
- Use domain entities directly as request/response models
- Leak `DataSourceException` into the domain layer
- Swallow exceptions silently
