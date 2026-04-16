---
name: presentation
description: "Presentation layer structure for screens, cubits, routes, and views in lib/screens/. Use when adding or modifying Flutter screens, cubits, routes, barrel files, or feature presentation code."
---

## Related Guidelines

- `@flutter` - Widget architecture, composition, performance
- `@state` - BLoC/Cubit patterns, freezed state, DI annotations
- `@clean` - Layer separation, dependency rules
- `@di` - sl, injectable, BlocProvider wiring

## File Organization

### Screen Structure (Main App)

#### Standard Feature Structure

All features follow a consistent directory structure with barrel files for clean imports:

```
lib/screens/[feature_name]/
├── [feature_name].dart           # Barrel file - exports all public APIs
├── cubit/                        # State management (see @state)
│   ├── cubit.dart                # Barrel — exports cubits and states
│   ├── [feature]_cubit.dart      # Main Cubit for feature
│   └── [feature]_state.dart      # State definitions
├── views/                        # Screen implementations
│   ├── views.dart                # Barrel file - exports all views
│   ├── [feature]_screen.dart     # Main screen widget
│   └── [component]_view.dart     # Sub-views/components
├── route/                        # Navigation configuration
│   ├── route.dart                # Barrel file - exports routes
│   └── [feature]_route.dart      # Route definitions (using AppPageRoute)
├── models/                       # Feature-specific data models (optional)
│   ├── models.dart               # Barrel file - exports all models
│   └── [model_name].dart         # Data models, helpers, enums
├── widgets/                      # Reusable feature widgets (optional)
│   ├── widgets.dart              # Barrel file - exports widgets
│   └── [widget_name].dart        # Widget classes
├── mixins/                       # Shared behavior (optional)
│   ├── mixins.dart               # Barrel file - exports mixins
│   └── [mixin_name].dart         # Mixin implementations
└── helpers/                      # Utility functions (optional)
    ├── helpers.dart              # Barrel file - exports helpers
    └── [helper_name].dart        # Helper functions
```

#### Nested Sub-Features

Complex features may contain sub-features, each following the same structure:

```
lib/screens/[feature_name]/
├── [feature_name].dart           # Exports sub-features and main feature
├── [sub_feature_1]/              # Sub-feature follows same structure
│   ├── [sub_feature_1].dart      # Barrel file
│   ├── cubit/
│   │   ├── cubit.dart
│   │   ├── [name]_cubit.dart
│   │   └── [name]_state.dart
│   ├── views/
│   │   ├── views.dart
│   │   └── [name]_screen.dart
│   ├── route/
│   │   ├── route.dart
│   │   └── [name]_route.dart
│   └── models/
│       ├── models.dart
│       └── [model].dart
├── [sub_feature_2]/              # Another sub-feature
│   └── ... (same structure)
├── cubit/                        # Parent feature's state
├── views/                        # Parent feature's views
├── route/                        # Parent feature's routes
└── models/                       # Parent feature's models
```

**Example: Billing Feature**
```
lib/screens/billing/
├── billing.dart                  # export 'billing_detail/billing_detail.dart';
│                                 # export 'route/route.dart';
├── billing_detail/               # Sub-feature
│   ├── billing_detail.dart       # export 'models/models.dart' show BillingDetailData;
│   │                             # export 'route/route.dart';
│   ├── cubit/
│   │   ├── billing_detail_cubit.dart
│   │   └── billing_detail_state.dart
│   ├── views/
│   │   ├── views.dart            # export 'billing_detail_screen.dart';
│   │   └── billing_detail_screen.dart
│   ├── route/
│   │   ├── route.dart            # export 'billing_detail_route.dart';
│   │   └── billing_detail_route.dart
│   └── models/
│       ├── models.dart           # export 'billing_detail_data.dart';
│       └── billing_detail_data.dart
├── cubit/                        # Parent billing state
│   ├── billing_cubit.dart
│   └── billing_state.dart
├── views/
│   ├── views.dart
│   ├── billing_screen.dart
│   └── invoice_item.dart
├── route/
│   ├── route.dart
│   ├── billing_route.dart
│   └── billing_page_route.dart
└── models/
    ├── models.dart
    └── invoice_status_helper.dart
```

#### Multiple Cubits in Feature

Features may have multiple Cubits for different concerns:

```
lib/screens/[feature_name]/
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
lib/screens/account_detail/
├── cubit/
│   ├── account_detail_cubit.dart     # Main account data
│   ├── account_detail_state.dart
│   ├── account_avatar_cubit.dart     # Avatar upload logic
│   └── account_avatar_state.dart
└── ...
```

#### Views vs Widgets

- **`views/`**: Screen implementations, full-page views, or major screen sections
  - Contains `[feature]_screen.dart` (the main screen)
  - Contains `[component]_view.dart` for major screen sections
  - Exported via `views.dart` barrel file
  - Typically integrates with BLoC/Cubit

- **`widgets/`**: Reusable UI components specific to the feature
  - Contains widget classes that can be used across multiple views
  - May have nested organization for complex widgets
  - Exported via `widgets.dart` barrel file
  - Usually presentational (no direct state management)

```
lib/screens/assignments/
├── views/
│   ├── views.dart
│   ├── assignments_tab.dart          # Main screen
│   ├── assignment_list.dart          # Major section view
│   └── assignment_item.dart          # List item view
└── widgets/
    ├── widgets.dart
    └── assignment_buttons/           # Nested widget organization
        ├── submit_button.dart
        ├── save_draft_button.dart
        └── cancel_button.dart
```

#### Barrel File Pattern

**CRITICAL**: Every directory MUST have a barrel file that exports its public APIs.

- **DO** create `[directory_name].dart` at each directory level
- **DO** selectively export only public APIs
- **DO** use `show` keyword to control what's re-exported
- **DON'T** export internal implementation details

```dart
// ✅ GOOD - lib/screens/billing/billing.dart
export 'billing_detail/billing_detail.dart';  // Export sub-feature
export 'route/route.dart';                    // Export routes

// ✅ GOOD - lib/screens/billing/billing_detail/billing_detail.dart
export 'models/models.dart' show BillingDetailData;  // Selective export
export 'route/route.dart';

// ✅ GOOD - lib/screens/billing/cubit/cubit.dart
export 'billing_cubit.dart';
export 'billing_state.dart';

// ✅ GOOD - lib/screens/billing/views/views.dart
export 'billing_screen.dart';
export 'invoice_item.dart';

// ✅ GOOD - lib/screens/billing/models/models.dart
export 'billing_detail_data.dart';
export 'invoice_status_helper.dart';

// ❌ BAD - No barrel file
// Forces consumers to know internal structure:
// import '../../screens/billing/cubit/billing_cubit.dart';
// import '../../screens/billing/views/billing_screen.dart';

// ✅ GOOD - With barrel files, clean imports:
// import 'package:app/screens/[feature]/[feature].dart';
```

#### Route Configuration

Routes use `AppPageRoute` from `lib/components/route/`:

```dart
// lib/screens/[feature]/route/[feature]_route.dart
import 'package:app/components/route/app_page_route.dart';

class FeatureRoute extends AppPageRoute<FeatureData, FeatureResult> {
  FeatureRoute({
    required FeatureData data,
  }) : super(
          builder: (context) => BlocProvider(
            create: (_) => sl<FeatureCubit>(),
            child: const FeatureScreen(),
          ),
          data: data,
        );
}

// route/route.dart - Barrel file
export 'feature_route.dart';
```

#### Complete Real-World Examples

**Simple Feature (Login)**
```
lib/screens/login/
├── login.dart                    # Barrel: exports route
├── cubit/
│   ├── login_cubit.dart
│   └── login_state.dart
├── views/
│   ├── views.dart                # export 'login_screen.dart';
│   ├── login_screen.dart
│   ├── login_form.dart
│   └── login_header.dart
├── route/
│   ├── route.dart                # export 'login_route.dart';
│   └── login_route.dart
├── models/
│   ├── models.dart               # export 'login_type.dart';
│   ├── login_type.dart           # enum LoginType
│   └── login_validators.dart
└── otp_verification/             # Sub-feature
    ├── otp_verification.dart
    ├── cubit/...
    ├── views/...
    └── route/...
```

**Complex Feature (Home with Tabs)**
```
lib/screens/home/
├── home.dart                     # Barrel: exports tabs, route
├── cubit/
│   ├── home_cubit.dart
│   ├── home_state.dart
│   ├── navigation_cubit.dart     # Tab navigation
│   └── navigation_state.dart
├── view/
│   ├── view.dart
│   └── home_screen.dart
├── route/
│   ├── route.dart
│   └── home_route.dart
├── tabs/                         # Nested features for each tab
│   ├── dashboard/
│   │   ├── dashboard.dart
│   │   ├── cubit/...
│   │   ├── view/...
│   │   └── model/...
│   ├── my_learning/
│   │   ├── my_learning.dart
│   │   ├── cubit/...
│   │   ├── views/...
│   │   ├── route/...
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
├── mixins/
│   ├── mixins.dart
│   └── home_navigation_mixin.dart
└── widgets/
    ├── widgets.dart
    └── tab_bar_widget.dart
```

#### Directory Guidelines

- **REQUIRED directories**: `cubit/`, `views/`, `route/`
- **OPTIONAL directories**: `models/`, `widgets/`, `mixins/`, `helpers/`
- **ALWAYS** include barrel files in each directory
- **ORGANIZE** sub-features as nested directories with full structure
- **USE** consistent naming: `[feature]_screen.dart`, `[feature]_cubit.dart`, etc.
- **SEPARATE** views from widgets: views are screens, widgets are reusable components

## Implementation Rules

### Cubit & State

- Annotate cubit with `@injectable` (feature) or `@singleton` (app-wide) — required for DI wiring
- Extend `Cubit<State>` with `CubitMixin<State>`; use `safeEmit` (from `core/state_management`)
- State: `@freezed sealed class` with union factories (`initial`, `loading`, `success`, `error`)
- Inject only repositories and use cases via constructor
- No business logic in widgets; no direct repo calls from UI
- Use `FormStatus` for forms; `DataLoadStatus` from `lib/core/state-management/` for data loading

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
- Design system from `packages/vle_ui` (VleColors, VleDimens, VleTextStyles, VleButton, etc.)
- Use `LocalizationKeys.*.tr()` for all user-visible strings
- `const` constructors everywhere; files under ~200 lines

### Routes

- Extend `AppPageRoute`; implement `buildPage`
- `RouteSettings(name: '/feature-name')`
- Build screen widget in `buildPage`; provide cubit via `BlocProvider`

```dart
class FeatureRoute extends AppPageRoute<FeatureData, FeatureResult> {
  FeatureRoute({required FeatureData data})
      : super(
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
// ✅ CORRECT
BlocProvider(create: (_) => sl<FeatureCubit>())

// ❌ WRONG
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
