# Code Style & Documentation

## Table of Contents
- [Formatting](#formatting)
- [Declarations](#declarations)
- [Collections](#collections)
- [Strings](#strings)
- [Documentation — Comments](#documentation--comments)
  - [When to document](#when-to-document)
  - [Format rules](#format-rules)
  - [Cross-references with `[SymbolName]`](#cross-references-with-symbolname)
  - [Parameters, return values, and exceptions](#parameters-return-values-and-exceptions)
  - [Documenting classes](#documenting-classes)
  - [Documenting complex private logic](#documenting-complex-private-logic)
  - [Reusable doc templates](#reusable-doc-templates-with-template--macro)
  - [Code examples in docs](#code-examples-in-docs)
  - [`{@nodoc}` — exclude from generated docs](#nodoc--exclude-from-generated-docs)
  - [Summary checklist](#summary-checklist)

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

Reference: [dartdoc documentation](https://pub.dev/documentation/dartdoc/latest/)

### When to document

- **ALWAYS** document every public API — classes, constructors, fields, methods, getters, typedefs, and top-level functions.
- **ALWAYS** document complex private logic — non-obvious algorithms, workarounds, invariants, or state machines, even when private.
- **DO NOT** document trivial private helpers when the name + types are self-explanatory.

### Format rules

- **DO** use `///` triple-slash for all doc comments (never `/** */`).
- **DO** format comments like sentences — capitalize first word, end with period.
- **DO** write the first sentence as a standalone summary; dartdoc uses it as hover text and the API index entry.
- **DO** separate the summary from the body with a blank `///` line.

```dart
// Good
/// Authenticates the user with the given credentials.
///
/// Throws [AuthException] if the credentials are invalid or the
/// session has expired. Returns the authenticated [User] on success.
Future<User> login({required String email, required String password}) async { ... }

// Bad — no doc, vague name forces readers to read the body
Future<User> doLogin(String e, String p) async { ... }
```

### Cross-references with `[SymbolName]`

Use `[SymbolName]` to link to any Dart identifier — dartdoc resolves it to the correct API page.

```dart
/// Converts this [User] to a [UserDto] for API serialization.
///
/// See also [UserDto.fromUser] for the reverse conversion.
UserDto toDto() => UserDto.fromUser(this);
```

Supported link targets:

| Target | Syntax |
|--------|--------|
| Class / enum / typedef | `[ClassName]` |
| Constructor | `[ClassName.new]` or `[ClassName.namedCtor]` |
| Method / getter | `[methodName]` or `[ClassName.methodName]` |
| Top-level function | `[functionName]` |
| Parameter (inline only) | `[paramName]` |
| External URL | `[label](https://...)` |

### Parameters, return values, and exceptions

- Reference parameters inline using `[paramName]`.
- Describe the return value in prose — don't use a `@returns` tag.
- List every exception the caller may need to handle under a "Throws" paragraph.

```dart
/// Sends [message] to [recipient].
///
/// Returns `true` if the message was delivered immediately, or
/// `false` if it was queued for retry.
///
/// Throws [NetworkException] if no connection is available.
/// Throws [ArgumentError] if [message] is empty.
bool sendMessage(String message, User recipient) { ... }
```

### Documenting classes

Every public class needs: a summary sentence, what it represents or does, and links to related types.

```dart
/// A paginated list of [User] records returned by the API.
///
/// Iterate directly or use [hasNextPage] and [fetchNextPage] to
/// load additional results lazily.
///
/// See also:
/// - [UserRepository] which produces [UserPage] instances
/// - [PagedListView] for rendering in UI
class UserPage {
  /// Creates a page from raw [items] and an optional [nextCursor].
  UserPage({required this.items, this.nextCursor});

  /// The users on this page.
  final List<User> items;

  /// Cursor used to fetch the next page, or `null` if this is the last page.
  final String? nextCursor;

  /// Whether more pages are available.
  bool get hasNextPage => nextCursor != null;
}
```

### Documenting complex private logic

Private members don't generate API docs, but non-obvious logic still needs inline explanation using `//` comments. Document the *why*, not the *what*.

```dart
// Retry with exponential backoff capped at 30 s. The server enforces a
// per-IP rate limit of 10 req/min, so aggressive retries make the
// problem worse — backing off gives the limit window time to reset.
Future<void> _retryWithBackoff(Future<void> Function() action) async {
  var delay = const Duration(seconds: 1);
  for (var attempt = 0; attempt < _maxRetries; attempt++) {
    try {
      await action();
      return;
    } on RateLimitException {
      await Future<void>.delayed(delay);
      delay = Duration(seconds: (delay.inSeconds * 2).clamp(1, 30));
    }
  }
}
```

### Reusable doc templates with `{@template}` / `{@macro}`

Use `{@template}` to define a snippet once and `{@macro}` to embed it elsewhere — avoids copy-paste drift in shared error descriptions or parameter notes.

```dart
/// {@template auth_token_note}
/// The [token] must be a non-expired JWT issued by the auth service.
/// Obtain one via [AuthService.login].
/// {@endtemplate}

/// Fetches the current user's profile.
///
/// {@macro auth_token_note}
Future<UserProfile> getProfile({required String token}) async { ... }

/// Updates the current user's display name.
///
/// {@macro auth_token_note}
Future<void> updateName({required String token, required String name}) async { ... }
```

### Code examples in docs

Use fenced ` ```dart ` blocks for inline examples. Keep them minimal and runnable.

```dart
/// Parses an ISO 8601 date string into a [DateTime].
///
/// Example:
/// ```dart
/// final date = parseDate('2024-10-23');
/// print(date.year); // 2024
/// ```
///
/// Throws [FormatException] if [input] is not a valid ISO 8601 string.
DateTime parseDate(String input) { ... }
```

### `{@nodoc}` — exclude from generated docs

Use `{@nodoc}` on public members that are public only for technical reasons (e.g., generated code plumbing) and should not appear in the API reference.

```dart
/// {@nodoc}
// ignore: public_member_api_docs
void $internalBootstrap() { ... }
```

### Summary checklist

| What | Required doc |
|------|-------------|
| Public class | Summary + fields + constructor |
| Public method / function | Summary + params + return + throws |
| Public getter / setter | One-line summary |
| Public typedef | What it represents |
| Complex private method | `//` inline comment explaining why |
| Trivial private helper | None required |
