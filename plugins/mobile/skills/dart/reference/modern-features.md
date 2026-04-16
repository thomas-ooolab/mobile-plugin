# Modern Dart Features

## Table of Contents
- [Patterns and Pattern Matching](#patterns-and-pattern-matching)
  - [Destructuring Patterns](#destructuring-patterns)
  - [Switch Expressions and Patterns](#switch-expressions-and-patterns)
  - [Object Patterns](#object-patterns)
  - [Guard Clauses with Patterns](#guard-clauses-with-patterns)
  - [Logical Patterns](#logical-patterns)
  - [Pattern Matching in Variable Declarations](#pattern-matching-in-variable-declarations)
  - [Pattern Matching Best Practices](#pattern-matching-best-practices)
- [Records](#records)
- [Sealed Classes](#sealed-classes)
- [Extension Methods](#extension-methods)
- [Extension Types](#extension-types)
- [Enums](#enums)
- [Dot Shorthand](#dot-shorthand)

## Patterns and Pattern Matching

Dart 3.0+ introduces powerful pattern matching capabilities. Use them to write clearer, more concise code.

### Destructuring Patterns

- **PREFER** using destructuring patterns to extract multiple values at once.
```dart
// Good - Clear and concise
final User(:name, :email, :age) = user;
print('$name ($email) is $age years old');

// Good - With renaming
final User(name: userName, email: userEmail) = user;

// Good - Nested destructuring
final Response(data: User(:name, :email)) = response;

// Bad - Verbose and repetitive
final name = user.name;
final email = user.email;
final age = user.age;
print('$name ($email) is $age years old');
```

- **DO** use record destructuring for multiple return values.
```dart
// Good
(String, int) getUserInfo() => ('John', 25);

final (name, age) = getUserInfo();
print('$name is $age years old');

// Good - Named records
({String name, int age, String email}) getUserDetails() {
  return (name: 'John', age: 25, email: 'john@example.com');
}

final (:name, :age, :email) = getUserDetails();

// Bad - Creating a class just for return values
class UserInfo {
  UserInfo(this.name, this.age);
  final String name;
  final int age;
}

UserInfo getUserInfo() => UserInfo('John', 25);
final info = getUserInfo();
final name = info.name;
final age = info.age;
```

- **DO** use list/map destructuring patterns.
```dart
// Good - List destructuring
final [first, second, ...rest] = items;
final [x, y] = coordinates;

// Good - Map destructuring
final {'name': name, 'email': email} = userMap;

// Good - With type patterns
final [int x, int y, int z] = coordinates;

// Bad - Manual indexing
final first = items[0];
final second = items[1];
final rest = items.sublist(2);
```

- **PREFER** destructuring in for-in loops.
```dart
// Good - Clear iteration with destructuring
for (final (index, item) in items.indexed) {
  print('$index: $item');
}

// Good - Destructuring map entries
for (final MapEntry(key: name, value: email) in userMap.entries) {
  print('$name: $email');
}

// Good - Destructuring records
final coordinates = [(1, 2), (3, 4), (5, 6)];
for (final (x, y) in coordinates) {
  print('Point at $x, $y');
}

// Bad - Manual destructuring
for (final entry in userMap.entries) {
  final name = entry.key;
  final email = entry.value;
  print('$name: $email');
}
```

### Switch Expressions and Patterns

- **PREFER** switch expressions over if-else chains for pattern matching.
```dart
// Good - Concise and exhaustive
String describe(Object obj) => switch (obj) {
  int() => 'An integer',
  double() => 'A floating-point number',
  String() => 'A string',
  List() => 'A list',
  Map() => 'A map',
  _ => 'Something else',
};

// Good - With guards
String categorize(int age) => switch (age) {
  < 0 => 'Invalid',
  < 13 => 'Child',
  < 20 => 'Teenager',
  < 65 => 'Adult',
  _ => 'Senior',
};

// Bad - Verbose if-else chain
String describe(Object obj) {
  if (obj is int) return 'An integer';
  if (obj is double) return 'A floating-point number';
  if (obj is String) return 'A string';
  if (obj is List) return 'A list';
  if (obj is Map) return 'A map';
  return 'Something else';
}
```

- **DO** use pattern matching with destructuring in switch expressions.
```dart
// Good - Combining pattern matching and destructuring
String formatResponse(Object response) => switch (response) {
  Success(data: User(:name, :email)) => 'User: $name ($email)',
  Success(data: List(:length)) => 'Got $length items',
  Failure(:message) => 'Error: $message',
  _ => 'Unknown response',
};

// Good - With null patterns
String greet(String? name) => switch (name) {
  null => 'Hello, guest!',
  'Admin' => 'Hello, administrator!',
  var n when n.startsWith('Dr.') => 'Hello, $n!',
  _ => 'Hello, $name!',
};

// Bad - Verbose nested if statements
String formatResponse(Object response) {
  if (response is Success) {
    if (response.data is User) {
      final user = response.data as User;
      return 'User: ${user.name} (${user.email})';
    } else if (response.data is List) {
      return 'Got ${(response.data as List).length} items';
    }
  } else if (response is Failure) {
    return 'Error: ${response.message}';
  }
  return 'Unknown response';
}
```

- **DO** use case patterns in switch statements for side effects.
```dart
// Good - Pattern matching with actions
switch (event) {
  case UserLoggedIn(:final userId, :final timestamp):
    analytics.track('login', userId: userId, time: timestamp);
    
  case UserLoggedOut(:final userId):
    analytics.track('logout', userId: userId);
    
  case DataSynced(items: List(:final length)) when length > 0:
    print('Synced $length items');
    notifyUser('Sync complete');
    
  case ErrorOccurred(:final message):
    logger.error(message);
    showErrorDialog(message);
}

// Good - With multiple patterns
switch (value) {
  case null || '':
    print('Empty value');
  case 'yes' || 'y' || 'true':
    handleYes();
  case 'no' || 'n' || 'false':
    handleNo();
}
```

### Object Patterns

- **DO** use object patterns for type checking and extraction.
```dart
// Good - Type pattern with destructuring
if (response case Success(data: User(:final name, :final email))) {
  print('Logged in as $name ($email)');
}

// Good - Pattern in variable declarations
final User(:name, :email, isActive: active) = getUser();

// Good - Null-check with pattern
if (user case User(:final name, :final email)) {
  sendEmail(to: email, subject: 'Hello $name');
}

// Bad - Manual type checking and property access
if (response is Success && response.data is User) {
  final user = response.data as User;
  print('Logged in as ${user.name} (${user.email})');
}
```

### Guard Clauses with Patterns

- **DO** use when clauses for additional constraints.
```dart
// Good - Guard clauses make conditions explicit
String processUser(User user) => switch (user) {
  User(age: var a) when a < 18 => 'Minor user',
  User(age: var a) when a >= 65 => 'Senior user',
  User(:final subscriptionType) when subscriptionType == 'premium' 
    => 'Premium user',
  User(isActive: false) => 'Inactive user',
  _ => 'Regular user',
};

// Good - Complex conditions
String validateInput(String? input) => switch (input) {
  null || '' => 'Required field',
  String s when s.length < 3 => 'Too short',
  String s when s.length > 50 => 'Too long',
  String s when !s.contains('@') => 'Invalid email',
  _ => 'Valid',
};

// Bad - Nested ifs
String processUser(User user) {
  if (user.age < 18) return 'Minor user';
  if (user.age >= 65) return 'Senior user';
  if (user.subscriptionType == 'premium') return 'Premium user';
  if (!user.isActive) return 'Inactive user';
  return 'Regular user';
}
```

### Logical Patterns

- **DO** use logical-or patterns for multiple matches.
```dart
// Good - Logical OR
bool isSpecialCommand(String cmd) => switch (cmd) {
  'quit' || 'exit' || 'q' => true,
  'help' || 'h' || '?' => true,
  _ => false,
};

// Good - Logical AND with guard
String categorizeProduct(Product product) => switch (product) {
  Product(inStock: true, price: < 100) => 'Affordable and available',
  Product(inStock: true, price: >= 100) => 'Premium and available',
  Product(inStock: false) => 'Out of stock',
};

// Bad - Multiple conditions
bool isSpecialCommand(String cmd) {
  return cmd == 'quit' || cmd == 'exit' || cmd == 'q' ||
         cmd == 'help' || cmd == 'h' || cmd == '?';
}
```

### Pattern Matching in Variable Declarations

- **DO** use patterns in variable declarations for validation.
```dart
// Good - Pattern assignment with validation
void processCoordinates() {
  final [x, y, z] = getCoordinates(); // Ensures exactly 3 elements
  print('Position: $x, $y, $z');
}

// Good - With type checking
void processUser(Object data) {
  if (data case User(:final name, :final email)) {
    sendWelcomeEmail(name: name, email: email);
  }
}

// Good - Multiple patterns
final result = fetchData();
switch (result) {
  case Success(:final data):
    processData(data);
  case Failure(:final error):
    handleError(error);
  case Loading():
    showLoader();
}
```

### Pattern Matching Best Practices

- **PREFER** patterns over explicit type casts.
```dart
// Good
if (obj case List<int> numbers) {
  final sum = numbers.reduce((a, b) => a + b);
}

// Bad
if (obj is List<int>) {
  final numbers = obj as List<int>;
  final sum = numbers.reduce((a, b) => a + b);
}
```

- **PREFER** exhaustive pattern matching with sealed classes.
```dart
// Good - Compiler ensures all cases are covered
sealed class Result<T> {}
class Success<T> extends Result<T> {
  Success(this.data);
  final T data;
}
class Failure<T> extends Result<T> {
  Failure(this.error);
  final String error;
}

String handle(Result<String> result) => switch (result) {
  Success(:final data) => 'Success: $data',
  Failure(:final error) => 'Error: $error',
  // No default needed - all cases covered
};

// Bad - Missing cases possible
String handle(Result<String> result) {
  if (result is Success) {
    return 'Success: ${result.data}';
  } else if (result is Failure) {
    return 'Error: ${result.error}';
  }
  return 'Unknown'; // This case should not exist
}
```

## Records
- **DO** use records for multiple return values.
```dart
// Good
(String, int) getUserInfo() {
  return ('John', 25);
}

final (name, age) = getUserInfo();

// Bad
class UserInfo {
  UserInfo(this.name, this.age);
  final String name;
  final int age;
}

UserInfo getUserInfo() {
  return UserInfo('John', 25);
}
```

- **PREFER** named record fields for clarity.
```dart
// Good
({String name, int age}) getUserInfo() {
  return (name: 'John', age: 25);
}

final (:name, :age) = getUserInfo();

// Less clear
(String, int) getUserInfo() {
  return ('John', 25);
}
```

## Sealed Classes
- **DO** use sealed classes for exhaustive type checking.
```dart
// Good
sealed class Result<T> {}

class Success<T> extends Result<T> {
  Success(this.value);
  final T value;
}

class Failure<T> extends Result<T> {
  Failure(this.error);
  final String error;
}

// Usage with exhaustive checking
String getMessage(Result<String> result) {
  return switch (result) {
    Success(:final value) => value,
    Failure(:final error) => 'Error: $error',
    // No default needed - compiler knows all cases are covered
  };
}
```

## Extension Methods
- **DO** use extension methods to add functionality to existing types.
```dart
// Good
extension StringExtensions on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  bool get isValidEmail => contains('@') && contains('.');
}

// Usage
final name = 'john'.capitalize();
final valid = 'test@example.com'.isValidEmail;
```

## Extension Types
- **DO** use extension types for zero-cost wrappers.
```dart
// Good
extension type const EmailAddress(String value) {
  EmailAddress.from(String email) : value = email {
    if (!email.contains('@')) {
      throw ArgumentError('Invalid email');
    }
  }

  bool get isValid => value.contains('@') && value.contains('.');
}
```

## Enums
- **DO** use enhanced enums with members.
```dart
// Good
enum Status {
  pending(color: Colors.orange, icon: Icons.pending),
  active(color: Colors.green, icon: Icons.check),
  inactive(color: Colors.grey, icon: Icons.close);

  const Status({required this.color, required this.icon});
  final Color color;
  final IconData icon;
}

// Usage
final status = Status.active;
final color = status.color;
```

## Dot Shorthand

### Overview

Dot shorthands (Dart 3.10.0+) allow omitting explicit type names when accessing enum values, static members, or named constructors **if the surrounding context already conveys the type**. Use them to reduce noise without sacrificing clarity.  
Reference: [Dart Dot Shorthands Documentation](https://dart.dev/language/dot-shorthands)

### Enums with Dot Shorthand

```dart
enum Color { red, green, blue }

Color myColor = .green; // Equivalent to Color.green

void setColor(Color color) {}
setColor(.red); // Parameter type supplies context

String getColorName(Color color) => switch (color) {
  .red => 'Red',
  .green => 'Green',
  .blue => 'Blue',
};

var myColor = .green;      // Error: no context type
final colors = [.red];     // Error: list type unknown
```

### Static Members with Dot Shorthand

```dart
class Logger {
  static void log(String message) {}
  static void error(String message) {}
}

void useLogger(Function(String) action) {
  action('Hello');
}

useLogger(Logger.log); // Full reference when passing tear-offs

final void Function(String) info = Logger.log;
info('Hi'); // Invoke via variable

// Dot shorthand usable only when a static context type is explicit:
final int port = .parse('8080'); // int.parse
```

> **Note:** Instance members still require the receiver (`logger.log('hi')`). Constructors like `EdgeInsets.all()` generally need the explicit class name because the expression itself provides the context.

### Constructors with Dot Shorthand

```dart
class Point {
  const Point(this.x, this.y);
  const Point.zero() : x = 0, y = 0;
  final double x;
  final double y;
}

Point origin = .zero();           // Type declared
List<Point> points = [.zero()];   // List has explicit type
Future<Point> fetch() async => .zero();

final origin = .zero();           // Error: var lacks context
final points = [.zero()];         // Error: Type inference fails
```

### Equality Checks

Dot shorthand **must** appear on the right-hand side of `==`/`!=` so the left side can supply the context type.

```dart
if (status == .pending || status == .approved) {} // OK
if (.pending == status) {}                        // Compilation error
```

### Expression Statement Restrictions

Expression statements cannot start with a dot shorthand.

```dart
.log('Hello');   // Error: statement can't start with '.'
Logger.log('Hello'); // Use explicit type
```

### Return Statements and Switches

Return type provides context, so dot shorthand works naturally.

```dart
ApiResponse handle() {
  return .success;
}

ApiResponse process() => switch (data) {
  _ when isValid => .success,
  _ => .error,
};
```

### Collection Initializers

Collections must declare their element type so the shorthand has context.

```dart
List<Priority> priorities = [.low, .medium, .high]; // OK
Set<Priority> important = {.high, .medium};         // OK

final priorities = [.low, .high]; // Error: Type missing
```

### Additional Patterns

- **Control flow:** `switch (status) { case .active: ... }`
- **Null coalescing / assertions:** `final mode = override ?? .system;`
- **Flutter builders:** `DropdownButton<Locale>(value: .english, ...)`
- **Maps with explicit value types:** `final Map<String, Theme> map = {'dark': .dark};`

### Best Practices

**DO**
- Use dot shorthand when the variable, parameter, or return type is explicit.
- Prefer it in switch expressions/statements and typed collections.
- Keep shorthands on the right of equality checks.

**DON'T**
- Start statements with dot shorthand.
- Use it with `var` when the type cannot be inferred.
- Place it where multiple types could match or readability suffers.

**Use dot shorthand when** the type context is explicit, unambiguous, and clarity improves.  
**Avoid it when** inference would fail or teammates might struggle to see the underlying type.
