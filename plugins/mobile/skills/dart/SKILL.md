---
name: dart
description: "Dart naming, syntax, documentation, design principles, and modern language features. Use when writing Dart code, reviewing style, enforcing conventions, or using null safety and async patterns."
---

## Related Guidelines

- `@flutter` - Flutter widget patterns built on Dart
- `@state` - Cubit/BLoC patterns using Dart class features
- `@clean` - Architecture patterns enforced through Dart interfaces/abstractions

# Dart Coding Standards

This project uses FVM (Flutter Version Management). Always prefix Dart commands with `fvm dart`.

## Key Principles

### Documentation (Always Required)

Every public API **must** have a `///` doc comment. Every piece of non-obvious private logic **must** have an inline `//` comment explaining *why*, not *what*.

```dart
// GOOD: Public API — full dartdoc comment
/// Fetches the user's profile from the remote API.
///
/// Throws [NetworkException] if the device is offline.
/// Throws [AuthException] if the [token] has expired.
Future<UserProfile> fetchProfile({required String token}) async { ... }

// GOOD: Complex private logic — explain the why
// Cap at 30 s because the server rate-limits to 10 req/min; aggressive
// retries make the problem worse, so we back off to let the window reset.
Future<void> _retryWithBackoff(Future<void> Function() action) async { ... }

// BAD: No doc on a public method
Future<UserProfile> fetchProfile({required String token}) async { ... }
```

Reference: [dartdoc documentation](https://pub.dev/documentation/dartdoc/latest/) — full guide in [reference/code-style.md](reference/code-style.md#documentation--comments).

### Method Length — 100-Line Limit

Keep every method/function body under 100 lines. Extract cohesive steps into private helpers when exceeded.

```dart
// BAD — monolith method
Future<void> submitOrder(Order order) async {
  // validate (20 lines) + price (30 lines) + pay (40 lines) + notify (30 lines) ...
}

// GOOD — orchestrator + focused helpers
Future<void> submitOrder(Order order) async {
  _validateOrder(order);
  final pricing = await _calculatePricing(order);
  await _processPayment(order, pricing);
  await _sendConfirmation(order);
}
```

### Modern Dart Features (Dart 3.0+)
1. **Use Patterns and Destructuring** - Extract multiple values concisely
2. **Use Named Parameters** - Make constructors and methods self-documenting
3. **Use Switch Expressions** - Replace verbose if-else chains
4. **Use Records** - Return multiple values without creating classes
5. **Use Class Modifiers** - Express design intent with sealed, final, base, interface, mixin class
6. **Use Extension Types** - Create zero-cost wrappers with compile-time safety
7. **Use Enhanced Enums** - Add methods and properties to enums
8. **Use Dot Shorthand (Dart 3.10+)** - **Required** for all enum usages where context type is explicit (assignments, parameters, switch arms, collections, equality checks). Never write `EnumType.member` when context already provides the type.

### Memory: Prefer `late final` over `static const` for Object Collections

`static const` holds data in static memory for the app's entire lifetime. For collections containing non-primitive objects (widget configs, icon defs, etc.), use `late final` — initialized once per instance, freed when the object is GC'd.

```dart
// BAD — static storage lives forever, all _TabDef objects pinned in memory
static const _tabs = <_TabDef>[
  _TabDef(label: 'Home', icon: Icons.grid_view_rounded),
  _TabDef(label: 'Calls', icon: Icons.phone_outlined),
];

// GOOD — lazy, tied to instance lifecycle
late final _tabs = <_TabDef>[
  _TabDef(label: 'Home', icon: Icons.grid_view_rounded),
  _TabDef(label: 'Calls', icon: Icons.phone_outlined),
];
```

`static const` is fine for primitives (`static const int maxRetries = 3`) or true compile-time constants. Avoid it for object graphs.

### Quick Examples

```dart
// GOOD - Modern Dart with patterns and named parameters
class User {
  User({required this.name, required this.email, this.age});
  final String name;
  final String email;
  final int? age;
}

// Destructuring pattern
final User(:name, :email) = user;

// Switch expression with pattern
String message = switch (user) {
  User(age: var a) when a != null && a < 18 => 'Minor user',
  User(:final email) when email.endsWith('.edu') => 'Student user',
  _ => 'Regular user',
};

// Record for multiple returns
({String name, int age}) getUserInfo() => (name: 'John', age: 25);
final (:name, :age) = getUserInfo();

// Sealed class for exhaustive pattern matching
sealed class LoadState {}
class Loading extends LoadState {}
class Success extends LoadState {
  Success(this.data);
  final String data;
}
class Error extends LoadState {
  Error(this.message);
  final String message;
}

Widget build(LoadState state) => switch (state) {
  Loading() => CircularProgressIndicator(),
  Success(:final data) => Text(data),
  Error(:final message) => Text('Error: $message'),
};

// Interface class for dependency injection
interface class PaymentService {
  Future<bool> processPayment(Payment payment);
}

// BAD - Old verbose style
final name = user.name;
final email = user.email;

String message;
if (user.age != null && user.age! < 18) {
  message = 'Minor user';
} else if (user.email.endsWith('.edu')) {
  message = 'Student user';
} else {
  message = 'Regular user';
}

class UserInfo {
  UserInfo(this.name, this.age);
  final String name;
  final int age;
}
```

## Linting

This project uses `very_good_analysis` for strict linting. When creating or editing a `pubspec.yaml`, verify it is present — add if missing.

```yaml
# pubspec.yaml — always use latest version from pub.dev
dev_dependencies:
  very_good_analysis: ^<latest>  # check https://pub.dev/packages/very_good_analysis
```

```yaml
# analysis_options.yaml
include: package:very_good_analysis/analysis_options.yaml
```

## Reference

| Topic | File |
|-------|------|
| Naming conventions | [reference/naming-conventions.md](reference/naming-conventions.md) |
| Code style & documentation | [reference/code-style.md](reference/code-style.md) |
| Design principles & usage guidelines | [reference/design-principles.md](reference/design-principles.md) |
| Modern Dart features | [reference/modern-features.md](reference/modern-features.md) |
| Error handling & performance | [reference/error-handling.md](reference/error-handling.md) |
