# Widget Architecture

## Table of Contents
- [Widget Classes vs Build Methods](#widget-classes-vs-build-methods)
- [StatelessWidget vs StatefulWidget](#statelesswidget-vs-statefulwidget)
- [Widget Composition](#widget-composition)
- [Widget Keys](#widget-keys)

---

## Widget Classes vs Build Methods

**CRITICAL RULE**: ALWAYS use Widget classes instead of build methods for reusable UI components.

### Why Widget Classes Are Mandatory

- **DO** use Widget classes for ALL reusable UI components.
```dart
// ✅ GOOD - Widget class enables const optimization and hot reload
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
// ❌ BAD - Build method prevents const optimization and breaks hot reload
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

## StatelessWidget vs StatefulWidget

- **PREFER** StatelessWidget when widget doesn't need mutable state.
```dart
// Good - Stateless for immutable widgets
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.imageUrl,
    this.radius = 20,
    super.key,
  });

  final String imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: NetworkImage(imageUrl),
    );
  }
}
```

- **DO** use StatefulWidget ONLY for local UI state (animations, form controllers, scroll controllers).
```dart
// Good - Stateful for local UI state only
class ExpandableCard extends StatefulWidget {
  const ExpandableCard({
    required this.title,
    required this.content,
    super.key,
  });

  final String title;
  final Widget content;

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(widget.title),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
            ),
            onTap: _toggleExpanded,
          ),
          if (_isExpanded) widget.content,
        ],
      ),
    );
  }
}
```

- **DON'T** use StatefulWidget for business logic (use BLoC/Cubit per `@state`).
```dart
// ❌ BAD - StatefulWidget managing business logic
class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<User> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers(); // ❌ Business logic in widget!
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    _users = await userRepository.getUsers(); // ❌ Direct repository call!
    setState(() => _isLoading = false);
  }
  // ...
}

// ✅ GOOD - Use BLoC/Cubit for business logic (see @state)
class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserListCubit(
        userRepository: sl<UserRepository>(), // ✅ Service locator
      )..loadUsers(),
      child: const UserListView(),
    );
  }
}
```

---

## Widget Composition

- **DO** compose complex UIs from small, focused widget classes.
```dart
// Good - Small, focused widgets (each <50 lines)
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    this.onTap,
    super.key,
  });

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(imageUrl: product.imageUrl),
            ProductInfo(product: product),
            ProductPrice(price: product.price),
          ],
        ),
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({required this.imageUrl, super.key});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
      ),
    );
  }
}

class ProductInfo extends StatelessWidget {
  const ProductInfo({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            product.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
```

- **AVOID** deeply nested widget trees without extraction.
```dart
// ❌ BAD - Deeply nested, hard to read and maintain
@override
Widget build(BuildContext context) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                child: Icon(Icons.person),
              ),
              SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: TextStyle(fontSize: 18)),
                  Text(user.email, style: TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
          // ... 50 more lines
        ],
      ),
    ),
  );
}

// ✅ GOOD - Extracted into focused widget classes
@override
Widget build(BuildContext context) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          UserHeader(user: user),
          const SizedBox(height: 16),
          UserDetails(user: user),
          const SizedBox(height: 16),
          UserActions(user: user),
        ],
      ),
    ),
  );
}
```

---

## Widget Keys

- **DO** use keys for widgets in lists.
```dart
// Good - Keys for list items
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    final item = items[index];
    return ProductCard(
      key: ValueKey(item.id), // Use ValueKey with unique ID
      product: item,
    );
  },
);
```

- **DO** use GlobalKey when you need to access widget state from parent.
```dart
// Good - GlobalKey for form validation
class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final _formKey = GlobalKey<FormState>();

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // Submit form
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          EmailField(),
          PasswordField(),
          SubmitButton(onPressed: _handleSubmit),
        ],
      ),
    );
  }
}
```
