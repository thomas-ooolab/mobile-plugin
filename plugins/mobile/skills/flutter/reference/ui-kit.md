# UI Kit Package Guidelines

## Table of Contents
- [Component Design](#component-design)
- [UI Kit Package Structure](#ui-kit-package-structure)
- [Theming](#theming)
- [Widget Class Naming](#widget-class-naming)

---

## Component Design

- **DO** create reusable, themed components in a dedicated UI kit package.
```dart
// packages/ui_kit/lib/src/buttons/app_button.dart
class AppButton extends StatelessWidget {
  const AppButton({
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    super.key,
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
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
      AppButtonVariant.primary => AppButtonStyles.primary(theme),
      AppButtonVariant.secondary => AppButtonStyles.secondary(theme),
      AppButtonVariant.outlined => AppButtonStyles.outlined(theme),
    };
  }

  double _getLoadingSize() => switch (size) {
    AppButtonSize.small => 16,
    AppButtonSize.medium => 20,
    AppButtonSize.large => 24,
  };
}

enum AppButtonVariant { primary, secondary, outlined }
enum AppButtonSize { small, medium, large }
```

---

## UI Kit Package Structure

```
packages/ui_kit/
└── lib/
    ├── src/
    │   ├── buttons/
    │   │   ├── app_button.dart
    │   │   └── app_icon_button.dart
    │   ├── cards/
    │   │   └── app_card.dart
    │   ├── inputs/
    │   │   ├── app_text_field.dart
    │   │   └── app_dropdown.dart
    │   ├── theme/
    │   │   ├── app_colors.dart
    │   │   ├── app_text_styles.dart
    │   │   └── app_theme.dart
    │   └── widgets/
    │       ├── app_loading_indicator.dart
    │       └── app_error_view.dart
    └── ui_kit.dart  // Export all components
```

---

## Theming

- **DO** provide consistent theming across all UI kit components.
```dart
// packages/ui_kit/lib/src/theme/app_theme.dart
class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColors.lightColorScheme,
      textTheme: AppTextStyles.textTheme,
      elevatedButtonTheme: AppButtonStyles.elevatedButtonTheme,
      // ... other theme properties
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColors.darkColorScheme,
      textTheme: AppTextStyles.textTheme,
      // ... other theme properties
    );
  }
}
```

---

## Widget Class Naming

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
