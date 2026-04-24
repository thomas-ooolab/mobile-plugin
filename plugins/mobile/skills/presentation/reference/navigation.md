# Navigation Reference

## AppPageRoute

`AppPageRoute<Data, Result>` extends `MaterialPageRoute<Result>`.

```dart
abstract base class AppPageRoute<
  Data extends RouteData?,
  Result extends Object?
> extends MaterialPageRoute<Result>
```

**Constructor params:**

| Param | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `path` | `String` | yes | — | Sets `RouteSettings.name`; used for analytics and `isCurrentRoute` |
| `builder` | `WidgetBuilder` | yes | — | Receives `BuildContext`; build screen here |
| `data` | `Data?` | no | `null` | Injected via `Provider<RouteData?>` — read with `context.arguments<Data>()` |
| `enableTransition` | `bool` | no | `true` | `false` = no forward animation; back animation always plays |
| `isUsingRootNavigator` | `bool` | no | `false` | `true` = pushes above tab bar / bottom nav |

**Pattern:**

```dart
// screens/feature/feature_route.dart
import 'package:app/components/route/route.dart';

class FeatureRoute extends AppPageRoute<FeatureData, FeatureResult> {
  FeatureRoute({required FeatureData data})
      : super(
          path: '/feature-name',
          builder: (_) => BlocProvider(
            create: (_) => sl<FeatureCubit>(),
            child: const FeatureScreen(),
          ),
          data: data,
        );
}
```

---

## RouteData

Base class for route input data. Extend it to pass typed data to a route.

```dart
abstract base class RouteData {
  const RouteData();
  Map<String, String>? toMap() => null; // override for analytics params
}
```

**Pattern:**

```dart
// feature_route.dart (same file as FeatureRoute, or separate)
class FeatureData extends RouteData {
  const FeatureData({required this.id});
  final String id;

  @override
  Map<String, String>? toMap() => {'id': id};
}
```

Read inside any widget below the route:

```dart
final data = context.arguments<FeatureData>(); // nullable — null when no data passed
```

---

## NavigatorExtension

All navigation is via `BuildContext` extension methods. Import `route.dart`.

### Push

```dart
// Push a new route — returns Result? when popped
final result = await context.push(FeatureRoute(data: data));
```

### Push Replacement

```dart
// Replace current route with new route — current route removed once new one animates in
// routeResult is returned to the screen that pushed the current one
await context.pushReplacement(
  FeatureRoute(data: data),
  routeResult: someResult, // optional — returned to previous screen
);
```

### Pop

```dart
// Pop the top-most route
context.pop();

// Pop with a result (returned to the caller of push)
context.pop(routeResult: FeatureResult(success: true));

// Pop using root navigator (e.g. dismiss a root-level dialog)
context.pop(rootNavigator: true);
```

### Push to First

Pushes new route and removes all routes except the first (initial) route.
Use for flows that return to home after completion.

```dart
context.pushToFirst(HomeRoute());
```

### Push to Top

Pushes new route and removes **all** existing routes.
Use for hard resets — e.g. logout → login, or deep-link landing that clears history.

```dart
context.pushToTop(LoginRoute());
```

### Pop Until Route or First

Pops routes until the target route is on top, or until the stack's first route.

```dart
// Pop until DashboardRoute is on top
context.popUntilRouteOrFirst(expectedRoute: dashboardRoute);

// Pop all the way to the first route
context.popUntilRouteOrFirst();
```

### Pop Until Predicate

```dart
context.popUntil((route) => route.settings.name == '/home');
```

### Check Current Route

```dart
final route = FeatureRoute(data: data);
if (context.isCurrentRoute(route)) {
  // this route is on top of the stack
}
```

---

## AppRouteObserver

Tracks navigation for analytics (Firebase) and Microsoft Clarity. Registered at app root.

- Fires `analyticsRepository.trackRoute(screenName, parameters)` on push, replace, and pop-back
- `parameters` comes from `RouteData.toMap()` — override it to pass screen-specific dimensions
- Fires `Clarity.setCurrentScreenName(screenName)` on each screen change

Register in `MaterialApp`:

```dart
MaterialApp(
  navigatorObservers: [sl<AppRouteObserver>()],
  ...
)
```

`AppRouteObserver` is a `@singleton` — resolve via `sl<AppRouteObserver>()`.
