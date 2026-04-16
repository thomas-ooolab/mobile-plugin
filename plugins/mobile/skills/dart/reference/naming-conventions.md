# Naming Conventions

## Table of Contents
- [Classes, Enums, Typedefs, and Type Parameters](#classes-enums-typedefs-and-type-parameters)
- [Libraries, Packages, Directories, and Source Files](#libraries-packages-directories-and-source-files)
- [Import Prefixes](#import-prefixes)
- [Variables, Constants, Parameters, and Named Parameters](#variables-constants-parameters-and-named-parameters)
- [Private Members](#private-members)
- [Unused Parameters and Wildcards](#unused-parameters-and-wildcards)
- [Acronyms and Abbreviations](#acronyms-and-abbreviations)

## Classes, Enums, Typedefs, and Type Parameters
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

## Libraries, Packages, Directories, and Source Files
- **DO** use `lowercase_with_underscores` for libraries, packages, directories, and source files.
```dart
// Good
library vector_math;
import 'slider_menu.dart';

// Bad
library VectorMath;
import 'SliderMenu.dart';
```

## Import Prefixes
- **DO** use `lowercase_with_underscores` for import prefixes.
```dart
// Good
import 'dart:math' as math;
import 'package:flutter/material.dart' as material;

// Bad
import 'dart:math' as Math;
import 'package:flutter/material.dart' as Material;
```

## Variables, Constants, Parameters, and Named Parameters
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

## Private Members
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

## Unused Parameters and Wildcards
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

## Acronyms and Abbreviations
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
