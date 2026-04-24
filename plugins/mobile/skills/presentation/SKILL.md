---
name: presentation
description: "Presentation layer structure for screens, cubits, routes, and views in screens/. Use when adding or modifying Flutter screens, cubits, routes, barrel files, or feature presentation code."
---

## Related Guidelines

- `@dart` - Dart language best practices, naming, modern features
- `@flutter` - Widget architecture, composition, performance
- `@state` - BLoC/Cubit patterns, freezed state, DI annotations
- `@clean` - Layer separation, dependency rules
- `@di` - sl, injectable, BlocProvider wiring

## File Organization

### Screen Structure (Main App)

#### Standard Feature Structure

All features follow a consistent directory structure with barrel files for clean imports:

```
screens/[feature_name]/
├── [feature_name].dart           # Barrel file - exports all public APIs
├── cubit/                        # State management (see @state)
│   ├── cubit.dart                # Barrel — exports cubits and states
│   ├── [feature]_cubit.dart      # Main Cubit for feature
│   └── [feature]_state.dart      # State definitions
├── view/                         # Screen implementations
│   ├── view.dart                 # Barrel file - exports all views
│   ├── [feature]_screen.dart     # Main screen widget
│   └── [component]_view.dart     # Sub-views/components
├── model/                        # Feature-specific data models (optional)
│   ├── model.dart                # Barrel file - exports all models
│   └── [model_name].dart         # Data models, helpers, enums
├── mixin/                        # Shared behavior (optional)
│   ├── mixin.dart                # Barrel file - exports mixins
│   └── [mixin_name].dart         # Mixin implementations
└── helpers/                      # Utility functions (optional)
    ├── helpers.dart              # Barrel file - exports helpers
    └── [helper_name].dart        # Helper functions
```

#### Nested Sub-Features

Complex features may contain sub-features, each following the same structure:

```
screens/[feature_name]/
├── [feature_name].dart           # Exports sub-features and main feature
├── [sub_feature_1]/              # Sub-feature follows same structure
│   ├── [sub_feature_1].dart      # Barrel file
│   ├── cubit/
│   │   ├── cubit.dart
│   │   ├── [name]_cubit.dart
│   │   └── [name]_state.dart
│   ├── view/
│   │   ├── view.dart
│   │   └── [name]_screen.dart
│   └── model/
│       ├── model.dart
│       └── [model].dart
├── [sub_feature_2]/              # Another sub-feature
│   └── ... (same structure)
├── cubit/                        # Parent feature's state
├── view/                         # Parent feature's views
└── model/                        # Parent feature's models
```

**Example: Billing Feature**
```
screens/billing/
├── billing.dart                  # export 'billing_detail/billing_detail.dart';
├── billing_detail/               # Sub-feature
│   ├── billing_detail.dart       # export 'model/model.dart' show BillingDetailData;
│   ├── cubit/
│   │   ├── billing_detail_cubit.dart
│   │   └── billing_detail_state.dart
│   ├── view/
│   │   ├── view.dart             # export 'billing_detail_screen.dart';
│   │   └── billing_detail_screen.dart
│   └── model/
│       ├── model.dart            # export 'billing_detail_data.dart';
│       └── billing_detail_data.dart
├── cubit/                        # Parent billing state
│   ├── billing_cubit.dart
│   └── billing_state.dart
├── view/
│   ├── view.dart
│   ├── billing_screen.dart
│   └── invoice_item.dart
└── model/
    ├── model.dart
    └── invoice_status_helper.dart
```

#### Multiple Cubits in Feature

Features may have multiple Cubits for different concerns:

```
screens/[feature_name]/
├── cubit/
│   ├── cubit.dart                    # Barrel — exports all cubits and states
│   ├── [feature]_cubit.dart          # Main feature logic
│   ├── [feature]_state.dart
│   ├── [sub_concern]_cubit.dart      # Specific concern (e.g., avatar, filter)
│   ├── [sub_concern]_state.dart
│   ├── [another]_cubit.dart          # Another concern
│   └── [another]_state.dart
└── ...
```

**Example: Account Detail with Multiple Cubits**
```
screens/account_detail/
├── cubit/
│   ├── cubit.dart                    # Barrel — exports all cubits and states
│   ├── account_detail_cubit.dart     # Main account data
│   ├── account_detail_state.dart
│   ├── account_avatar_cubit.dart     # Avatar upload logic
│   └── account_avatar_state.dart
└── ...
```

#### View Directory

- **`view/`**: Screen implementations, full-page views, or major screen sections
  - Contains `[feature]_screen.dart` (the main screen)
  - Contains `[component]_view.dart` for major screen sections
  - Exported via `view.dart` barrel file
  - Typically integrates with BLoC/Cubit

```
screens/assignments/
└── view/
    ├── view.dart
    ├── assignments_tab.dart          # Main screen
    ├── assignment_list.dart          # Major section view
    └── assignment_item.dart          # List item view
```

#### Barrel File Pattern

**CRITICAL**: Every directory MUST have a barrel file. Only export symbols used outside that directory.

- **DO** create `[directory_name].dart` at each directory level
- **DO** only export files consumed by code outside the current folder
- **DO** use `show` keyword to restrict re-exports to specific symbols
- **DON'T** export internal implementation details (forms, helpers, sub-components used only within the folder)

```dart
// GOOD - screens/billing/cubit/cubit.dart
// State is read by view/ outside this folder — export both
export 'billing_cubit.dart';
export 'billing_state.dart';

// GOOD - screens/billing/view/view.dart
// Screen used by route — export it; invoice_item used by parent feature — export it
export 'billing_screen.dart';
export 'invoice_item.dart';

// BAD - screens/login/view/view.dart
export 'login_screen.dart';
export 'login_form.dart';               // only used inside login_screen — do not export
export 'login_header.dart';             // only used inside login_screen — do not export

// GOOD - screens/billing/model/model.dart
// Only export models referenced outside this folder
export 'billing_detail_data.dart';
// invoice_status_helper.dart used only inside model/ — not exported

// GOOD - screens/billing/billing_detail/billing_detail.dart
export 'model/model.dart' show BillingDetailData;  // only the type needed by callers

// BAD - No barrel file
// Forces consumers to know internal structure:
// import '../../screens/billing/cubit/billing_cubit.dart';
// import '../../screens/billing/view/billing_screen.dart';

// GOOD - With barrel files, clean imports:
// import 'package:app/screens/[feature]/[feature].dart';
```

#### Route Configuration

Routes use `AppPageRoute` from `components/route/`:

```dart
// screens/[feature]/[feature]_route.dart
import 'package:app/components/route/route.dart';

class FeatureRoute extends AppPageRoute<FeatureData, FeatureResult> {
  FeatureRoute({
    required FeatureData data,
  }) : super(
          path: '/feature-name',
          builder: (context) => BlocProvider(
            create: (_) => sl<FeatureCubit>(),
            child: const FeatureScreen(),
          ),
          data: data,
        );
}
```

Access route input data inside the screen via `context.arguments<FeatureData>()`.

See [`reference/navigation.md`](reference/navigation.md) for full navigation API — push methods, pop variants, `RouteData`, and `AppRouteObserver`.

#### Complete Real-World Examples

**Simple Feature (Login)**
```
screens/login/
├── login.dart                    # Barrel: exports all public APIs
├── cubit/
│   ├── login_cubit.dart
│   └── login_state.dart
├── view/
│   ├── view.dart                 # export 'login_screen.dart'; (form/header internal — not exported)
│   ├── login_screen.dart
│   ├── login_form.dart
│   └── login_header.dart
├── model/
│   ├── model.dart                # export 'login_type.dart';
│   ├── login_type.dart           # enum LoginType
│   └── login_validators.dart
└── otp_verification/             # Sub-feature
    ├── otp_verification.dart
    ├── cubit/...
    └── view/...
```

**Complex Feature (Home with Tabs)**
```
screens/home/
├── home.dart                     # Barrel: exports tabs
├── cubit/
│   ├── home_cubit.dart
│   ├── home_state.dart
│   ├── navigation_cubit.dart     # Tab navigation
│   └── navigation_state.dart
├── view/
│   ├── view.dart
│   └── home_screen.dart
├── tabs/                         # Nested features for each tab
│   ├── dashboard/
│   │   ├── dashboard.dart
│   │   ├── cubit/...
│   │   ├── view/...
│   │   └── model/...
│   ├── my_learning/
│   │   ├── my_learning.dart
│   │   ├── cubit/...
│   │   ├── view/...
│   │   └── course/              # Nested sub-feature
│   │       ├── course.dart
│   │       ├── cubit/...
│   │       ├── view/...
│   │       └── lesson_detail/   # Deep nesting
│   │           └── ...
│   ├── assignments/
│   │   └── ...
│   └── schedule/
│       └── ...
└── mixin/
    ├── mixin.dart
    └── home_navigation_mixin.dart
```

#### Directory Guidelines

- **REQUIRED directories**: `cubit/`, `view/`
- **OPTIONAL directories**: `model/`, `mixin/`, `helpers/`
- **ALWAYS** include barrel files in each directory
- **ORGANIZE** sub-features as nested directories with full structure
- **USE** consistent naming: `[feature]_screen.dart`, `[feature]_cubit.dart`, etc.

## Implementation Rules

### Cubit & State

- Annotate cubit with `@injectable` (feature) or `@singleton` (app-wide) — required for DI wiring
- Extend `Cubit<State>` with `CubitMixin<State>`; use `safeEmit` (from `core/state_management`)
- State: `@freezed sealed class` with union factories (`initial`, `loading`, `success`, `error`)
- Inject only repositories and use cases via constructor
- No business logic in widgets; no direct repo calls from UI
- Use `FormStatus` for forms; `DataLoadStatus` from `core/state-management/` for data loading

```dart
// feature_state.dart
import 'package:app/core/state-management/state_management.dart';

@freezed
class FeatureState with _$FeatureState {
  const factory FeatureState({
    @Default(DataLoadStatus.initial) DataLoadStatus status,
    FeatureData? data,
    String? errorMessage,
  }) = _FeatureState;
}

// feature_cubit.dart
@injectable
class FeatureCubit extends Cubit<FeatureState> with CubitMixin<FeatureState> {
  FeatureCubit({required FeatureRepository repository})
      : _repository = repository,
        super(const FeatureState());

  final FeatureRepository _repository;

  Future<void> load() async {
    safeEmit(state.copyWith(status: DataLoadStatus.loading));
    try {
      final data = await _repository.getFeature();
      safeEmit(state.copyWith(status: DataLoadStatus.success, data: data));
    } catch (e) {
      safeEmit(state.copyWith(status: DataLoadStatus.failure, errorMessage: e.toString()));
    }
  }
}
```

### Views (Screens)

- Prefer `StatelessWidget`; `StatefulWidget` only for local UI state
- Widget classes for UI components — not build methods (see `@flutter`)
- `BlocProvider` to create cubit; `BlocBuilder`/`BlocListener` to react to state
- Design system from `vle_ui` (VleColors, VleDimens, VleTextStyles, VleButton, etc.)
- Use `LocalizationKeys.*.tr()` for all user-visible strings
- `const` constructors everywhere; files under ~200 lines

### Routes

- Extend `AppPageRoute<Data, Result>` — `Data extends RouteData?`, `Result` is the return type
- Pass required `path` (sets `RouteSettings.name` automatically) and `builder`
- Provide cubit via `BlocProvider` inside `builder`
- Access route input data in screen via `context.arguments<Data>()`
- Use `isUsingRootNavigator: true` for routes that must overlay tabs/bottom nav
- Use `enableTransition: false` to suppress forward animation (back animation preserved)

```dart
class FeatureRoute extends AppPageRoute<FeatureData, FeatureResult> {
  FeatureRoute({required FeatureData data})
      : super(
          path: '/feature-name',
          builder: (_) => BlocProvider(
            create: (_) => sl<FeatureCubit>(),
            child: const FeatureScreen(),
          ),
          data: data,
        );
}
```

### Dependency Injection

- Resolve cubit via `sl<FeatureCubit>()` inside `BlocProvider.create`
- Never use `context.read<T>()` for repositories/use cases
- Cubit's own deps wired by injectable — do not pass them manually through the route

```dart
// CORRECT
BlocProvider(create: (_) => sl<FeatureCubit>())

// BAD
BlocProvider(create: (_) => FeatureCubit(repository: sl<FeatureRepository>()))
```

### Naming

| Artifact | File | Class |
|----------|------|-------|
| Cubit | `feature_cubit.dart` | `FeatureCubit` |
| State | `feature_state.dart` | `FeatureState` |
| Screen | `feature_screen.dart` | `FeatureScreen` |
| Route | `feature_route.dart` | `FeatureRoute` |

Files: `snake_case.dart`. Classes: `PascalCase`.

## NEVER

- Put business logic in widgets or screens
- Call repositories/use cases directly from UI — go through cubit
- Use `context.read<T>()` for dependency resolution
- Hardcode strings — use `LocalizationKeys.*.tr()`
- Create widget build methods instead of widget classes
