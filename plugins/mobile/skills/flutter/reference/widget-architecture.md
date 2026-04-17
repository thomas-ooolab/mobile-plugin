# Widget Architecture

## Table of Contents
- [Widget Classes vs Build Methods](#widget-classes-vs-build-methods)
- [StatelessWidget vs StatefulWidget](stateful-stateless.md)
- [Widget Composition & Keys](widget-composition.md)

---

## Widget Classes vs Build Methods

**CRITICAL RULE**: ALWAYS use Widget classes instead of build methods for reusable UI components.

### File Size Rule — 200-Line Limit

Keep every Dart widget file under 200 lines. If a file exceeds 200 lines, split it into focused files within the same folder.

```
// BAD — one file with everything
lib/screens/product/product_screen.dart  (450 lines)

// GOOD — split by responsibility
lib/screens/product/product_screen.dart       (main screen, ~60 lines)
lib/screens/product/product_header.dart       (header widget, ~80 lines)
lib/screens/product/product_details.dart      (details section, ~90 lines)
lib/screens/product/product_action_bar.dart   (bottom actions, ~50 lines)
```

Rules for splitting:
- Each file = one primary widget class (plus small private helpers used only in that file)
- Name file after the primary widget: `UserAvatar` → `user_avatar.dart`
- Keep split files in the same feature folder — do not create a `widgets/` subfolder unless shared across features
- Export split files from the folder's barrel file (`view.dart` or `model.dart`)

### Build Method — Split When Complex

When a `build` method grows too large or handles multiple distinct sections, split it:

1. **Prefer separate widget class** — use when the section has parameters, could be reused, or has meaningful independent state.
2. **Private build method** — only acceptable when the section is simple (≤15 lines), has no parameters, and is used exactly once.

```dart
// BAD — one monolithic build method
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      // 15 lines of appbar config
    ),
    body: Column(
      children: [
        // 25 lines of header section
        // 40 lines of content list
        // 20 lines of footer actions
      ],
    ),
  );
}

// GOOD — separate widget classes for complex sections
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: ProductAppBar(product: product),
    body: Column(
      children: [
        ProductHeader(product: product),
        ProductContentList(items: product.items),
        ProductFooterActions(product: product, onBuy: _handleBuy),
      ],
    ),
  );
}

// ACCEPTABLE — private build method only for simple, no-param, single-use sections
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      _buildDivider(),   // simple, no params, <5 lines — acceptable
      ProductDetails(product: product),
    ],
  );
}

Widget _buildDivider() => const Divider(height: 1, thickness: 1);
```

Decision rule:

| Section has params? | Reused elsewhere? | Complex (>15 lines)? | Action |
|---------------------|-------------------|----------------------|--------|
| Yes | — | — | Separate widget class |
| No | Yes | — | Separate widget class |
| No | No | Yes | Separate widget class |
| No | No | No | Private build method OK |

### Why Widget Classes Are Mandatory

- **DO** use Widget classes for ALL reusable UI components.
```dart
// GOOD - Widget class enables const optimization and hot reload
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
// BAD - Build method prevents const optimization and breaks hot reload
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

### Benefits of Widget Classes

1. **Performance**: Enable const constructors for unchanged widgets
2. **Hot Reload**: Better hot reload support and widget tree inspection
3. **DevTools**: Easier debugging in Flutter DevTools widget tree
4. **Testability**: Can test widgets in isolation with widget tests
5. **Reusability**: Clear interface with named parameters
6. **Type Safety**: Compile-time checking of parameters
7. **Documentation**: Self-documenting with named parameters and types

### When Build Methods Are Acceptable

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

---

## Reference

| Topic | File |
|-------|------|
| StatelessWidget vs StatefulWidget | [stateful-stateless.md](stateful-stateless.md) |
| Widget Composition & Keys | [widget-composition.md](widget-composition.md) |
