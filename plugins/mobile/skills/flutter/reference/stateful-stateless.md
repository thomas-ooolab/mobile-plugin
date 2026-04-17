# StatelessWidget vs StatefulWidget

## StatelessWidget — prefer by default

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

## StatefulWidget — local UI state only

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

## StatefulWidget — never for business logic

- **DON'T** use StatefulWidget for business logic (use BLoC/Cubit per `@state`).
```dart
// BAD - StatefulWidget managing business logic
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
    _loadUsers(); // BAD: business logic in widget!
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    _users = await userRepository.getUsers(); // BAD: direct repository call!
    setState(() => _isLoading = false);
  }
  // ...
}

// GOOD - Use BLoC/Cubit for business logic (see @state)
class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserListCubit(
        userRepository: sl<UserRepository>(), // GOOD: service locator
      )..loadUsers(),
      child: const UserListView(),
    );
  }
}
```

## Decision rule

| Need | Widget type |
|------|-------------|
| Displays data, no local state | `StatelessWidget` |
| Local UI state (animation, controller, expand/collapse) | `StatefulWidget` |
| Business logic, API calls, shared state | BLoC/Cubit — never `StatefulWidget` |
