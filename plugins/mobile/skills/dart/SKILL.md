---
name: dart
description: "Dart naming, syntax, documentation, design principles, and modern language features. Use when writing Dart code, reviewing style, enforcing conventions, or using null safety and async patterns."
---

# Dart Coding Standards

This project uses FVM (Flutter Version Management). Always prefix Dart commands with `fvm dart`.

## Key Principles

### Modern Dart Features (Dart 3.0+)
1. **Use Patterns and Destructuring** - Extract multiple values concisely
2. **Use Named Parameters** - Make constructors and methods self-documenting
3. **Use Switch Expressions** - Replace verbose if-else chains
4. **Use Records** - Return multiple values without creating classes
5. **Use Class Modifiers** - Express design intent with sealed, final, base, interface, mixin class
6. **Use Extension Types** - Create zero-cost wrappers with compile-time safety
7. **Use Enhanced Enums** - Add methods and properties to enums
8. **Use Dot Shorthand (Dart 3.10+)** - Eliminate redundant type names when the context already defines them

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

## Reference

| Topic | File |
|-------|------|
| Naming conventions | [reference/naming-conventions.md](reference/naming-conventions.md) |
| Code style & documentation | [reference/code-style.md](reference/code-style.md) |
| Design principles & usage guidelines | [reference/design-principles.md](reference/design-principles.md) |
| Modern Dart features | [reference/modern-features.md](reference/modern-features.md) |
| Error handling & performance | [reference/error-handling.md](reference/error-handling.md) |
