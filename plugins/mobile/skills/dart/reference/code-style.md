# Code Style & Documentation

## Table of Contents
- [Formatting](#formatting)
- [Declarations](#declarations)
- [Collections](#collections)
- [Strings](#strings)
- [Documentation — Comments](#documentation--comments)

## Formatting
- **DO** format code using `fvm dart format`.
- **DO** limit lines to 80 characters when possible.
- **DO** use curly braces for all flow control statements.
```dart
// Good
if (condition) {
  doSomething();
}

// Bad (single-line without braces is error-prone)
if (condition) doSomething();
```

## Declarations
- **DO** declare return types for public APIs.
```dart
// Good
String getName() => _name;
Future<User> fetchUser() async => await api.getUser();

// Bad
getName() => _name;
fetchUser() async => await api.getUser();
```

- **DO** annotate when you intend to override a member.
```dart
// Good
@override
Widget build(BuildContext context) {
  return Container();
}
```

- **AVOID** redundant `const` keywords.
```dart
// Good
const SizedBox.shrink();
const [1, 2, 3];

// Bad
const SizedBox.shrink(child: const Text(''));
```

## Collections
- **DO** use collection literals when possible.
```dart
// Good
var points = <Point>[];
var addresses = <String, Address>{};
var counts = <int>{};

// Bad
var points = List<Point>();
var addresses = Map<String, Address>();
var counts = Set<int>();
```

- **DO** use `isEmpty` and `isNotEmpty` for collections.
```dart
// Good
if (items.isEmpty) return;
if (users.isNotEmpty) print(users);

// Bad
if (items.length == 0) return;
if (users.length > 0) print(users);
```

- **DO** use spread collections.
```dart
// Good
var combined = [...list1, ...list2];
var conditional = [
  item1,
  if (condition) item2,
  for (var item in items) item,
];

// Bad
var combined = List.from(list1)..addAll(list2);
```

## Strings
- **DO** use adjacent strings to concatenate string literals.
```dart
// Good
var message = 'This is a very long message that '
    'spans multiple lines for readability.';

// Bad
var message = 'This is a very long message that ' +
    'spans multiple lines for readability.';
```

- **DO** use interpolation to compose strings.
```dart
// Good
'Hello, $name! You are ${year - birth} years old.';

// Bad
'Hello, ' + name + '! You are ' + (year - birth).toString() + ' years old.';
```

- **AVOID** using curly braces in interpolation when not needed.
```dart
// Good
'Hi, $name!';

// Bad
'Hi, ${name}!';
```

## Documentation — Comments

- **DO** format comments like sentences (capitalize, end with period).
```dart
// Good
// Converts the user's name to uppercase.
String toUpperCase(String name) => name.toUpperCase();

// Bad
// converts the user's name to uppercase
String toUpperCase(String name) => name.toUpperCase();
```

- **DO** use `///` for doc comments.
```dart
/// Calculates the sum of two numbers.
///
/// Returns the sum of [a] and [b].
int add(int a, int b) => a + b;
```

- **DO** document all public APIs.
```dart
/// A user in the system.
///
/// Each user has a unique [id] and a [name].
class User {
  /// Creates a new user with the given [id] and [name].
  User(this.id, this.name);

  /// The unique identifier for this user.
  final String id;

  /// The user's display name.
  final String name;
}
```

- **CONSIDER** writing prose for doc comments.
```dart
// Good
/// Deletes the file at [path].
///
/// Throws an [IOError] if the file cannot be deleted.

// Bad
/// Deletes the file at [path] from disk.
```

- **DO** reference parameters and return values in doc comments using square brackets.
```dart
/// Sends a [message] to [recipient].
///
/// Returns `true` if the message was sent successfully.
bool sendMessage(String message, User recipient) {
  // ...
}
```
