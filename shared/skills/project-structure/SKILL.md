---
name: project-structure
description: "Complete project structure covering directory organization, package architecture, file organization, and naming conventions - consolidates project structure and package architecture guidance"
---

# LearningOS Project Structure

Comprehensive project structure and package architecture guide for the LearningOS Flutter application.


## Overview

LearningOS is a comprehensive educational platform built with Flutter, following **Clean Architecture** principles and utilizing a **monorepo** structure. The application supports multiple white-label configurations (tenants) across different environments with a modular, scalable architecture.

### Technology Stack
- **Framework**: Flutter 3.38.7 / Dart 3.10.7
- **Architecture**: Clean Architecture with BLoC pattern
- **State Management**: `flutter_bloc` 9.1.1
- **Dependency Injection**: `get_it` 9.2.0 with `injectable` 2.7.1+4
- **API Client**: Retrofit with Dio
- **Localization**: `easy_localization` 3.0.8 (English, Vietnamese, French)
- **Package Management**: Melos 7.3.0 (Monorepo)
- **Testing**: `mocktail` 1.0.4, `bloc_test` 10.0.0
- **Code Generation**: `build_runner`, `freezed`, `json_serializable`

## Related Guidelines

This document covers project structure and organization. For detailed implementation guidance, refer to:
- `@clean-architecture` - Layer separation, dependency rules, data flow
- `@flutter-coding-standards` - Widget architecture and Flutter patterns
- `@state-management` - BLoC/Cubit patterns
- `@dart-coding-standards` - Dart language best practices
- `@testing-guidelines` - Testing strategies

---

## Main Entry Points

### Application Bootstrap
- **`lib/main.dart`** - Application entry point, calls `initializeApp()`
- **`lib/vle_application.dart`** - Main application initialization, flavor setup, dependency injection, widget tree
- **`pubspec.yaml`** - Root project dependencies, Melos scripts, Flutter Gen configuration

### Key Initialization Flow
```
main.dart → initializeApp() → VLEApplication
  ├── Setup Dependency Injection (get_it + injectable)
  ├── Initialize Firebase (per flavor)
  ├── Setup Localization (easy_localization)
  ├── Initialize BLoC Observer
  └── Run MaterialApp with routing
```

---

## Core Architecture Layers

### 1. Presentation Layer (`lib/screens/`, `lib/widgets/`, `lib/components/`)

**Responsibility**: UI components, user interactions, state management

#### `lib/screens/` - Feature Screens (916 files)

Each feature follows a consistent structure:
```
feature_name/
├── feature_name.dart              # Barrel file (exports all)
├── cubit/                         # State management
│   ├── feature_cubit.dart
│   └── feature_state.dart
├── route/                         # Navigation
│   ├── feature_route.dart
│   └── route.dart
├── views/                         # UI components
│   ├── feature_screen.dart
│   └── views.dart
├── models/                        # UI-specific models
│   └── models.dart
└── widgets/                       # Feature-specific widgets
```

**Major Feature Modules**:
- **`home/`** (331 files) - Main dashboard, tabs (courses, schedule, profile, assignments, explore, rewards, reports, notifications)
- **`explore/`** - Course catalog, shopping cart, favorites, skill paths
- **`booking/`** - Session booking, instructor/course/lesson/learning group search, booking filters, confirmations
- **`login/`** & **`forgot_password/`** - Authentication flows, OTP verification
- **`notifications/`** - Push notification handling, notification details
- **`reports/`** - Custom course reports, session report details
- **`resources/`** - File management, preview (PDF, video, images, audio)
- **`rewards/`** - Gamification, coin history, reward redemption, reward details
- **`progress_center/`** - Course progress tracking, all progress courses
- **`instructors/`** - Instructor listings, details, filters
- **`billing/`** - Invoice management, billing details
- **`credit_accounts/`** - Credit/balance management, credit account details
- **`account_detail/`** - User profile management, avatar updates
- **`password/`** - Change password, reset password flows
- **`splash/`** - App initialization screen
- **`user_select/`** & **`workspaces/`** - Multi-user/workspace selection
- **`language_setting/`** - Language selection
- **`pin_code/`** & **`change_pin/`** - Security PIN features
- **`about/`** - About page
- **`unknown/`** - 404 error page

#### `lib/widgets/` - Reusable UI Components (55 files)
Global reusable widgets used across features:
- Common buttons, cards, dialogs
- Form inputs and validation widgets
- Loading and error states
- Custom navigation widgets

#### `lib/components/` - Complex Components (36 files)
Infrastructure-level components:

**Broadcast System** (`broadcast/`):
- `app_broadcast/` - Application-wide state coordination
- `notification_badge_broadcast/` - Real-time badge updates
- `assignment_broadcast/` - Assignment state changes
- `session_action_broadcast/` - Session state changes
- `explore_course_broadcast/` - Course exploration events
- `app_link_broadcast/` - Deep linking handling
- `app_loader/` - Global loading states

**Pagination** (`pagination/`):
- `mixins/pagination_cubit_mixin.dart` - BLoC pagination logic
- `mixins/pagination_view_mixin.dart` - UI pagination helpers
- `views/` - PaginationListView, PaginationGridView, Sliver variants
- `interfaces/` - Pagination and refresh interfaces

**Routing** (`route/`):
- `app_page_route.dart` - Custom page transitions
- `navigator.dart` - Navigation utilities
- `observer/` - Route lifecycle tracking
- `route_data.dart` & `route_result.dart` - Route data models

**WebView** (`webview_manager/`):
- In-app browser management

### 2. Domain Layer (`lib/use_case/`)

**Responsibility**: Business logic, use cases

Use cases encapsulate single business operations independent of UI:

**Structure**:
```
use_case/
├── use_case_provider.dart          # Injectable module
├── use_case_provider_impl.dart     # Implementation
├── analytics/                       # Analytics tracking
│   ├── set_user_props_uc.dart
│   └── set_user_props_uc_impl.dart
├── app/                            # App-level operations
│   ├── app_version_check/
│   │   ├── check_app_version_uc.dart
│   │   └── check_app_version_uc_impl.dart
│   └── in_app_review/
│       ├── check_inapp_review_uc.dart
│       └── check_inapp_review_uc_impl.dart
└── user/                           # User operations
    ├── update_user_info/
    │   ├── synchronize_device_token_uc.dart
    │   ├── synchronize_information_uc.dart
    │   └── implementations...
    ├── user_selection/
    │   ├── determine_account_uc.dart
    │   ├── select_user_uc.dart
    │   ├── switch_to_parent_uc.dart
    │   └── implementations...
    └── workspace_selection/
        ├── switch_to_first_workspace_uc.dart
        ├── switch_workspace_uc.dart
        └── implementations...
```

**Key Use Cases**:
- **Analytics**: User property tracking
- **App Version Check**: Force update logic
- **In-App Review**: Review prompts based on usage
- **User Selection**: Multi-user account switching
- **Workspace Selection**: Multi-tenant workspace switching
- **User Info Synchronization**: Device token, profile updates

### 3. Data Layer (`packages/`)

**Responsibility**: Data access, API communication, local storage

#### Domain Package (`packages/domain/`)

Unified domain package containing all repository interfaces, implementations, and domain exceptions. Previously 25 separate `*_repository` packages, now consolidated into a single `packages/domain/` package with 25 subdirectories.

**Repository Domains** (25 subdirectories under `lib/src/`):
- `analytics/` - Analytics events and tracking
- `assignment/` - Homework/assignments and submissions
- `authentication/` - Login/logout/token management
- `banner/` - Marketing banners and announcements
- `booking/` - Session bookings and scheduling
- `cart/` - Shopping cart operations
- `child/` - Child accounts management
- `configuration/` - App configuration and settings
- `course/` - Course catalog, enrollment, explore
- `crashlytics/` - Error tracking and reporting
- `credit_account/` - Credit account balances
- `credit/` - Credit transactions
- `instructor/` - Instructor data and profiles
- `invoice/` - Billing and invoices
- `learning_group/` - Learning groups/classes
- `notification/` - Push notifications
- `point/` - Gamification points and levels
- `progress/` - Learning progress tracking
- `report/` - Custom reports
- `resource/` - Files and learning resources
- `reward/` - Rewards and redemptions
- `session/` - Learning sessions
- `skill/` - Skills and competencies
- `user/` - User profiles and preferences
- `workspace/` - Multi-tenancy workspaces

**Domain Package Structure**:
```
domain/
├── lib/
│   ├── domain.dart                 # Public API (barrel file, exports all repositories)
│   ├── module.dart                 # DI module export
│   └── src/
│       ├── domain_module.dart      # Injectable module registering all repositories
│       ├── analytics/              # Each domain subdirectory follows the same layout:
│       │   ├── analytics_repository.dart       # Abstract interface
│       │   ├── analytics_repository_impl.dart  # Implementation
│       │   └── exception/                      # Domain exceptions
│       │       └── exception.dart
│       ├── user/
│       │   ├── user_repository.dart
│       │   ├── user_repository_impl.dart
│       │   └── exception/
│       │       └── exception.dart
│       └── ... (25 domain subdirectories total)
├── test/
│   ├── analysis_options.yaml
│   └── src/
│       └── ... (repository tests)
├── pubspec.yaml
└── README.md
```

**Example: UserRepository Interface** (at `packages/domain/lib/src/user/user_repository.dart`):
```dart
abstract interface class UserRepository {
  Future<User?> getCachedUser();
  Future<void> saveUserToLocal(User user);
  Future<User> getInformation();
  Future<void> update(UserInfoUpdate infoUpdate);
  Future<String> updateAvatar(String avatar);
  Future<void> changePassword(ChangePassword request);
  Future<bool> hasNoParent();
  bool hasMultipleUsers();
  Future<void> setMultipleUsersFlag({required bool value});
  DateTime getReviewAppTime();
  DateTime setReviewAppTime({Duration duration});
  Future<void> deleteUser();
}
```

#### Data Package (`packages/data/`)

Unified data source package containing both remote (API) and local (persistence) sources.

**Structure**:
```
data/
├── lib/
│   ├── data.dart                    # Barrel file (exports DataModule, local, remote)
│   └── src/
│       ├── data_module.dart             # Top-level DI module
│       ├── remote/                      # Remote data sources
│       │   ├── remote.dart              # Remote barrel file
│       │   ├── api/                     # Retrofit API definitions
│       │   │   ├── api_provider.dart    # Dio configuration & interceptors
│       │   │   └── generated/           # Retrofit generated code
│       │   │       ├── authentication/  # Auth API client
│       │   │       ├── course/          # Course API client
│       │   │       ├── booking/         # Booking API client
│       │   │       ├── user/            # User API client
│       │   │       ├── notification/    # Notification API client
│       │   │       └── ... (30+ API modules)
│       │   ├── service/                 # Service implementations
│       │   │   ├── service_provider.dart
│       │   │   ├── authentication/
│       │   │   │   ├── authentication_service_impl.dart
│       │   │   │   ├── service.dart
│       │   │   │   ├── model/
│       │   │   │   └── exception/
│       │   │   └── ... (30+ service modules)
│       │   ├── network/                 # Network utilities
│       │   │   └── network_impl.dart
│       │   └── model/                   # Shared remote models
│       │       ├── custom_converter.dart
│       │       ├── pagination/
│       │       └── error/
│       └── local/                       # Local data sources
│           ├── local.dart               # Local barrel file
│           ├── local_dependency_register.dart
│           ├── authentication/          # Token persistence
│           ├── user/                    # User preferences/cache
│           ├── workspace/               # Workspace cache
│           ├── biometric/               # Biometric settings
│           └── model/                   # Local storage models
├── test/
│   ├── helpers/
│   ├── mocks/
│   └── src/
├── build.yaml                           # Build runner configuration
├── pubspec.yaml
└── README.md
```

**Service Provider** (Injectable Module):
All services are registered through `ServiceProvider` for dependency injection. Located at `src/remote/service/service_provider.dart`.

**Key Services** (30+ services in `src/remote/service/`):
- `AuthenticationService` - Login, logout, token refresh, OTP
- `UserService` - User profile CRUD operations
- `CourseService` - Course CRUD, enrollments, filters
- `BookingService` - Session booking operations
- `NotificationService` - Push notification handling
- `SessionService` - Session CRUD, attendance
- `AssignmentService` - Assignment submissions
- `ProgressService` - Progress tracking
- `RewardService` - Rewards and redemptions
- `InstructorService` - Instructor data
- `ResourceService` - File uploads/downloads
- `CartService` - Shopping cart operations
- `InvoiceService` - Billing operations
- `CreditService` - Credit transactions
- `CreditAccountService` - Credit account operations
- `LearningGroupService` - Learning group management
- `WorkspaceService` - Workspace operations
- `PointService` - Points and levels
- `BannerService` - Banner content
- `ChildrenService` - Child account management
- `ConfigurationService` - App config retrieval
- `LessonService` - Lesson details
- `LibraryContentService` - Library content access
- `SkillService` - Skills and skill paths
- `ReportService` - Custom reports
- `WhitelabelService` - White-label configurations
- `SystemService` - System health checks

**Local Sources** (in `src/local/`):
- `authentication/` - Token persistence (SecureStorage)
- `user/` - User preferences, cached user data
- `workspace/` - Workspace cache
- `biometric/` - Biometric settings

**API Provider**:
Located at `src/remote/api/api_provider.dart`, configures Dio with:
- Base URL (environment-based)
- Interceptors (authentication, logging, error handling)
- Timeout configurations
- SSL certificate pinning
- Pretty logging (in debug mode)

#### Entity Package (`packages/entity/`)

Shared domain models across all layers. These are immutable data classes using `freezed` and `json_serializable`.

**Structure** (113 files):
```
entity/lib/
├── entity.dart                     # Public API (exports all entities)
└── src/
    ├── user/                           # User domain
    │   ├── entity.dart                 # User entity barrel
    │   ├── user.dart
    │   ├── membership.dart
    │   ├── user_mode.dart
    │   └── setting_language.dart
    ├── course/                         # Course domain
    │   ├── entity.dart
    │   ├── course.dart
    │   ├── course_enrollment.dart
    │   ├── course_types.dart
    │   ├── course_status.dart
    │   ├── course_settings.dart
    │   ├── course_property.dart
    │   ├── property.dart
    │   ├── property_value.dart
    │   ├── enrollment_type.dart
    │   ├── progress_status.dart
    │   ├── explore_filters.dart
    │   ├── explore_filter_option.dart
    │   ├── study_history.dart
    │   ├── course_report.dart
    │   ├── course_custom_report.dart
    │   └── absence_request_type.dart
    ├── session/                        # Session domain
    │   ├── entity.dart
    │   ├── session.dart
    │   ├── session_attendance.dart
    │   └── schedule_types.dart
    ├── assignment/                     # Assignment domain
    │   ├── entity.dart
    │   ├── assignment.dart
    │   ├── attempt.dart
    │   ├── task.dart
    │   ├── task_types.dart
    │   ├── task_result.dart
    │   └── task_submission_file.dart
    ├── booking/                        # Booking domain
    │   ├── entity.dart
    │   ├── booking_data.dart
    │   ├── booking_instructor.dart
    │   ├── session_instructor.dart
    │   └── session_slot.dart
    ├── instructor/                     # Instructor domain
    │   ├── entity.dart
    │   └── instructor.dart
    ├── notification/                   # Notification domain
    │   ├── entity.dart
    │   ├── notification.dart
    │   ├── notification_badge.dart
    │   ├── notification_events.dart
    │   ├── push_notification.dart
    │   └── push_notification_data.dart
    ├── reward/                         # Reward domain
    │   ├── entity.dart
    │   ├── reward.dart
    │   ├── reward_history.dart
    │   └── reward_history_statuses.dart
    ├── point/                          # Point domain
    │   ├── entity.dart
    │   ├── point.dart
    │   ├── point_history.dart
    │   ├── level.dart
    │   ├── coin_history_activities.dart
    │   ├── point_origin_types.dart
    │   └── transaction_types.dart
    ├── progress/                       # Progress domain
    │   ├── entity.dart
    │   ├── progress_stat.dart
    │   └── course_certificate.dart
    ├── resource/                       # Resource domain
    │   ├── entity.dart
    │   ├── resource.dart
    │   ├── resource_info.dart
    │   ├── resource_content_types.dart
    │   ├── resource_file_extensions.dart
    │   └── resource_stream_status.dart
    ├── learning_path/                  # Learning path domain
    │   ├── entity.dart
    │   ├── learning_path.dart
    │   ├── learning_path_format.dart
    │   ├── learning_group.dart
    │   ├── syllabus.dart
    │   └── program_type.dart
    ├── lesson/                         # Lesson domain
    │   ├── entity.dart
    │   └── lesson.dart
    ├── library/                        # Library domain
    │   ├── entity.dart
    │   ├── library_content.dart
    │   ├── library_lesson.dart
    │   ├── library_section.dart
    │   └── library_sections.dart
    ├── skill/                          # Skill domain
    │   ├── entity.dart
    │   ├── skill.dart
    │   └── skill_path.dart
    ├── invoice/                        # Invoice domain
    │   ├── entity.dart
    │   ├── invoice.dart
    │   ├── invoice_status.dart
    │   ├── invoice_file_type.dart
    │   └── common_file.dart
    ├── cart/                           # Cart domain
    │   ├── entity.dart
    │   └── cart.dart
    ├── credit/                         # Credit domain
    │   ├── entity.dart
    │   ├── credit_account.dart
    │   ├── credit_account_types.dart
    │   ├── credit_balance.dart
    │   ├── credit_transaction.dart
    │   └── credit_transaction_types.dart
    ├── banner/                         # Banner domain
    │   ├── entity.dart
    │   └── banner.dart
    ├── workspace/                      # Workspace domain
    │   ├── entity.dart
    │   ├── workspace.dart
    │   └── custom_field.dart
    ├── whitelabel/                     # White-label domain
    │   ├── entity.dart
    │   └── login_configurations.dart
    ├── currency/                       # Currency domain
    │   ├── entity.dart
    │   ├── currency.dart
    │   └── symbol_position.dart
    ├── tokens/                         # Token domain
    │   ├── entity.dart
    │   └── tokens.dart
    ├── extra/                          # Extra metadata
    │   ├── entity.dart
    │   └── extra.dart
    └── pagination/                     # Pagination wrapper
        ├── entity.dart
        └── pagination.dart
```

**Key Features**:
- `freezed` for immutable models with copyWith
- `json_serializable` for JSON parsing
- Enum extensions for type safety and display values
- Generic `Pagination<T>` wrapper for paginated responses
- Type-safe enums for all categorical data

#### UI Package (`packages/vle_ui/`)

Shared design system and reusable UI components. This is the single source of truth for all UI styling.

**Structure** (485 files):
```
vle_ui/
├── lib/
│   ├── vle_ui.dart                 # Public API
│   └── src/
│       ├── res/                        # Design tokens
│       │   ├── colors.dart             # VleColors (brand, neutral, semantic)
│       │   ├── dimens.dart             # VleDimens (spacing, sizing)
│       │   ├── typography.dart         # VleTextStyles
│       │   ├── icons.dart              # VleIcons (SVG icon widgets)
│       │   ├── images.dart             # VleImages (image widgets)
│       │   └── gen/                    # Flutter Gen generated
│       │       └── assets.gen.dart
│       ├── widgets/                    # Reusable widgets (100+ widgets)
│       │   ├── buttons/
│       │   │   ├── vle_button.dart
│       │   │   ├── vle_icon_button.dart
│       │   │   ├── vle_text_button.dart
│       │   │   └── vle_outlined_button.dart
│       │   ├── cards/
│       │   │   ├── vle_card.dart
│       │   │   └── vle_info_card.dart
│       │   ├── inputs/
│       │   │   ├── vle_text_field.dart
│       │   │   ├── vle_dropdown.dart
│       │   │   └── vle_checkbox.dart
│       │   ├── dialogs/
│       │   │   ├── vle_dialog.dart
│       │   │   └── vle_bottom_sheet.dart
│       │   ├── loaders/
│       │   │   ├── vle_loading_indicator.dart
│       │   │   └── vle_skeleton_loader.dart
│       │   ├── navigation/
│       │   │   ├── vle_app_bar.dart
│       │   │   ├── vle_tab_bar.dart
│       │   │   └── vle_bottom_nav.dart
│       │   ├── display/
│       │   │   ├── vle_avatar.dart
│       │   │   ├── vle_badge.dart
│       │   │   ├── vle_chip.dart
│       │   │   └── vle_divider.dart
│       │   └── ... (many more widget categories)
│       └── theme/                      # Material theme
│           ├── vle_theme.dart          # ThemeData configuration
│           └── vle_theme_extensions.dart
├── assets/                         # UI assets
│   ├── icons/                      # SVG icons (150+ files)
│   ├── images/                     # WebP images (114+ files)
│   └── fonts/                      # Custom fonts
├── example/                        # Widget gallery app
│   ├── lib/
│   │   └── main.dart               # Gallery app
│   ├── pubspec.yaml
│   └── README.md
├── test/
├── build.yaml                      # Flutter Gen config
├── pubspec.yaml
└── README.md
```

**Design System**:
- **VleColors**: Brand colors, neutral palette, semantic colors (success, error, warning, info)
- **VleDimens**: Spacing scale (4px increments), component sizes
- **VleTextStyles**: Typography scale (display, heading, body, label, caption)
- **VleIcons**: Static methods returning SVG widgets with color/size params
- **VleImages**: Static methods returning image widgets

**Widget Gallery**:
Run the example app to see all components:
```bash
cd packages/vle_ui/example/
flutter run
```

#### Shared Lint Package (`packages/shared_lint/`)

Centralized linting rules used by all packages.

**Structure**:
```
shared_lint/
├── lib/
│   └── analysis_options.yaml       # Shared linting rules
├── pubspec.yaml
└── README.md
```

**Usage**:
Each package includes:
```yaml
# analysis_options.yaml
include: package:shared_lint/analysis_options.yaml
```

---

## Core Infrastructure (`lib/core/`)

### Flavor System (`core/flavors/`)

Multi-environment and multi-tenant (white-label) support through build flavors.

**Environments**:
1. **Development** - `dev-vle.thelearningos.com` (dev API)
2. **Staging** - `stg-vle.thelearningos.com` (staging API)
3. **Sandbox** - `sandbox.thelearningos.com` (production API, sandbox tenant)
4. **Ooolab** (Production) - `vle.thelearningos.com` (production API, ooolab tenant)
5. **Nihaoma** (White-label) - `vle.nihaoma.thelearningos.com` (production API, nihaoma tenant)
6. **Soa** (White-label) - `soa.thelearningos.com` (production API, soa tenant)
7. **Nse** (White-label) - `nse.thelearningos.com` (production API, nse tenant)

**Configuration Files**:
```
environment_configurations/
├── api/
│   ├── .development.env            # Dev API URLs
│   ├── .staging.env                # Staging API URLs
│   └── .production.env             # Production API URLs
├── tenant/
│   ├── .development.env            # Dev tenant config
│   ├── .staging.env                # Staging tenant config
│   ├── .sandbox.env                # Sandbox tenant config
│   ├── .ooolab.env                 # Ooolab tenant config
│   ├── .nihaoma.env                # Nihaoma tenant config
│   ├── .soa.env                    # Soa tenant config
│   └── .nse.env                    # Nse tenant config
├── certificates/
│   ├── .trusted_certificates.env   # SSL certificate pinning
│   └── .trusted_fingerprints.env   # SSL fingerprints
└── .general.env                    # General config (all environments)
```

**Firebase Options** (`core/flavors/firebase_options/`):
Each flavor has a dedicated Firebase project:
- `development.dart`
- `staging.dart`
- `sandbox.dart`
- `ooolab.dart`
- `nihaoma.dart`
- `soa.dart`
- `nse.dart`

**Clarity Configurations** (`core/flavors/clarity_configurations/`):
Analytics (Microsoft Clarity) configuration per flavor.

**Flavor Definition** (`core/flavors/flavor.dart`):
```dart
enum Flavor {
  development,
  staging,
  sandbox,
  ooolab,
  nihaoma,
  soa,
  nse,
}
```

### Permissions (`core/permission/`)

Centralized permission handling for camera, microphone, storage, notifications, etc.

**Files**:
- `app_permission.dart` - Permission interface
- `app_permission_impl.dart` - Implementation using `permission_handler`

### State Management (`core/state_management/`)

BLoC infrastructure and utilities for state management.

**Files**:
- **`vle_bloc_observer.dart`** - Global BLoC observer for logging/debugging state transitions
- **`cubit_mixin.dart`** - Common Cubit functionality (error handling, loading states)
- **`data_load_status.dart`** - Standard loading states enum (initial, loading, success, error)
- **`form_status.dart`** - Form submission states enum (initial, validating, submitting, success, failure)

---

## Dependency Injection (`lib/locator/`)

### Service Locator Setup

Uses `get_it` with `injectable` for compile-time dependency injection.

**Structure**:
```
locator/
├── locator.dart                    # GetIt instance configuration
├── register_module.dart            # @InjectableInit generated code
└── repository_provider/
    └── repository_provider.dart    # Repository DI module
```

**Key Files**:

**`locator.dart`**:
```dart
final locator = GetIt.instance;

Future<void> setupLocator() async {
  await locator.init(); // Generated by injectable
}
```

**`register_module.dart`**:
Contains `@InjectableInit` annotation. After running `build_runner`, generates `locator.init()` method.

**`repository_provider.dart`**:
Injectable module for all repositories (delegates to `DomainModule` from `packages/domain/`):
```dart
@module
abstract class RepositoryProvider {
  UserRepository userRepository(
    UserService service,
    UserDatabaseService databaseService,
  ) => UserRepositoryImpl(service, databaseService);
  
  CourseRepository courseRepository(
    CourseService service,
  ) => CourseRepositoryImpl(service);
  
  // ... all other repositories
}
```

**Registration Flow**:
1. Add `@injectable` or `@module` annotations
2. Run `dart run build_runner build -d`
3. Call `setupLocator()` in `vle_application.dart`
4. Access dependencies: `locator<Type>()` or constructor injection

**Dependency Scopes**:
- `@singleton` - Single instance for app lifetime
- `@lazySingleton` - Single instance, created on first access
- `@injectable` - New instance every time

---

## Utilities & Mixins

### Mixins (`lib/mixin/`)

Reusable behavior for widgets and cubits (10 files):
- Navigation mixins (push, pop, replace)
- Loading state mixins
- Error handling mixins
- Form validation mixins
- Lifecycle mixins
- Analytics tracking mixins

### Utilities (`lib/utils/`)

Helper functions and extensions (16 files):
- Date/time utilities (formatting, parsing, timezone)
- String extensions (validation, formatting)
- Number extensions (formatting, currency)
- List extensions (chunking, grouping)
- Validation helpers (email, phone, password)
- Format helpers (file size, duration)

### Resources (`lib/res/`)

Generated asset references:
- `gen/assets.gen.dart` - Generated by Flutter Gen

---

## Localization (`lib/localization/` + `translations/`)

### Localization Setup

- **Package**: `easy_localization` 3.0.8
- **Languages**: English (en-US), Vietnamese (vi-VN), French (fr-FR)
- **Translation Files**: `translations/*.json`
- **Generated Keys**: `lib/localization/generated/localization.dart`

### Translation Files

```
translations/
├── en-US.json      # English (source of truth)
├── vi-VN.json      # Vietnamese
└── fr-FR.json      # French
```

**Example structure** (`en-US.json`):
```json
{
  "common": {
    "ok": "OK",
    "cancel": "Cancel",
    "save": "Save"
  },
  "login": {
    "title": "Sign In",
    "email": "Email",
    "password": "Password"
  }
}
```

### Workflow:

1. **Add keys** to `translations/en-US.json`
2. **Generate** localization keys:
   ```bash
   fvm dart run melos generate-translation
   ```
3. **Use in code**:
   ```dart
   Text(LocalizationKeys.login_title.tr())
   ```
4. **Watch mode** (auto-regenerate on file changes):
   ```bash
   ./scripts/watch_translation.sh
   ```

---

## Configuration & Build Files

### Linting & Analysis

- **Root**: `analysis_options.yaml` - Project-wide linting rules (Very Good Analysis + custom rules)
- **Shared**: `packages/shared_lint/` - Shared linting rules across packages
- **BLoC Lint**: `bloc_lint` 0.3.2 for BLoC-specific lint rules

### Asset Management

**Flutter Gen**:
Auto-generates `Assets` class from `assets/` and `packages/vle_ui/assets/`.

**Configuration** (`pubspec.yaml`):
```yaml
flutter_gen:
  output: lib/res/gen/
  line_length: 80
  integrations:
    flutter_svg: true
    image: true
  assets:
    enabled: true
    exclude:
      - translations/**
    outputs:
      style: dot-delimiter
```

**Generated**: `lib/res/gen/assets.gen.dart`

**Usage**:
```dart
Assets.images.logo.image()
Assets.icons.home.svg()
```

### Launcher Icons & Splash Screens

Each flavor has dedicated configuration files:

**Launcher Icons**:
- `flutter_launcher_icons-development.yaml`
- `flutter_launcher_icons-staging.yaml`
- `flutter_launcher_icons-sandbox.yaml`
- `flutter_launcher_icons-ooolab.yaml`
- `flutter_launcher_icons-nihaoma.yaml`
- `flutter_launcher_icons-soa.yaml`
- `flutter_launcher_icons-nse.yaml`

**Splash Screens**:
- `flutter_native_splash-development.yaml`
- `flutter_native_splash-staging.yaml`
- `flutter_native_splash-sandbox.yaml`
- `flutter_native_splash-ooolab.yaml`
- `flutter_native_splash-nihaoma.yaml`
- `flutter_native_splash-soa.yaml`
- `flutter_native_splash-nse.yaml`

**Assets**:
- `launcher_icon/{android|ios}/` - App icon assets per flavor
- `splash_logo/` - Splash screen assets per flavor
- `splash_logo/android_12/` - Android 12+ splash icons

**Commands**:
```bash
# Generate all launcher icons
fvm dart run melos generate-app-icon

# Generate all splash screens
fvm dart run melos generate-splash-screen
```

### Native Configuration

#### Android (`android/`)

- **`android/app/build.gradle`** - Gradle configuration, build flavors, signing configs
- **`android/app/src/`** - Flavor-specific resources (icons, strings, manifests)
- **`android/fastlane/`** - Deployment automation
- **`android/Gemfile`** - Ruby dependencies for Fastlane

**Flavors** (in `build.gradle`):
```groovy
flavorDimensions "default"
productFlavors {
    development { ... }
    staging { ... }
    sandbox { ... }
    ooolab { ... }
    nihaoma { ... }
    soa { ... }
    nse { ... }
}
```

#### iOS (`ios/`)

- **`ios/Runner.xcodeproj/`** - Xcode project, schemes per flavor
- **`ios/Runner/`** - App source, storyboards, Info.plist
- **`ios/config/`** - Flavor-specific configurations
- **`ios/fastlane/`** - Deployment automation
- **`ios/Podfile`** - CocoaPods dependencies

**Schemes**: 7 schemes (one per flavor) in Xcode

---

## Testing Structure (`test/`)

### Test Organization (465 test files)

Mirrors the `lib/` structure for easy navigation:

```
test/
├── analysis_options.yaml           # Test-specific linting
├── mocks/                          # Mocktail mocks (5 files)
│   ├── mock_repositories.dart      # All repository mocks
│   ├── mock_services.dart          # All service mocks (remote)
│   ├── mock_storage.dart           # All local source mocks
│   ├── mock_use_cases.dart         # All use case mocks
│   └── mock_navigation.dart        # Navigation mocks
├── test_helpers/                   # Testing utilities (1 file)
│   └── test_helpers.dart           # pump_app, mock setup utilities
├── components/                     # Component tests (6 files)
│   ├── broadcast/
│   ├── pagination/
│   └── route/
├── screens/                        # Screen tests (413 files)
│   ├── home/
│   │   ├── cubit/
│   │   │   └── home_cubit_test.dart
│   │   └── views/
│   │       └── home_screen_test.dart
│   ├── login/
│   ├── explore/
│   └── ... (mirrors all screens/)
├── use_case/                       # Use case tests (11 files)
│   ├── analytics/
│   ├── app/
│   └── user/
├── widgets/                        # Widget tests (20 files)
│   ├── button_test.dart
│   ├── card_test.dart
│   └── ...
├── utils/                          # Utility tests (4 files)
├── core/                           # Core tests (1 file)
├── localization/                   # Localization tests (1 file)
└── mixin/                          # Mixin tests (1 file)
```

### Testing Strategy

- **Unit Tests**: Use cases, utilities, models, repositories
- **Widget Tests**: Individual widgets and screens with mocked dependencies
- **BLoC Tests**: Cubit state transitions using `bloc_test`
- **Integration Tests**: (Future) End-to-end flows
- **Coverage**: Enforced via CI/CD, reports in `coverage/`

### Running Tests

```bash
# All tests with coverage
fvm flutter test --coverage --branch-coverage --fail-fast -r failures-only --test-randomize-ordering-seed random

# Generate HTML coverage report
lcov --ignore-errors inconsistent --branch-coverage --no-function-coverage -r coverage/lcov.info -o coverage/lcov.info && \
genhtml --ignore-errors inconsistent,corrupt --branch-coverage --no-function-coverage coverage/lcov.info -o coverage && \
open coverage/index.html
```

### Test Helpers

**`test/test_helpers/test_helpers.dart`**:
- `pumpApp()` - Wraps widget in MaterialApp with all necessary providers
- `mockRepositories()` - Sets up all repository mocks
- `mockAuthenticationState()` - Mocks authentication state

**`test/mocks/`**:
- All mocks created with `mocktail`
- Centralized mock classes for consistency

---

## Scripts & Automation

### Cursor command scripts (`.cursor/commands/scripts/`)

- **`push.sh`** - Push workflow: format, stage, commit, push
- **`merge_request.sh`** - Create GitLab merge request via glab
- **`flutter_upgrade.sh`** - Automated Flutter version upgrade

### Build & configuration scripts (`scripts/`)

- **`configure_firebase_flavor.sh`** - Firebase flavor configuration
- **`download_whitelabel_icons.sh`** - Fetch white-label assets from Figma API
- **`setup_figma_token.sh`** - Figma API token setup
- **`figma_token_manager.sh`** - Secure Figma token storage/retrieval
- **`export_domain_certificates.sh`** - SSL certificate export for pinning
- **`convert_images_to_webp.sh`** - Batch image optimization to WebP
- **`watch_translation.sh`** - Auto-regenerate translations on file changes

---

## CI/CD & Deployment

### Fastlane Configuration

**Android** (`android/fastlane/`):
- `Fastfile` - Android deployment lanes
- `Appfile` - Android app configuration
- `metadata/` - Play Store metadata

**iOS** (`ios/fastlane/`):
- `Fastfile` - iOS deployment lanes
- `Appfile` - iOS app configuration
- `metadata/` - App Store Connect metadata

**Common** (root):
- `CommonFastfile` - Shared lanes across platforms
- `GeneralFastFile` - General deployment utilities
- `NotificationFastfile` - Build notification lanes

### Firebase Distribution

Internal testing distribution via Firebase App Distribution:
- Automated builds per flavor
- Tester groups in `groups.txt` & `testers.txt`
- Distribution via Fastlane

### Web CI/CD Portal

Custom build portal: `https://mobile-cicd-97b09.web.app/`

**Features**:
- Select branch, flavor, environment
- Trigger builds for iOS/Android
- Download build artifacts
- View build logs

---

## Melos Monorepo Management

### Melos Configuration

Workspace packages managed via Melos 7.2.0. Configuration in `pubspec.yaml` under `melos:` section.

**Workspace**:
- Root project (`useRootAsPackage: true`)
- All packages in `packages/*` (5 packages: `data`, `domain`, `entity`, `shared_lint`, `vle_ui`)

**Categories**:
- `app`: Root project
- `packages`: All packages in `packages/*`

### Key Scripts

```bash
# Code generation across all packages
fvm dart run melos generate --no-select

# Clean all packages
fvm dart run melos clean-up

# Get dependencies for all packages
fvm dart run melos pub-get

# Check outdated dependencies
fvm dart run melos pub-outdated

# Format and lint all packages
fvm dart run melos dart-format

# Generate splash screens for all flavors
fvm dart run melos generate-splash-screen

# Generate app icons for all flavors
fvm dart run melos generate-app-icon

# Generate translations
fvm dart run melos generate-translation

# Watch translations and auto-regenerate
./scripts/watch_translation.sh

# CI clean-up (preserve coverage)
fvm dart run melos ci-clean-up
```

---

## Development Workflow

### 1. Running the App

**⚠️ Recommendation**: Use **Development** flavor only during development.

**Via Flutter CLI** (Development):
```bash
fvm flutter run --flavor development \
  --dart-define-from-file environment_configurations/api/.development.env \
  --dart-define-from-file environment_configurations/tenant/.development.env \
  --dart-define-from-file environment_configurations/.general.env \
  --dart-define-from-file environment_configurations/certificates/.trusted_certificates.env \
  --dart-define-from-file environment_configurations/certificates/.trusted_fingerprints.env
```

**Or use run configurations**:
- **Android Studio**: Select flavor from run configurations dropdown
- **VS Code**: Use launch configurations in `.vscode/launch.json` (Debug panel)

### 2. Adding New Features

#### Step 1: Create Feature Screen

```bash
# Navigate to screens directory
cd lib/screens/

# Create feature structure
mkdir -p new_feature/{cubit,route,views,models,widgets}

# Create barrel file
touch new_feature/new_feature.dart

# Create cubit files
touch new_feature/cubit/new_feature_cubit.dart
touch new_feature/cubit/new_feature_state.dart

# Create route files
touch new_feature/route/new_feature_route.dart
touch new_feature/route/route.dart

# Create view files
touch new_feature/views/new_feature_screen.dart
touch new_feature/views/views.dart

# Create model files (if needed)
touch new_feature/models/models.dart
```

#### Step 2: Implement Cubit (State Management)

**`new_feature_state.dart`**:
```dart
part of 'new_feature_cubit.dart';

@freezed
class NewFeatureState with _$NewFeatureState {
  const factory NewFeatureState.initial() = _Initial;
  const factory NewFeatureState.loading() = _Loading;
  const factory NewFeatureState.success(Data data) = _Success;
  const factory NewFeatureState.error(String message) = _Error;
}
```

**`new_feature_cubit.dart`**:
```dart
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'new_feature_state.dart';
part 'new_feature_cubit.freezed.dart';

@injectable
class NewFeatureCubit extends Cubit<NewFeatureState> {
  NewFeatureCubit(
    this._repository,
    this._useCase,
  ) : super(const NewFeatureState.initial());

  final SomeRepository _repository;
  final SomeUseCase _useCase;

  Future<void> loadData() async {
    emit(const NewFeatureState.loading());
    try {
      final data = await _repository.getData();
      emit(NewFeatureState.success(data));
    } catch (e) {
      emit(NewFeatureState.error(e.toString()));
    }
  }
}
```

**Generate freezed code**:
```bash
fvm dart run build_runner build -d
```

#### Step 3: Create UI

**`new_feature_screen.dart`**:
```dart
class NewFeatureScreen extends StatelessWidget {
  const NewFeatureScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => locator<NewFeatureCubit>()..loadData(),
      child: Scaffold(
        appBar: AppBar(title: Text('New Feature')),
        body: BlocBuilder<NewFeatureCubit, NewFeatureState>(
          builder: (context, state) {
            return state.when(
              initial: () => SizedBox.shrink(),
              loading: () => Center(child: CircularProgressIndicator()),
              success: (data) => Text('Data: $data'),
              error: (message) => Center(child: Text('Error: $message')),
            );
          },
        ),
      ),
    );
  }
}
```

**`new_feature_route.dart`**:
```dart
import 'package:flutter/material.dart';

class NewFeatureRoute extends PageRoute {
  NewFeatureRoute() : super(
    settings: const RouteSettings(name: '/new-feature'),
  );

  @override
  Widget buildPage(...) => const NewFeatureScreen();
}
```

#### Step 4: Add Tests

```bash
cd test/screens/new_feature/

# Create cubit test
mkdir -p cubit
cat > cubit/new_feature_cubit_test.dart << 'EOF'
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('NewFeatureCubit', () {
    late NewFeatureCubit cubit;
    late MockRepository mockRepository;

    setUp(() {
      mockRepository = MockRepository();
      cubit = NewFeatureCubit(mockRepository);
    });

    blocTest<NewFeatureCubit, NewFeatureState>(
      'emits [loading, success] when loadData succeeds',
      build: () {
        when(() => mockRepository.getData()).thenAnswer((_) async => data);
        return cubit;
      },
      act: (cubit) => cubit.loadData(),
      expect: () => [
        const NewFeatureState.loading(),
        NewFeatureState.success(data),
      ],
    );
  });
}
EOF

# Create widget test
mkdir -p views
cat > views/new_feature_screen_test.dart << 'EOF'
import 'package:flutter_test/flutter_test.dart';
import '../../test_helpers/test_helpers.dart';

void main() {
  testWidgets('NewFeatureScreen renders correctly', (tester) async {
    await tester.pumpApp(const NewFeatureScreen());
    expect(find.text('New Feature'), findsOneWidget);
  });
}
EOF
```

### 3. Adding New Repository

Add a new domain subdirectory inside the unified `packages/domain/` package:

```bash
cd packages/domain/

# Create new domain subdirectory
mkdir -p lib/src/new_domain/exception
touch lib/src/new_domain/new_domain_repository.dart
touch lib/src/new_domain/new_domain_repository_impl.dart
touch lib/src/new_domain/exception/exception.dart
```

**Implement**:

**`lib/src/new_domain/new_domain_repository.dart`** (interface):
```dart
abstract interface class NewDomainRepository {
  Future<Data> getData();
  Future<void> saveData(Data data);
}
```

**`lib/src/new_domain/new_domain_repository_impl.dart`** (implementation):
```dart
import 'package:injectable/injectable.dart';

class NewDomainRepositoryImpl implements NewDomainRepository {
  NewDomainRepositoryImpl(this._service, this._databaseService);

  final NewDomainService _service;
  final NewDomainDatabaseService _databaseService;

  @override
  Future<Data> getData() async {
    try {
      // Try cache first
      final cached = await _databaseService.getCachedData();
      if (cached != null) return cached;

      // Fetch from API
      final data = await _service.getData();
      
      // Cache it
      await _databaseService.cacheData(data);
      
      return data;
    } catch (e) {
      throw GetDataException(e.toString());
    }
  }

  @override
  Future<void> saveData(Data data) async {
    try {
      await _service.saveData(data);
      await _databaseService.cacheData(data);
    } catch (e) {
      throw SaveDataException(e.toString());
    }
  }
}
```

**Register in domain module** (`lib/src/domain_module.dart`):
```dart
// Add factory method for the new repository
NewDomainRepository newDomainRepository(
  NewDomainService service,
  NewDomainDatabaseService databaseService,
) => NewDomainRepositoryImpl(service, databaseService);
```

**Export from barrel file** (`lib/domain.dart`):
```dart
export 'src/new_domain/new_domain_repository.dart';
export 'src/new_domain/exception/exception.dart';
```

**Run code generation**:
```bash
cd ../..  # Back to root
fvm dart run build_runner build -d
```

### 4. Code Generation

```bash
# After modifying models or adding @injectable
fvm dart run build_runner build -d

# For all packages
fvm dart run melos generate --no-select

# Watch mode (auto-regenerate on file changes)
fvm dart run build_runner watch
```

### 5. Localization

```bash
# Add keys to translations/en-US.json
# Then generate
fvm dart run melos generate-translation

# Or watch for changes
./scripts/watch_translation.sh
```

---

## Key Design Patterns

### 1. Clean Architecture Layers

```
Presentation (Screens/Widgets) → Domain (Use Cases) → Data (Repositories) → Service (API)
```

**Dependency Rule**: Inner layers never depend on outer layers.
- Presentation depends on Domain
- Domain depends on Data (interfaces only)
- Data depends on Service
- Service has no dependencies

**Abstraction**: Repositories and Use Cases are **interfaces** (abstract classes).

### 2. BLoC Pattern

- **Cubit**: Simplified BLoC for most features (no events, just methods)
- **State**: Immutable states using `freezed` with union types
- **BLoC**: For complex state machines with events (rarely used)

**Example**:
```dart
// State (freezed union)
@freezed
class MyState with _$MyState {
  const factory MyState.initial() = _Initial;
  const factory MyState.loading() = _Loading;
  const factory MyState.success(Data data) = _Success;
  const factory MyState.error(String message) = _Error;
}

// Cubit
class MyCubit extends Cubit<MyState> {
  MyCubit() : super(const MyState.initial());

  void loadData() async {
    emit(const MyState.loading());
    // ... fetch data
    emit(MyState.success(data));
  }
}

// UI
BlocBuilder<MyCubit, MyState>(
  builder: (context, state) {
    return state.when(
      initial: () => SizedBox(),
      loading: () => Loader(),
      success: (data) => DataView(data),
      error: (msg) => ErrorView(msg),
    );
  },
)
```

### 3. Repository Pattern

- **Abstract interfaces** in `packages/domain/lib/src/<domain>/`
- **Implementation** injects remote services and local sources
- **Caching logic** in repositories
- **Error handling** in repositories (convert service exceptions to domain exceptions)

### 4. Dependency Injection

- **`get_it`** for service locator
- **`injectable`** for compile-time generation
- **Constructor injection** preferred
- **Singleton** for most services and repositories
- **LazySingleton** for heavy objects

### 5. Broadcast Pattern

- **Global state coordination** via broadcast cubits
- **Screens listen** to broadcasts for cross-feature updates
- **Examples**: Notification badge count, assignment updates, session actions

---

## Common Conventions

### File Naming

- **Dart files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/functions**: `camelCase`
- **Constants**: `camelCase` or `SCREAMING_SNAKE_CASE` for compile-time constants
- **Private members**: `_camelCase`

### Directory Structure

- Always include **barrel files** (e.g., `feature.dart` exports all)
- **Group by feature**, not by type (e.g., `login/cubit/`, not `cubits/login/`)
- Use standard subdirectories: `cubit/`, `route/`, `views/`, `models/`, `widgets/`

### BLoC Naming

- **Cubit**: `FeatureNameCubit` (e.g., `LoginCubit`)
- **State**: `FeatureNameState` (e.g., `LoginState`)
- **State variants** (with freezed): `FeatureNameInitial`, `FeatureNameLoading`, etc.

### Import Ordering

1. Dart SDK imports (`dart:*`)
2. Flutter SDK imports (`package:flutter/`)
3. External package imports (`package:*/`)
4. Internal package imports (`package:entity/`, `package:data/`, etc.)
5. Relative imports (`./`, `../`)

**Separate groups with blank lines**.

### Class Member Ordering

1. Static fields
2. Instance fields (public then private)
3. Constructors
4. Static methods
5. Instance methods (public then private)
6. Overrides

---

## Resources & Documentation

### Internal Documentation

- **`README.md`** - Getting started, setup instructions, technology stack
- **`CONTRIBUTING.md`** - Contribution guidelines
- **`CHANGELOG.md`** - Release notes history
- **`release-notes.txt`** - Latest deployment notes
- **Package READMEs** - Each package has its own README

### API Documentation

- **Contact**: thang.nt@ooolab.edu.vn (for API docs access)
- **Docs**: https://docs-vle.thelearningos.com/v1/docs/

### Code Coverage

- **Reports**: `coverage/index.html` (generated locally)
- **Badge**: Codecov integration via GitLab CI

### Recommended IDE Plugins

**Android Studio / IntelliJ**:
- Dart
- Flutter
- Bloc
- Flutter Toolkit
- RestfulTool Retrofit
- String Manipulation

**VS Code**:
- Dart
- Flutter
- Bloc
- Awesome Flutter Snippets
- Pubspec Assist
- TabOut
- Todo Tree
- Code Spell Checker
- Advanced New File

---

## Quick Reference

### Most Important Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry point |
| `lib/vle_application.dart` | App initialization |
| `lib/locator/locator.dart` | Dependency injection setup |
| `lib/components/route/navigator.dart` | Navigation utilities |
| `packages/entity/` | All domain models |
| `packages/domain/` | All repository interfaces and implementations |
| `packages/data/` | API layer |
| `packages/data/src/local/` | Local persistence |
| `packages/vle_ui/` | Design system |

### Most Common Commands

```bash
# Run app (Development)
fvm flutter run --flavor development

# Code generation
fvm dart run build_runner build -d

# Run all tests with coverage
fvm flutter test --coverage --branch-coverage --fail-fast -r failures-only --test-randomize-ordering-seed random

# Generate translations
fvm dart run melos generate-translation

# Watch translations
./scripts/watch_translation.sh

# Clean project
fvm dart run melos clean-up && fvm dart run melos pub-get

# Generate splash screens
fvm dart run melos generate-splash-screen

# Generate app icons
fvm dart run melos generate-app-icon

# Format code
fvm dart format .

# Analyze code
fvm flutter analyze

# Check for linting issues
bloc lint lib test
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Build errors after pull | `fvm flutter clean && fvm flutter pub get && fvm dart run build_runner build -d` |
| DI errors (can't find dependencies) | Run `fvm dart run build_runner build -d` |
| Missing translations | Run `fvm dart run melos generate-translation` |
| iOS build fails | `cd ios && pod install && pod update` |
| Android build fails | Clean Android: `cd android && ./gradlew clean` |
| Asset not found | Run `fvm dart run build_runner build -d` (regenerates assets) |
| Flavor configuration error | Check `environment_configurations/` files exist |

---

## Best Practices

### Project Organization

1. **Feature-based structure** - Group related files by feature
2. **Single responsibility** - Each package/class handles one concern
3. **Clear separation** - UI, business logic, and data layers separated
4. **Consistent naming** - Follow established conventions
5. **Small files** - Keep files under 200-300 lines

### Package Management

1. **Minimal dependencies** - Each package only depends on what it needs
2. **Share through entity** - Common models in `entity` package
3. **Use local packages** - `path:` dependency for internal packages
4. **Avoid circular dependencies** - Dependency graph should be acyclic
5. **Document packages** - Each package has comprehensive README

### State Management

1. **Cubit over BLoC** - Use Cubit for simpler state management
2. **Freezed states** - Immutable states with union types
3. **Handle all states** - Initial, loading, success, error
4. **Dispose properly** - Close streams and cubits
5. **Test state transitions** - Use `bloc_test`

### Dependency Flow

```
Presentation (lib/screens/)
     ↓
Domain (lib/use_case/, packages/entity/)
     ↓
Data (packages/domain/)
     ↓
Data Sources (packages/data/ — remote + local)
```

See `@clean-architecture` for detailed dependency rules.

---

## Related Documentation

For specific implementation patterns and guidelines, see:
- `@clean-architecture` - Architecture patterns and data flow
- `@flutter-coding-standards` - Widget architecture and Flutter best practices
- `@state-management` - BLoC/Cubit implementation patterns
- `@dart-coding-standards` - Dart language best practices
- `@testing-guidelines` - Testing strategies and patterns
- `@bash-scripting-standards` - Bash scripting guidelines
- `@add-whitelabel-guidelines` - Adding new white-label configurations
- `@development-workflow` - Development workflow and processes
- `@localization-guidelines` - Localization and translation management
