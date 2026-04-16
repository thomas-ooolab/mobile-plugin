# Design Principles & Usage Guidelines

## Table of Contents
- [Constructors](#constructors)
- [Functions](#functions)
- [Variables](#variables)
- [Types](#types)
- [Parameters — Named Parameters for Readability](#parameters--named-parameters-for-readability)
- [Null Safety](#null-safety)
- [Class Modifiers (Dart 3.0+)](#class-modifiers-dart-30)
- [Classes and Mixins](#classes-and-mixins)
- [Getters and Setters](#getters-and-setters)
- [Interfaces](#interfaces)
- [Equality](#equality)

## Constructors

- **PREFER** using named parameters for constructors (improves readability and maintainability).
```dart
// Good - Named parameters are self-documenting
class User {
  User({
    required this.id,
    required this.name,
    this.email,
    this.isActive = true,
  });
  
  final String id;
  final String name;
  final String? email;
  final bool isActive;
}

// Usage is clear
final user = User(
  id: '123',
  name: 'John Doe',
  email: 'john@example.com',
);

// Less preferred - Positional parameters
class User {
  User(this.id, this.name, [this.email, this.isActive = true]);
  final String id;
  final String name;
  final String? email;
  final bool isActive;
}

// Usage is less clear
final user = User('123', 'John Doe', 'john@example.com');
```

- **DO** use initializing formals when possible.
```dart
// Good
class Product {
  Product({
    required this.id,
    required this.name,
    required this.price,
  });
  
  final String id;
  final String name;
  final double price;
}

// Bad
class Product {
  Product({
    required String id,
    required String name,
    required double price,
  }) : id = id,
       name = name,
       price = price;
  
  final String id;
  final String name;
  final double price;
}
```

- **DO** use `;` instead of `{}` for empty constructor bodies.
```dart
// Good
class User {
  User({required this.id, required this.name});
  
  final String id;
  final String name;
}

// Bad
class User {
  User({required this.id, required this.name}) {}
  
  final String id;
  final String name;
}
```

- **DON'T** use `new` keyword.
```dart
// Good
var user = User(id: '123', name: 'John');
var list = <int>[];

// Bad
var user = new User(id: '123', name: 'John');
var list = new List<int>();
```

- **PREFER** named constructors for alternative ways to create objects.
```dart
// Good
class Rectangle {
  Rectangle({
    required this.width,
    required this.height,
  });
  
  Rectangle.square({required double size})
      : width = size,
        height = size;
  
  Rectangle.fromSize({required Size size})
      : width = size.width,
        height = size.height;
  
  final double width;
  final double height;
}

// Usage is clear and self-documenting
final rect1 = Rectangle(width: 100, height: 50);
final rect2 = Rectangle.square(size: 50);
final rect3 = Rectangle.fromSize(size: Size(100, 50));
```

- **PREFER** using const constructors when instantiating (when all arguments are compile-time constants).
```dart
// Good - const when all arguments are constant
const padding = EdgeInsets.all(16);
const empty = SizedBox.shrink();
const point = Point(0, 0);
const userId = UserId(42);
return const Text('Hello');

// Good - const collections when elements are constant
const items = [1, 2, 3];
const map = {'a': 1, 'b': 2};

// Bad - omit const when arguments are not compile-time constant
final padding = EdgeInsets.all(16);  // Should be const
final text = Text(label);          // OK if label is variable; use const Text('literal') for literals

// When you cannot use const (runtime values)
final point = Point(x, y);         // x, y are variables
final widget = Padding(padding: edgeInsets, child: child);
```

Declare const constructors on your own classes when instances can be created at compile time (all fields final and constructor is const). When calling constructors—including framework widgets and value types—use the `const` keyword when every argument is a compile-time constant so the compiler can canonicalize instances and reduce allocations.

## Functions
- **DO** use a function declaration to bind a function to a name.
```dart
// Good
void sayHello() {
  print('Hello!');
}

// Bad
var sayHello = () {
  print('Hello!');
};
```

- **DO** use tear-offs when possible.
```dart
// Good
names.forEach(print);
users.map(toUpperCase);

// Bad
names.forEach((name) => print(name));
users.map((user) => toUpperCase(user));
```

- **DON'T** pass the argument if its value is the default.
```dart
// Good
Widget build(BuildContext context) {
  return Container();
}

// Bad
Widget build(BuildContext context) {
  return Container(
    width: null,
    height: null,
    child: null,
  );
}
```

- **DO** use `=>` for simple members.
```dart
// Good
String get fullName => '$firstName $lastName';
bool get isValid => email.isNotEmpty && password.length >= 8;

// Bad
String get fullName {
  return '$firstName $lastName';
}
```

## Variables
- **AVOID** using `var` when the type isn't obvious.
```dart
// Good
var name = 'John'; // Type is obvious (String)
final user = User(); // Type is obvious (User)
String title; // Type isn't obvious from initializer

// Bad (when type isn't obvious)
var title = getTitle(); // What type is returned?
```

- **DO** use `final` for variables that won't be reassigned.
```dart
// Good
final name = 'John';
final users = <User>[];

// Bad
var name = 'John'; // Never reassigned
```

- **AVOID** `late` variables if you can instead use lazy initialization.
```dart
// Good
final expensiveObject = () {
  // Compute once when first accessed
  return ExpensiveObject();
}();

// Bad (when lazy initialization would work)
late final expensiveObject = ExpensiveObject();
```

## Types
- **DO** type annotate public APIs.
```dart
// Good
String getUserName(int userId) {
  return users[userId]?.name ?? '';
}

// Bad
getUserName(userId) {
  return users[userId]?.name ?? '';
}
```

- **DON'T** redundantly type annotate initialized local variables.
```dart
// Good
var items = <String>[];
final user = User();

// Bad
List<String> items = <String>[];
User user = User();
```

- **DON'T** use `dynamic` unless you mean to disable type checking.
```dart
// Good (when you know the type)
Object value = getValue();

// Bad (when you know the type)
dynamic value = getValue();
```

- **DO** use `Future<void>` as the return type of asynchronous functions that don't produce values.
```dart
// Good
Future<void> saveData() async {
  await database.save(data);
}

// Bad
Future saveData() async {
  await database.save(data);
}
```

## Parameters — Named Parameters for Readability

- **PREFER** using named parameters for all constructor parameters (except single-parameter constructors).
```dart
// Good - Named parameters are clear and self-documenting
class User {
  User({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.isActive = true,
  });
  
  final String id;
  final String name;
  final String email;
  final int? age;
  final bool isActive;
}

// Usage is clear and readable
final user = User(
  id: '123',
  name: 'John Doe',
  email: 'john@example.com',
  age: 30,
);

// Bad - Positional parameters are unclear
class User {
  User(this.id, this.name, this.email, [this.age, this.isActive = true]);
  
  final String id;
  final String name;
  final String email;
  final int? age;
  final bool isActive;
}

// Usage is confusing - what does each parameter mean?
final user = User('123', 'John Doe', 'john@example.com', 30);
```

- **PREFER** using named parameters for methods with multiple parameters.
```dart
// Good - Named parameters improve readability
void updateUser({
  required String userId,
  required String name,
  String? email,
  int? age,
  bool notifyUser = false,
}) {
  // Implementation
}

// Usage is clear
updateUser(
  userId: '123',
  name: 'John Doe',
  email: 'john@example.com',
  notifyUser: true,
);

// Bad - Positional parameters reduce clarity
void updateUser(
  String userId,
  String name, [
  String? email,
  int? age,
  bool notifyUser = false,
]) {
  // Implementation
}

// Usage is unclear - what is true for?
updateUser('123', 'John Doe', 'john@example.com', null, true);
```

- **PREFER** using named parameters for methods with 2+ parameters (especially if they're the same type).
```dart
// Good
void createRectangle({
  required double width,
  required double height,
  Color? color,
}) {
  // Implementation
}

createRectangle(width: 100, height: 50);

// Bad - Easy to mix up parameters of the same type
void createRectangle(double width, double height, [Color? color]) {
  // Implementation
}

createRectangle(100, 50); // Which is width? Which is height?
```

- **DO** use named parameters for all boolean parameters.
```dart
// Good
Task({
  required this.title,
  this.isUrgent = false,
  this.isCompleted = false,
});

void fetchData({
  required String url,
  bool useCache = true,
  bool showLoader = false,
}) {}

// Bad - Boolean positional parameters are cryptic
Task(this.title, [this.isUrgent = false, this.isCompleted = false]);

void fetchData(String url, [bool useCache = true, bool showLoader = false]) {}

// Usage is unclear
fetchData('https://api.example.com', true, false); // What do these mean?
```

- **DO** use `required` for named parameters that are essential.
```dart
// Good - Required parameters are explicit
class Product {
  Product({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
  });
  
  final String id;
  final String name;
  final double price;
  final String? description;
  final String? imageUrl;
}

// Bad - Missing required parameters are not enforced
class Product {
  Product({
    this.id,
    this.name,
    this.price,
    this.description,
    this.imageUrl,
  });
  
  final String? id;
  final String? name;
  final double? price;
  final String? description;
  final String? imageUrl;
}
```

- **CONSIDER** using positional parameters only for:
  - Single-parameter constructors where meaning is obvious
  - Well-known patterns (e.g., `DateTime(year, month, day)`)
  - Private/internal APIs
```dart
// Acceptable - Single parameter with obvious meaning
class EmailAddress {
  EmailAddress(this.value);
  final String value;
}

// Acceptable - Well-established pattern
final date = DateTime(2024, 10, 23);

// Acceptable - Very simple constructors
class Point {
  Point(this.x, this.y);
  final double x;
  final double y;
}
```

- **DO** order parameters consistently: required named first, then optional named with defaults.
```dart
// Good
void sendMessage({
  required String to,
  required String subject,
  required String body,
  String? cc,
  String? bcc,
  bool isHtml = false,
  bool sendImmediately = true,
}) {}

// Bad - Inconsistent ordering
void sendMessage({
  bool isHtml = false,
  required String to,
  String? cc,
  required String subject,
  bool sendImmediately = true,
  required String body,
  String? bcc,
}) {}
```

## Null Safety
- **DO** use `??` to provide default values.
```dart
// Good
var name = userName ?? 'Guest';

// Bad
var name = userName != null ? userName : 'Guest';
```

- **DO** use `?.` for null-aware access.
```dart
// Good
var length = name?.length;

// Bad
var length = name == null ? null : name.length;
```

- **DO** use `!` only when you're certain a value is non-null.
```dart
// Good (when you're certain)
var user = userMap['id']!;

// Bad (when you're not certain)
var user = userMap['id']!; // May throw if null
```

- **AVOID** using `late` without a good reason.
```dart
// Good
final name = _computeName();

// Bad (when eager initialization works)
late final name = _computeName();
```

## Class Modifiers (Dart 3.0+)

Dart 3.0 introduces class modifiers to control how classes can be extended, implemented, or mixed in. Use these modifiers to express your design intent clearly.

### Sealed Classes

- **DO** use `sealed` classes for exhaustive type checking with pattern matching.
```dart
// Good - Compiler enforces handling all cases
sealed class Result<T> {}

class Success<T> extends Result<T> {
  Success(this.data);
  final T data;
}

class Failure<T> extends Result<T> {
  Failure(this.error);
  final String error;
}

class Loading<T> extends Result<T> {}

// Usage - compiler ensures all cases are covered
String getMessage<T>(Result<T> result) => switch (result) {
  Success(:final data) => 'Success: $data',
  Failure(:final error) => 'Error: $error',
  Loading() => 'Loading...',
  // No default needed - compiler knows all subtypes
};
```

- **PREFER** sealed classes for state management and API responses.
```dart
// Good - State management with sealed classes
sealed class AuthState {}
class Authenticated extends AuthState {
  Authenticated(this.user);
  final User user;
}
class Unauthenticated extends AuthState {}
class AuthLoading extends AuthState {}
class AuthError extends AuthState {
  AuthError(this.message);
  final String message;
}

// Usage is type-safe and exhaustive
Widget buildAuthUI(AuthState state) => switch (state) {
  Authenticated(:final user) => HomeScreen(user: user),
  Unauthenticated() => LoginScreen(),
  AuthLoading() => LoadingScreen(),
  AuthError(:final message) => ErrorScreen(message: message),
};
```

### Final Classes

- **DO** use `final` classes to prevent inheritance while allowing implementation.
```dart
// Good - Prevent subclassing but allow interface implementation
final class Identifier {
  Identifier(this.value);
  final String value;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Identifier && value == other.value;
  
  @override
  int get hashCode => value.hashCode;
}

// Can implement as interface
class UserId implements Identifier {
  UserId(this.value);
  @override
  final String value;
}

// Cannot extend
// class CustomId extends Identifier {} // Error
```

- **PREFER** final classes for value objects and utility classes.
```dart
// Good - Value objects should be final
final class Money {
  const Money(this.amount, this.currency);
  final double amount;
  final String currency;
  
  Money operator +(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Currency mismatch');
    }
    return Money(amount + other.amount, currency);
  }
}

// Good - Utility classes that shouldn't be extended
final class StringUtils {
  StringUtils._(); // Private constructor
  
  static String capitalize(String text) => 
      text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';
  
  static bool isEmail(String text) => text.contains('@');
}
```

### Base Classes

- **DO** use `base` classes when you want to enforce that any subclass must be a base, final, or sealed class.
```dart
// Good - Base class that enforces extension model
base class Animal {
  Animal(this.name);
  final String name;
  
  void makeSound() {
    print('$name makes a sound');
  }
}

// Must use base, final, or sealed when extending
base class Dog extends Animal {
  Dog(super.name);
  
  @override
  void makeSound() {
    print('$name barks');
  }
}

// Cannot use regular class
// class Cat extends Animal {} // Error
```

- **PREFER** base classes for framework classes that need controlled extension.
```dart
// Good - Framework base class
base class Repository<T> {
  Repository(this.dataSource);
  final DataSource<T> dataSource;
  
  Future<List<T>> getAll() => dataSource.fetchAll();
  Future<T?> getById(String id) => dataSource.fetchById(id);
  Future<void> save(T entity) => dataSource.save(entity);
}

// Implementations must be base, final, or sealed
final class UserRepository extends Repository<User> {
  UserRepository(super.dataSource);
  
  Future<User?> getByEmail(String email) async {
    final users = await getAll();
    return users.firstWhere((u) => u.email == email);
  }
}
```

### Interface Classes

- **DO** use `interface` classes when you want to define a contract without providing implementation.
```dart
// Good - Pure interface that can only be implemented
interface class DataSource<T> {
  Future<List<T>> fetchAll();
  Future<T?> fetchById(String id);
  Future<void> save(T entity);
  Future<void> delete(String id);
}

// Can implement
class ApiDataSource implements DataSource<User> {
  @override
  Future<List<User>> fetchAll() async {
    // API implementation
  }
  
  @override
  Future<User?> fetchById(String id) async {
    // API implementation
  }
  
  @override
  Future<void> save(User entity) async {
    // API implementation
  }
  
  @override
  Future<void> delete(String id) async {
    // API implementation
  }
}

// Cannot extend
// class CustomDataSource extends DataSource<User> {} // Error
```

- **PREFER** interface classes for repository contracts and service interfaces.
```dart
// Good - Service interface
interface class AuthService {
  Future<User> login({required String email, required String password});
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<void> resetPassword({required String email});
}

// Multiple implementations for different backends
class FirebaseAuthService implements AuthService {
  @override
  Future<User> login({required String email, required String password}) async {
    // Firebase implementation
  }
  // ... other methods
}

class MockAuthService implements AuthService {
  @override
  Future<User> login({required String email, required String password}) async {
    // Mock implementation for testing
  }
  // ... other methods
}
```

### Mixin Classes

- **DO** use `mixin class` when you want a class that can be both extended and mixed in.
```dart
// Good - Mixin class provides both class and mixin functionality
mixin class Timestamped {
  DateTime? createdAt;
  DateTime? updatedAt;
  
  void markCreated() {
    createdAt = DateTime.now();
  }
  
  void markUpdated() {
    updatedAt = DateTime.now();
  }
}

// Can be used as a mixin
class User with Timestamped {
  User(this.name);
  final String name;
}

// Can also be extended
class BaseEntity extends Timestamped {
  BaseEntity(this.id);
  final String id;
}
```

- **PREFER** mixin classes for shared behavior that should be reusable in multiple ways.
```dart
// Good - Validation mixin
mixin class Validatable {
  final List<String> _errors = [];
  
  List<String> get errors => List.unmodifiable(_errors);
  bool get isValid => _errors.isEmpty;
  
  void addError(String error) => _errors.add(error);
  void clearErrors() => _errors.clear();
  
  void validate() {
    clearErrors();
    performValidation();
  }
  
  void performValidation(); // Override in subclasses
}

// Can mixin
class UserForm with Validatable {
  String? email;
  String? password;
  
  @override
  void performValidation() {
    if (email == null || !email!.contains('@')) {
      addError('Invalid email');
    }
    if (password == null || password!.length < 8) {
      addError('Password must be at least 8 characters');
    }
  }
}
```

### Choosing the Right Modifier

| Modifier | Can Extend | Can Implement | Can Mixin | Use Case |
|----------|-----------|---------------|-----------|----------|
| `sealed` | Yes (same library) | No | No | Exhaustive type checking, state machines |
| `final` | No | Yes | No | Value objects, prevent subclassing |
| `base` | Yes (must be base/final/sealed) | No | No | Controlled inheritance hierarchy |
| `interface` | No | Yes | No | Pure contracts, dependency injection |
| `mixin class` | Yes | Yes | Yes | Shared behavior, flexible reuse |
| `abstract` | Yes | Yes | No | Abstract base classes |
| `abstract base` | Yes (must be base/final/sealed) | No | No | Abstract with controlled inheritance |
| `abstract interface` | No | Yes | No | Abstract contracts only |

```dart
// Decision tree examples

// Want exhaustive checking? Use sealed
sealed class NetworkState {}
class Connected extends NetworkState {}
class Disconnected extends NetworkState {}

// Want to prevent subclassing? Use final
final class UserId {
  const UserId(this.value);
  final String value;
}

// Want a pure contract? Use interface
interface class PaymentGateway {
  Future<PaymentResult> processPayment(Payment payment);
}

// Want controlled inheritance? Use base
base class Widget {
  void render() {}
}

// Want flexible reuse? Use mixin class
mixin class Loggable {
  void log(String message) => print(message);
}
```

## Classes and Mixins
- **DO** use mixins for shared behavior.
```dart
// Good
mixin Timestamped {
  DateTime? createdAt;
  DateTime? updatedAt;
}

class User with Timestamped {
  String name;
}

// Bad (duplication)
class User {
  String name;
  DateTime? createdAt;
  DateTime? updatedAt;
}
```

- **AVOID** defining a one-member abstract class when a simple function will do.
```dart
// Good
typedef Predicate<T> = bool Function(T value);

// Bad
abstract class Predicate<T> {
  bool test(T value);
}
```

- **DO** use factory constructors when you don't need to create a new instance.
```dart
// Good
class Logger {
  static final Map<String, Logger> _cache = {};

  factory Logger(String name) {
    return _cache.putIfAbsent(name, () => Logger._internal(name));
  }

  Logger._internal(this.name);
  final String name;
}
```

## Getters and Setters
- **PREFER** making fields and getters `final` or `const`.
```dart
// Good
class Circle {
  Circle(this.radius);
  final double radius;
}

// Bad (when immutability is possible)
class Circle {
  Circle(this.radius);
  double radius;
}
```

- **DON'T** use getters for operations that are computationally expensive.
```dart
// Good
double calculateArea() => pi * radius * radius;

// Bad (expensive operation as getter)
double get area => expensiveCalculation();
```

## Interfaces
- **DO** use abstract interface classes to define pure interfaces.
```dart
// Good
abstract interface class DataSource {
  Future<List<User>> getUsers();
  Future<void> saveUser(User user);
}

// Implementation
class ApiDataSource implements DataSource {
  @override
  Future<List<User>> getUsers() async {
    // Implementation
  }

  @override
  Future<void> saveUser(User user) async {
    // Implementation
  }
}
```

- **PREFER** defining interfaces with `abstract interface class` when you want to prevent implementations from being extended.

## Equality
- **DO** override `hashCode` if you override `==`.
```dart
// Good
class User {
  const User(this.id, this.name);
  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

- **CONSIDER** using `Equatable` package or code generation for equality.
```dart
// Good (using Equatable)
class User extends Equatable {
  const User(this.id, this.name);
  final String id;
  final String name;

  @override
  List<Object> get props => [id, name];
}
```
