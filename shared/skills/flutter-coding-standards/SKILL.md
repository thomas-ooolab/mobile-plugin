---
name: flutter-coding-standards
description: "Flutter coding standards covering widget architecture, composition, and performance - complements @dart-coding-standards, @state-management, @clean-architecture, @testing-guidelines, and @localization-guidelines"
---

## Related Guidelines

This document focuses on Flutter-specific patterns. For complete guidance, also refer to:
- `@dart-coding-standards` - Dart language best practices, patterns, naming conventions
- `@state-management` - BLoC/Cubit patterns, state management, testing
- `@clean-architecture` - Layer separation, dependency injection, repositories
- `@testing-guidelines` - Testing strategies and patterns
- `@localization-guidelines` - Translation and localization

## Key Principles

### Flutter-Specific Best Practices
1. **Use Widget Classes** - ALWAYS extract widgets into classes, NOT build methods
2. **Const Constructors** - Use const everywhere possible for performance
3. **Widget Composition** - Build widget trees with classes, not nested functions
4. **StatelessWidget First** - Prefer StatelessWidget, use StatefulWidget only for local UI state
5. **Small, Focused Widgets** - Keep widgets under 200 lines, extract complexity

## Widget Architecture

### Widget Classes vs Build Methods

**CRITICAL RULE**: ALWAYS use Widget classes instead of build methods for reusable UI components.

#### Why Widget Classes Are Mandatory

- **DO** use Widget classes for ALL reusable UI components.
```dart
// ✅ GOOD - Widget class enables const optimization and hot reload
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(text),
    );
  }
}

// Usage with const (performance win!)
const PrimaryButton(
  text: 'Save',
  onPressed: _handleSave,
);
```

- **DON'T** use build methods for reusable widgets.
```dart
// ❌ BAD - Build method prevents const optimization and breaks hot reload
Widget _buildPrimaryButton({
  required String text,
  required VoidCallback? onPressed,
  bool isLoading = false,
}) {
  return ElevatedButton(
    onPressed: isLoading ? null : onPressed,
    child: isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(text),
  );
}

// Can't use const, worse hot reload, harder to debug
_buildPrimaryButton(
  text: 'Save',
  onPressed: _handleSave,
);
```

#### Benefits of Widget Classes

1. **Performance**: Enable const constructors for unchanged widgets
2. **Hot Reload**: Better hot reload support and widget tree inspection
3. **DevTools**: Easier debugging in Flutter DevTools widget tree
4. **Testability**: Can test widgets in isolation with widget tests
5. **Reusability**: Clear interface with named parameters
6. **Type Safety**: Compile-time checking of parameters
7. **Documentation**: Self-documenting with named parameters and types

#### When Build Methods Are Acceptable

- **CONSIDER** using build methods ONLY for:
  - One-time, non-reusable widget compositions within a single widget
  - Very simple conditional rendering (2-3 lines)
  - Private helper methods with NO parameters

```dart
// Acceptable - Private helper, no parameters, single use
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildDivider(), // Acceptable if simple
          UserDetailsCard(user: user), // Better - widget class
        ],
      ),
    );
  }

  // Acceptable ONLY if: no parameters, <5 lines, single use
  Widget _buildDivider() {
    return const Divider(height: 1);
  }
}
```

- **PREFER** extracting to Widget classes if:
  - The widget has ANY parameters → Extract to class
  - The widget might be reused → Extract to class
  - The widget is complex (>5 lines) → Extract to class
  - You want to use const → Extract to class

```dart
// Better approach - Extract to widget classes
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.user, super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ProfileDivider(), // Widget class
          UserDetailsCard(user: user), // Widget class
        ],
      ),
    );
  }
}

class ProfileDivider extends StatelessWidget {
  const ProfileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1);
  }
}
```

### StatelessWidget vs StatefulWidget

- **PREFER** StatelessWidget when widget doesn't need mutable state.
```dart
// Good - Stateless for immutable widgets
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.imageUrl,
    this.radius = 20,
    super.key,
  });

  final String imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(imageUrl),
    );
  }
}
```

- **DO** use StatefulWidget ONLY for local UI state (animations, form controllers, scroll controllers).
```dart
// Good - Stateful for local UI state only
class ExpandableCard extends StatefulWidget {
  const ExpandableCard({
    required this.title,
    required this.content,
    super.key,
  });

  final String title;
  final Widget content;

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(widget.title),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: _toggleExpanded,
          ),
          if (_isExpanded) widget.content,
        ],
      ),
    );
  }
}
```

- **DON'T** use StatefulWidget for business logic (use BLoC/Cubit per `@state-management`).
```dart
// ❌ BAD - StatefulWidget managing business logic
class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<User> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers(); // ❌ Business logic in widget!
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    _users = await userRepository.getUsers(); // ❌ Direct repository call!
    setState(() => _isLoading = false);
  }
  // ...
}

// ✅ GOOD - Use BLoC/Cubit for business logic (see @state-management)
class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserListCubit(
        userRepository: context.repository.user, // ✅ Service locator
      )..loadUsers(),
      child: const UserListView(),
    );
  }
}
```

### Widget Composition

- **DO** compose complex UIs from small, focused widget classes.
```dart
// Good - Small, focused widgets (each <50 lines)
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    this.onTap,
    super.key,
  });

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(imageUrl: product.imageUrl),
            ProductInfo(product: product),
            ProductPrice(price: product.price),
          ],
        ),
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({required this.imageUrl, super.key});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
      ),
    );
  }
}

class ProductInfo extends StatelessWidget {
  const ProductInfo({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            product.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
```

- **AVOID** deeply nested widget trees without extraction.
```dart
// ❌ BAD - Deeply nested, hard to read and maintain
@override
Widget build(BuildContext context) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                child: Icon(Icons.person),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: TextStyle(fontSize: 18)),
                  Text(user.email, style: TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
          // ... 50 more lines
        ],
      ),
    ),
  );
}

// ✅ GOOD - Extracted into focused widget classes
@override
Widget build(BuildContext context) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          UserHeader(user: user),
          const SizedBox(height: 16),
          UserDetails(user: user),
          const SizedBox(height: 16),
          UserActions(user: user),
        ],
      ),
    ),
  );
}
```

### Widget Keys

- **DO** use keys for widgets in lists.
```dart
// Good - Keys for list items
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    final item = items[index];
    return ProductCard(
      key: ValueKey(item.id), // Use ValueKey with unique ID
      product: item,
    );
  },
);
```

- **DO** use GlobalKey when you need to access widget state from parent.
```dart
// Good - GlobalKey for form validation
class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final _formKey = GlobalKey<FormState>();

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // Submit form
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          EmailField(),
          PasswordField(),
          SubmitButton(onPressed: _handleSubmit),
        ],
      ),
    );
  }
}
```

## Performance Best Practices

### Const Constructors

- **DO** use const constructors EVERYWHERE possible.
```dart
// Good - Const constructor and const usage
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const FlutterLogo(size: 100);
  }
}

// Usage with const (widget won't rebuild unnecessarily)
const AppLogo();
```

- **DO** use const for widget trees that don't change.
```dart
// Good - Const widget tree
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Home'),
      actions: const [
        Icon(Icons.search),
        SizedBox(width: 8),
        Icon(Icons.settings),
      ],
    ),
    body: DynamicContent(), // Only this part rebuilds
  );
}
```

### List Performance

- **DO** use ListView.builder for long lists.
```dart
// Good - Builder for performance
ListView.builder(
  itemCount: users.length,
  itemBuilder: (context, index) {
    return UserCard(
      key: ValueKey(users[index].id),
      user: users[index],
    );
  },
);

// ❌ Bad - Creates all widgets at once
ListView(
  children: users.map((user) => UserCard(user: user)).toList(),
);
```

- **DO** use ListView.separated for lists with separators.
```dart
// Good - Separated builder
ListView.separated(
  itemCount: users.length,
  separatorBuilder: (context, index) => const Divider(),
  itemBuilder: (context, index) {
    return UserCard(user: users[index]);
  },
);
```

### Image Optimization

- **DO** use cached_network_image for network images.
```dart
// Good - Cached network images
CachedNetworkImage(
  imageUrl: product.imageUrl,
  placeholder: (context, url) => const ShimmerPlaceholder(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  fit: BoxFit.cover,
);
```

- **DO** specify image dimensions to avoid layout shifts.
```dart
// Good - Explicit dimensions
CachedNetworkImage(
  imageUrl: product.imageUrl,
  width: 200,
  height: 200,
  fit: BoxFit.cover,
);
```

### Build Optimization

- **DON'T** create widgets in variables within build method.
```dart
// ❌ BAD - Widget created in variable, rebuilt every time
@override
Widget build(BuildContext context) {
  final header = Container(
    child: Text('Header'),
  ); // ❌ Created on every build!

  return Column(children: [header, body]);
}

// ✅ GOOD - Widget class with const
@override
Widget build(BuildContext context) {
  return const Column(
    children: [
      HeaderWidget(), // Reusable const widget
      BodyWidget(),
    ],
  );
}
```

- **DO** split large build methods into widget classes.
```dart
// Good - Split into focused widgets
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProductAppBar(product: product),
      body: ProductDetailBody(product: product),
      bottomNavigationBar: ProductActions(product: product),
    );
  }
}
```

## VLE UI Package Guidelines

### Component Design

- **DO** create reusable, themed components in vle_ui package.
```dart
// packages/vle_ui/lib/src/buttons/vle_button.dart
class VleButton extends StatelessWidget {
  const VleButton({
    required this.text,
    required this.onPressed,
    this.variant = VleButtonVariant.primary,
    this.size = VleButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    super.key,
  });

  final String text;
  final VoidCallback? onPressed;
  final VleButtonVariant variant;
  final VleButtonSize size;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        style: _getButtonStyle(context),
        onPressed: isLoading ? null : onPressed,
        child: _buildChild(),
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        width: _getLoadingSize(),
        height: _getLoadingSize(),
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Text(text);
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    return switch (variant) {
      VleButtonVariant.primary => VleButtonStyles.primary(theme),
      VleButtonVariant.secondary => VleButtonStyles.secondary(theme),
      VleButtonVariant.outlined => VleButtonStyles.outlined(theme),
    };
  }

  double _getLoadingSize() => switch (size) {
    VleButtonSize.small => 16,
    VleButtonSize.medium => 20,
    VleButtonSize.large => 24,
  };
}

enum VleButtonVariant { primary, secondary, outlined }
enum VleButtonSize { small, medium, large }
```

### VLE UI Package Structure

```
packages/vle_ui/
└── lib/
    ├── src/
    │   ├── buttons/
    │   │   ├── vle_button.dart
    │   │   └── vle_icon_button.dart
    │   ├── cards/
    │   │   └── vle_card.dart
    │   ├── inputs/
    │   │   ├── vle_text_field.dart
    │   │   └── vle_dropdown.dart
    │   ├── theme/
    │   │   ├── vle_colors.dart
    │   │   ├── vle_text_styles.dart
    │   │   └── vle_theme.dart
    │   └── widgets/
    │       ├── vle_loading_indicator.dart
    │       └── vle_error_view.dart
    └── vle_ui.dart  // Export all components
```

- **DO** provide consistent theming across all VLE UI components.
```dart
// packages/vle_ui/lib/src/theme/vle_theme.dart
class VleTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: VleColors.lightColorScheme,
      textTheme: VleTextStyles.textTheme,
      elevatedButtonTheme: VleButtonStyles.elevatedButtonTheme,
      // ... other theme properties
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: VleColors.darkColorScheme,
      textTheme: VleTextStyles.textTheme,
      // ... other theme properties
    );
  }
}
```

## File Organization

### Screen Structure (Main App)

#### Standard Feature Structure

All features follow a consistent directory structure with barrel files for clean imports:

```
lib/screens/[feature_name]/
├── [feature_name].dart           # Barrel file - exports all public APIs
├── cubit/                        # State management (see @state-management)
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

// ✅ GOOD - lib/screens/billing/views/views.dart
export 'billing_screen.dart';
export 'invoice_item.dart';

// ✅ GOOD - lib/screens/billing/models/models.dart
export 'billing_detail_data.dart';
export 'invoice_status_helper.dart';

// ❌ BAD - No barrel file
// Forces consumers to know internal structure:
// import '../../screens/billing/views/billing_screen.dart';

// ✅ GOOD - With barrel files, clean imports:
// import 'package:learningos/screens/billing/billing.dart';
```

#### Route Configuration

Routes use `AppPageRoute` from `lib/components/route/`:

```dart
// lib/screens/[feature]/route/[feature]_route.dart
import 'package:learningos/components/route/app_page_route.dart';

class FeatureRoute extends AppPageRoute<FeatureData, FeatureResult> {
  FeatureRoute({
    required FeatureData data,
  }) : super(
          builder: (context) => BlocProvider(
            create: (context) => FeatureCubit(
              repository: context.repository.feature,
            ),
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

### Widget Class Naming

- **DO** use descriptive names that reflect purpose.
```dart
// Good - Clear purpose
class UserProfileHeader extends StatelessWidget {}
class CourseListItem extends StatelessWidget {}
class LoadingOverlay extends StatelessWidget {}

// Bad - Generic names
class Header extends StatelessWidget {}
class Item extends StatelessWidget {}
class Overlay extends StatelessWidget {}
```

## Best Practices Summary

### DO
- Use Widget classes instead of build methods for ALL reusable components
- Use const constructors wherever possible
- Use StatelessWidget by default
- Use StatefulWidget ONLY for local UI state (animations, controllers)
- Use BLoC/Cubit for business logic (see `@state-management`)
- Use ListView.builder for long lists
- Use CachedNetworkImage for network images
- Use keys for list items
- Split large widgets into smaller, focused widget classes
- Keep widgets under 200 lines
- Organize widgets by feature
- Use VLE UI components for consistent design

### DON'T
- Use build methods (_buildXxx) for reusable widgets with parameters
- Use StatefulWidget for business logic
- Create widgets in variables within build method
- Create deeply nested widget trees (>5 levels) without extraction
- Use ListView() constructor for long lists
- Skip keys in list items
- Ignore const optimization opportunities
- Hardcode strings (use localization per `@localization-guidelines`)

### PREFER
- Widget classes over build methods (always!)
- Composition over complex widgets
- Small, focused widgets over large monolithic widgets
- Named parameters for all widget constructors
- Extracting to widget class if >5 lines or has parameters
- VLE UI components over custom implementations

### AVOID
- Build methods with parameters
- Widgets larger than 200 lines
- Deep nesting without extraction
- Mixing business logic and UI
- Direct repository/service calls from widgets
- Ignoring performance best practices

## References

- [Flutter Official Documentation](https://flutter.dev/docs)
- [Flutter Performance Best Practices](https://flutter.dev/docs/perf/best-practices)
- [Material Design 3](https://m3.material.io/)
- See also: `@dart-coding-standards`, `@state-management`, `@clean-architecture`, `@testing-guidelines`, `@localization-guidelines`, `@project-structure`
