# Performance Best Practices

## Table of Contents
- [Const Constructors](#const-constructors)
- [List Performance](#list-performance)
- [Image Optimization](#image-optimization)
- [Build Optimization](#build-optimization)

---

## Const Constructors

- **DO** use const constructors EVERYWHERE possible.
```dart
// Good - Const constructor and const usage
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return const FlutterLogo(size: 100);
  }
}

// Usage with const (widget won't rebuild unnecessarily)
const AppLogo();
```

- **DO** use const for widget trees that don't change.
```dart
// Good - Const widget tree
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Home'),
      actions: const [
        Icon(Icons.search),
        SizedBox(width: 8),
        Icon(Icons.settings),
      ],
    ),
    body: DynamicContent(), // Only this part rebuilds
  );
}
```

---

## List Performance

- **DO** use ListView.builder for long lists.
```dart
// Good - Builder for performance
ListView.builder(
  itemCount: users.length,
  itemBuilder: (context, index) {
    return UserCard(
      key: ValueKey(users[index].id),
      user: users[index],
    );
  },
);

// ❌ Bad - Creates all widgets at once
ListView(
  children: users.map((user) => UserCard(user: user)).toList(),
);
```

- **DO** use ListView.separated for lists with separators.
```dart
// Good - Separated builder
ListView.separated(
  itemCount: users.length,
  separatorBuilder: (context, index) => const Divider(),
  itemBuilder: (context, index) {
    return UserCard(user: users[index]);
  },
);
```

---

## Image Optimization

- **DO** use cached_network_image for network images.
```dart
// Good - Cached network images
CachedNetworkImage(
  imageUrl: product.imageUrl,
  placeholder: (context, url) => const ShimmerPlaceholder(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  fit: BoxFit.cover,
);
```

- **DO** specify image dimensions to avoid layout shifts.
```dart
// Good - Explicit dimensions
CachedNetworkImage(
  imageUrl: product.imageUrl,
  width: 200,
  height: 200,
  fit: BoxFit.cover,
);
```

---

## Build Optimization

- **DON'T** create widgets in variables within build method.
```dart
// ❌ BAD - Widget created in variable, rebuilt every time
@override
Widget build(BuildContext context) {
  final header = Container(
    child: Text('Header'),
  ); // ❌ Created on every build!

  return Column(children: [header, body]);
}

// ✅ GOOD - Widget class with const
@override
Widget build(BuildContext context) {
  return const Column(
    children: [
      HeaderWidget(), // Reusable const widget
      BodyWidget(),
    ],
  );
}
```

- **DO** split large build methods into widget classes.
```dart
// Good - Split into focused widgets
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ProductAppBar(product: product),
      body: ProductDetailBody(product: product),
      bottomNavigationBar: ProductActions(product: product),
    );
  }
}
```
