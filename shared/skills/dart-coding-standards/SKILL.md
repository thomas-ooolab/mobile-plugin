---
name: dart-coding-standards
description: "Dart coding standards and best practices for syntax and code style"
---

# Dart Coding Standards

This document provides comprehensive Dart coding standards based on Effective Dart guidelines and official Dart linter rules.

**Note**: This project uses FVM (Flutter Version Management). Always prefix Dart commands with `fvm dart`.

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
// ✅ GOOD - Modern Dart with patterns and named parameters
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

// ❌ BAD - Old verbose style
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

## Table of Contents
- [Dart Coding Standards](#dart-coding-standards)
  - [Key Principles](#key-principles)
    - [Modern Dart Features (Dart 3.0+)](#modern-dart-features-dart-30)
    - [Quick Examples](#quick-examples)
  - [Table of Contents](#table-of-contents)
  - [Naming Conventions](#naming-conventions)
    - [Classes, Enums, Typedefs, and Type Parameters](#classes-enums-typedefs-and-type-parameters)
    - [Libraries, Packages, Directories, and Source Files](#libraries-packages-directories-and-source-files)
    - [Import Prefixes](#import-prefixes)
    - [Variables, Constants, Parameters, and Named Parameters](#variables-constants-parameters-and-named-parameters)
    - [Private Members](#private-members)
    - [Unused Parameters and Wildcards](#unused-parameters-and-wildcards)
    - [Acronyms and Abbreviations](#acronyms-and-abbreviations)
  - [Code Style](#code-style)
    - [Formatting](#formatting)
    - [Declarations](#declarations)
    - [Collections](#collections)
    - [Strings](#strings)
  - [Documentation](#documentation)
    - [Comments](#comments)
  - [Usage Guidelines](#usage-guidelines)
    - [Constructors](#constructors)
    - [Functions](#functions)
    - [Variables](#variables)
    - [Types](#types)
    - [Parameters](#parameters)
      - [Named Parameters for Readability](#named-parameters-for-readability)
    - [Null Safety](#null-safety)
  - [Design Principles](#design-principles)
    - [Class Modifiers (Dart 3.0+)](#class-modifiers-dart-30)
      - [Sealed Classes](#sealed-classes)
      - [Final Classes](#final-classes)
      - [Base Classes](#base-classes)
      - [Interface Classes](#interface-classes)
      - [Mixin Classes](#mixin-classes)
      - [Choosing the Right Modifier](#choosing-the-right-modifier)
    - [Classes and Mixins](#classes-and-mixins)
    - [Getters and Setters](#getters-and-setters)
    - [Interfaces](#interfaces)
    - [Equality](#equality)
  - [Modern Dart Features](#modern-dart-features)
    - [Patterns and Pattern Matching](#patterns-and-pattern-matching)
      - [Destructuring Patterns](#destructuring-patterns)
      - [Switch Expressions and Patterns](#switch-expressions-and-patterns)
      - [Object Patterns](#object-patterns)
      - [Guard Clauses with Patterns](#guard-clauses-with-patterns)
      - [Logical Patterns](#logical-patterns)
      - [Pattern Matching in Variable Declarations](#pattern-matching-in-variable-declarations)
      - [Pattern Matching Best Practices](#pattern-matching-best-practices)
    - [Records](#records)
    - [Sealed Classes](#sealed-classes-1)
    - [Extension Methods](#extension-methods)
    - [Extension Types](#extension-types)
    - [Enums](#enums)
    - [Dot Shorthand](#dot-shorthand)
      - [Overview](#overview)
      - [Enums with Dot Shorthand](#enums-with-dot-shorthand)
      - [Static Members with Dot Shorthand](#static-members-with-dot-shorthand)
      - [Constructors with Dot Shorthand](#constructors-with-dot-shorthand)
      - [Equality Checks](#equality-checks)
      - [Expression Statement Restrictions](#expression-statement-restrictions)
      - [Return Statements and Switches](#return-statements-and-switches)
      - [Collection Initializers](#collection-initializers)
      - [Additional Patterns](#additional-patterns)
      - [Best Practices](#best-practices)
  - [Error Handling](#error-handling)
    - [Exceptions](#exceptions)
    - [Error Messages](#error-messages)
  - [Performance](#performance)
    - [Async/Await](#asyncawait)
    - [Strings](#strings-1)
    - [Collections](#collections-1)
  - [Best Practices Summary](#best-practices-summary)
    - [DO](#do)
    - [DON'T](#dont)
    - [PREFER](#prefer)
    - [AVOID](#avoid)
  - [References](#references)

## Naming Conventions

### Classes, Enums, Typedefs, and Type Parameters
- **DO** use `UpperCamelCase` for types.
```dart
// Good
class HomePage extends StatelessWidget {}
enum UserStatus { active, inactive }
typedef Predicate<T> = bool Function(T value);

// Bad
class homePage extends StatelessWidget {}
enum user_status { active, inactive }
```

### Libraries, Packages, Directories, and Source Files
- **DO** use `lowercase_with_underscores` for libraries, packages, directories, and source files.
```dart
// Good
library vector_math;
import 'slider_menu.dart';

// Bad
library VectorMath;
import 'SliderMenu.dart';
```

### Import Prefixes
- **DO** use `lowercase_with_underscores` for import prefixes.
```dart
// Good
import 'dart:math' as math;
import 'package:flutter/material.dart' as material;

// Bad
import 'dart:math' as Math;
import 'package:flutter/material.dart' as Material;
```

### Variables, Constants, Parameters, and Named Parameters
- **DO** use `lowerCamelCase` for variables, constants, parameters, and named parameters.
```dart
// Good
var itemCount = 3;
const maxValue = 255;
void sendMessage(String messageText) {}

// Bad
var item_count = 3;
const MAX_VALUE = 255;
void sendMessage(String message_text) {}
```

### Private Members
- **DO** start private declarations with an underscore.
```dart
// Good
class User {
  final String _userId;
  String _privateMethod() => _userId;
}

// Bad
class User {
  final String userId; // Not private
  String privateMethod() => userId; // Not private
}
```

### Unused Parameters and Wildcards
- **DO** use a **single** underscore `_` for unused variables, parameters, or callback arguments. The analyzer reports [unnecessary_underscores](https://dart.dev/tools/diagnostics/unnecessary_underscores) when multiple underscores (e.g. `__`) are used for an unused name.
```dart
// Good – single underscore for unused parameter
void callback(int _) {}
listener: (_, state) => doSomething(state),
BlocListener(..., listener: (context, _) => ...),

// Bad – multiple underscores trigger unnecessary_underscores
void callback(int __) {}
listener: (__, state) => doSomething(state),
```
Use one `_` per unused slot; you can repeat `_` for multiple unused parameters (e.g. `(_, _)`), but each name must be a single underscore, not `__`.

### Acronyms and Abbreviations
- **DO** capitalize acronyms and abbreviations longer than two letters like words.
```dart
// Good
class HttpConnection {}
class XmlParser {}
class IoStream {}

// Bad
class HTTPConnection {}
class XMLParser {}
class IOStream {}
```

## Code Style

### Formatting
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

### Declarations
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

### Collections
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

### Strings
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

## Documentation

### Comments
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

## Usage Guidelines

### Constructors

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

### Functions
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

### Variables
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

### Types
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

### Parameters

#### Named Parameters for Readability

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

### Null Safety
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

## Design Principles

### Class Modifiers (Dart 3.0+)

Dart 3.0 introduces class modifiers to control how classes can be extended, implemented, or mixed in. Use these modifiers to express your design intent clearly.

#### Sealed Classes

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

#### Final Classes

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
// class CustomId extends Identifier {} // ❌ Error
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

#### Base Classes

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
// class Cat extends Animal {} // ❌ Error
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

#### Interface Classes

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
// class CustomDataSource extends DataSource<User> {} // ❌ Error
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

#### Mixin Classes

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

#### Choosing the Right Modifier

| Modifier | Can Extend | Can Implement | Can Mixin | Use Case |
|----------|-----------|---------------|-----------|----------|
| `sealed` | ✅ (same library) | ❌ | ❌ | Exhaustive type checking, state machines |
| `final` | ❌ | ✅ | ❌ | Value objects, prevent subclassing |
| `base` | ✅ (must be base/final/sealed) | ❌ | ❌ | Controlled inheritance hierarchy |
| `interface` | ❌ | ✅ | ❌ | Pure contracts, dependency injection |
| `mixin class` | ✅ | ✅ | ✅ | Shared behavior, flexible reuse |
| `abstract` | ✅ | ✅ | ❌ | Abstract base classes |
| `abstract base` | ✅ (must be base/final/sealed) | ❌ | ❌ | Abstract with controlled inheritance |
| `abstract interface` | ❌ | ✅ | ❌ | Abstract contracts only |

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

### Classes and Mixins
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

### Getters and Setters
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

### Interfaces
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

### Equality
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

## Modern Dart Features

### Patterns and Pattern Matching

Dart 3.0+ introduces powerful pattern matching capabilities. Use them to write clearer, more concise code.

#### Destructuring Patterns

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

#### Switch Expressions and Patterns

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

#### Object Patterns

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

#### Guard Clauses with Patterns

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

#### Logical Patterns

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

#### Pattern Matching in Variable Declarations

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

#### Pattern Matching Best Practices

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

### Records
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

### Sealed Classes
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

### Extension Methods
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

### Extension Types
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

### Enums
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

### Dot Shorthand

#### Overview

Dot shorthands (Dart 3.10.0+) allow omitting explicit type names when accessing enum values, static members, or named constructors **if the surrounding context already conveys the type**. Use them to reduce noise without sacrificing clarity.  
Reference: [Dart Dot Shorthands Documentation](https://dart.dev/language/dot-shorthands)

#### Enums with Dot Shorthand

```dart
enum Color { red, green, blue }

Color myColor = .green; // ✅ Equivalent to Color.green

void setColor(Color color) {}
setColor(.red); // ✅ Parameter type supplies context

String getColorName(Color color) => switch (color) {
  .red => 'Red',
  .green => 'Green',
  .blue => 'Blue',
};

var myColor = .green;      // ❌ Error: no context type
final colors = [.red];     // ❌ Error: list type unknown
```

#### Static Members with Dot Shorthand

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

#### Constructors with Dot Shorthand

```dart
class Point {
  const Point(this.x, this.y);
  const Point.zero() : x = 0, y = 0;
  final double x;
  final double y;
}

Point origin = .zero();           // ✅ Type declared
List<Point> points = [.zero()];   // ✅ List has explicit type
Future<Point> fetch() async => .zero();

final origin = .zero();           // ❌ var lacks context
final points = [.zero()];         // ❌ Type inference fails
```

#### Equality Checks

Dot shorthand **must** appear on the right-hand side of `==`/`!=` so the left side can supply the context type.

```dart
if (status == .pending || status == .approved) {} // ✅
if (.pending == status) {}                        // ❌ Compilation error
```

#### Expression Statement Restrictions

Expression statements cannot start with a dot shorthand.

```dart
.log('Hello');   // ❌ Error: statement can't start with '.'
Logger.log('Hello'); // ✅ Use explicit type
```

#### Return Statements and Switches

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

#### Collection Initializers

Collections must declare their element type so the shorthand has context.

```dart
List<Priority> priorities = [.low, .medium, .high]; // ✅
Set<Priority> important = {.high, .medium};         // ✅

final priorities = [.low, .high]; // ❌ Type missing
```

#### Additional Patterns

- **Control flow:** `switch (status) { case .active: ... }`
- **Null coalescing / assertions:** `final mode = override ?? .system;`
- **Flutter builders:** `DropdownButton<Locale>(value: .english, ...)`
- **Maps with explicit value types:** `final Map<String, Theme> map = {'dark': .dark};`

#### Best Practices

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

## Error Handling

### Exceptions
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

### Error Messages
- **DO** provide helpful error messages.
```dart
// Good
throw ArgumentError(
  'Expected positive integer, got $value',
);

// Bad
throw ArgumentError('Invalid value');
```

## Performance

### Async/Await
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

### Strings
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

### Collections
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
