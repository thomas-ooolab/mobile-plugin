# Widget Composition & Keys

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
// BAD - Deeply nested, hard to read and maintain
@override
Widget build(BuildContext context) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(child: Icon(Icons.person)),
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

// GOOD - Extracted into focused widget classes
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
