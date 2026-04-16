# Layer Responsibilities

## Contents
- [Presentation Layer](#1-presentation-layer-lib)
- [Domain Layer — Use Cases](#2-domain-layer--use-cases)
- [Domain Layer — Entities](#3-domain-layer--entities-packagesentity)
- [Data Layer — Repositories](#4-data-layer--repositories-packagesdomain)
- [Data Layer — Data Package](#5-data-layer--data-package-packagesdata)

---

## 1. Presentation Layer (`lib/`)

**Location**: `lib/screens/`, `lib/widgets/`, `lib/components/`

Display data, handle user interactions, manage UI state via BLoC/Cubit. No business logic, no direct repo calls.

**Full implementation guide**: See `@presentation` (file structure, barrel files, routes, views vs widgets) and `@state` (Cubit pattern, `@freezed` states, `DataLoadStatus`, BlocBuilder/BlocListener).

---

## 2. Domain Layer — Use Cases (`lib/use_case/`)

Single-responsibility business operations. Coordinate repositories, no UI deps, no direct API/service calls.

**Full implementation guide**: See `@domain` (interface + impl pattern, `call()` convention, DI annotations, exception handling).

---

## 3. Domain Layer — Entities (`packages/entity/`)

Pure Dart domain models. Immutable, no layer dependencies, use `@JsonSerializable()` for serialization.

**Structure:**
```
packages/entity/lib/src/[domain]/
├── entity.dart          # Barrel file
├── [entity_name].dart   # Domain entity
├── [enum_name].dart     # Domain enums
└── [type_name].dart     # Domain types
```

**Rules:**
- Immutable — use `@freezed` or `copyWith`
- Entity-level business logic only
- Export through `entity.dart` package
- No dependencies on other layers

---

## 4. Data Layer — Repositories (`packages/domain/`)

Abstract data access. Coordinate remote + local sources, translate `DataSourceException` to domain exceptions, map models to entities. No business logic.

**Full implementation guide**: See `@domain` (repository interface/impl pattern, exception translation, DI wiring, folder structure).

---

## 5. Data Layer — Data Package (`packages/data/`)

Remote (Retrofit API) and local (Hive/SharedPreferences/SecureStorage) data sources. Convert HTTP errors to `DataSourceException`. No business logic, no entity exposure — use models.

**Full implementation guide**: See `@data` (API layer, remote/local data source patterns, models, DI modules, network config, error handling).
