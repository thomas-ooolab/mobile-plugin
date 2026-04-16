# Error Handling & Performance

## Table of Contents
- [Error Handling — Exceptions](#error-handling--exceptions)
- [Error Messages](#error-messages)
- [Performance — Async/Await](#performance--asyncawait)
- [Performance — Strings](#performance--strings)
- [Performance — Collections](#performance--collections)
- [Best Practices Summary](#best-practices-summary)

## Error Handling — Exceptions
- **DO** use exceptions for exceptional conditions only.
```dart
// Good
class User {
  User(String email) {
    if (!email.contains('@')) {
      throw ArgumentError('Invalid email address');
    }
    _email = email;
  }
  late final String _email;
}

// Bad (using exceptions for control flow)
try {
  var user = findUser(id);
} catch (e) {
  user = User.guest();
}
```

- **DO** throw appropriate exception types.
```dart
// Good
if (index < 0 || index >= length) {
  throw RangeError.range(index, 0, length - 1);
}

if (file == null) {
  throw ArgumentError.notNull('file');
}

// Bad
if (index < 0 || index >= length) {
  throw Exception('Index out of range');
}
```

- **DO** use custom exception types for domain-specific errors.
```dart
// Good
class UserNotFoundException implements Exception {
  UserNotFoundException(this.userId);
  final String userId;

  @override
  String toString() => 'User not found: $userId';
}

// Usage
throw UserNotFoundException(userId);
```

## Error Messages
- **DO** provide helpful error messages.
```dart
// Good
throw ArgumentError(
  'Expected positive integer, got $value',
);

// Bad
throw ArgumentError('Invalid value');
```

## Performance — Async/Await
- **DON'T** use `async` when not needed.
```dart
// Good
Future<String> fetchData() {
  return api.getData();
}

// Bad (unnecessary async)
Future<String> fetchData() async {
  return await api.getData();
}
```

- **DO** use `async`/`await` for better error handling.
```dart
// Good
Future<void> processData() async {
  try {
    final data = await fetchData();
    await saveData(data);
  } catch (e) {
    handleError(e);
  }
}

// Bad (harder to handle errors)
Future<void> processData() {
  return fetchData()
      .then((data) => saveData(data))
      .catchError(handleError);
}
```

## Performance — Strings
- **DO** use `StringBuffer` for building strings in loops.
```dart
// Good
String buildLongString(List<String> items) {
  final buffer = StringBuffer();
  for (final item in items) {
    buffer.write(item);
  }
  return buffer.toString();
}

// Bad
String buildLongString(List<String> items) {
  var result = '';
  for (final item in items) {
    result += item;
  }
  return result;
}
```

## Performance — Collections
- **PREFER** using collection methods over manual loops.
```dart
// Good
final names = users.map((user) => user.name).toList();
final adults = users.where((user) => user.age >= 18).toList();
final total = prices.reduce((a, b) => a + b);

// Less preferred
final names = <String>[];
for (final user in users) {
  names.add(user.name);
}
```

## Best Practices Summary

### DO
- Use `UpperCamelCase` for types
- Use `lowerCamelCase` for members
- Use `lowercase_with_underscores` for libraries
- Format code with `fvm dart format`
- Document all public APIs
- Use collection literals
- Use `final` for variables that won't change
- Use tear-offs when possible
- Use destructuring patterns to extract multiple values at once
- Use record destructuring for multiple return values
- Use list/map destructuring patterns instead of manual indexing
- Use pattern matching in for-in loops
- Use switch expressions for pattern matching
- Use case patterns in switch statements
- Use object patterns for type checking and extraction
- Use when clauses (guards) for additional constraints
- Use records for multiple return values
- Use sealed classes for exhaustive type checking and state management
- Use `final` classes for value objects and to prevent inheritance
- Use `interface` classes for pure contracts and dependency injection
- Use `base` classes for controlled inheritance hierarchies
- Use `mixin class` for shared behavior that needs flexible reuse
- Use extension methods to add functionality
- Use extension types for zero-cost wrappers
- Use enhanced enums with members for rich enum types
- Use meaningful variable names
- Use named parameters for constructors (except simple cases)
- Use named parameters for methods with 2+ parameters
- Use `required` for essential named parameters
- Order parameters consistently (required first, optional with defaults last)

### DON'T
- Use `new` keyword
- Use `dynamic` unless necessary
- Pass arguments with default values
- Use positional boolean parameters
- Use `late` without good reason
- Use exceptions for control flow
- Use getters for expensive operations
- Redundantly annotate local variable types

### PREFER
- Making fields `final`
- Using const constructors when instantiating (when all arguments are compile-time constants)
- Using named parameters for all constructors with multiple fields
- Using named parameters for methods with multiple parameters
- Using named parameters when parameters have the same type
- Using `?.` and `??` for null safety
- Using collection methods over manual loops
- Using switch expressions over if-else chains for pattern matching
- Using destructuring patterns over manual property access
- Using pattern matching with sealed classes for exhaustive checking
- Using patterns in for-in loops for clearer iteration
- Using patterns over explicit type casts
- Using guard clauses (when) for complex conditions in patterns
- Using appropriate class modifiers to express design intent
- Using sealed classes for state management and API responses
- Using final classes for value objects and utility classes
- Using interface classes for repository/service contracts
- Using records over temporary classes for multiple return values
- Using extension types for type-safe wrappers without runtime overhead

### AVOID
- Redundant `const` keywords
- Using `var` when type isn't obvious
- Using `!` unless you're certain
- One-member abstract classes (use typedefs or extension methods)
- Positional parameters when meaning isn't immediately clear
- Manual property access when destructuring patterns are clearer
- Verbose if-else chains when switch expressions can be used
- Explicit type casts when patterns can handle type checking
- Creating temporary classes just for returning multiple values (use records)
- Manual indexing when list/map destructuring is available
- Using regular classes when sealed classes would provide exhaustive checking
- Extending classes that should be final
- Missing class modifiers when design intent should be explicit
- Complex inheritance hierarchies (prefer composition and mixins)

## References

- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Dart Linter Rules](https://dart.dev/tools/linter-rules)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Dart Patterns](https://dart.dev/language/patterns)
