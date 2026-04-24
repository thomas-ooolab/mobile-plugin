# Navigation Reference

## Base Class Implementations

### AppPageRoute

```dart
// components/route/app_page_route.dart
import 'package:flutter/material.dart';
import 'package:app/components/route/route_data.dart';
import 'package:provider/provider.dart';

abstract base class AppPageRoute<
  Data extends RouteData?,
  Result extends Object?
> extends MaterialPageRoute<Result> {
  AppPageRoute({
    required WidgetBuilder builder,
    required this.path,
    this.enableTransition = true,
    Data? data,
    this.isUsingRootNavigator = false,
  }) : super(
         builder: (context) =>
             Provider<RouteData?>.value(value: data, child: builder(context)),
         settings: RouteSettings(name: path, arguments: data),
       );

  final bool enableTransition;
  final String path;
  final bool isUsingRootNavigator;

  @override
  Duration get transitionDuration =>
      enableTransition ? super.transitionDuration : Duration.zero;

  @override
  Duration get reverseTransitionDuration => enableTransition
      ? super.reverseTransitionDuration
      : const Duration(milliseconds: 300);
}
```

### RouteData

```dart
// components/route/route_data.dart
abstract base class RouteData {
  const RouteData();
  Map<String, String>? toMap() => null;
}
```

### NavigatorExtension

```dart
// components/route/navigator.dart
extension NavigatorExtension on BuildContext {
  NavigatorState _navState({bool? rootNavigator}) =>
      Navigator.of(this, rootNavigator: rootNavigator ?? false);

  Future<Result?> push<Result extends Object?>(
    AppPageRoute<RouteData?, Result> route,
  ) => _navState(rootNavigator: route.isUsingRootNavigator).push(route);

  Future<Result?> pushReplacement<Result extends Object?, ResultTO extends Object?>(
    AppPageRoute<RouteData?, Result> route, {
    ResultTO? routeResult,
  }) => _navState(rootNavigator: route.isUsingRootNavigator)
          .pushReplacement(route, result: routeResult) as Future<Result>;

  void pop<Result extends Object?>({Result? routeResult, bool? rootNavigator}) {
    if (_navState(rootNavigator: rootNavigator).canPop()) {
      _navState(rootNavigator: rootNavigator).pop(routeResult);
    }
  }

  Future<Result?> pushToFirst<Result extends Object?>(
    AppPageRoute<RouteData?, Result> route,
  ) => _navState(rootNavigator: route.isUsingRootNavigator)
          .pushAndRemoveUntil(route, (r) => r.isFirst);

  Future<Result?> pushToTop<Result extends Object?>(
    AppPageRoute<RouteData?, Result> route,
  ) => _navState(rootNavigator: route.isUsingRootNavigator)
          .pushAndRemoveUntil(route, (r) => false);

  void popUntilRouteOrFirst({AppPageRoute? expectedRoute}) {
    popUntil((route) =>
        (expectedRoute != null &&
            expectedRoute.settings.name == route.settings.name) ||
        route.isFirst);
  }

  void popUntil(RoutePredicate predicate, {bool? rootNavigator}) =>
      _navState(rootNavigator: rootNavigator).popUntil(predicate);

  Data arguments<Data extends RouteData?>() {
    try {
      return read<RouteData?>() as Data;
    } catch (_) {
      return null as Data;
    }
  }

  bool isCurrentRoute(AppPageRoute<RouteData?, dynamic> route) =>
      read<AppRouteObserver>().isCurrentRoute(route);
}
```

### AppRouteObserver

```dart
// components/route/observer/app_route_observer.dart
class AppRouteObserver extends RouteObserver<ModalRoute<dynamic>> {
  AppRouteObserver({required AnalyticsRepository analyticsRepository})
    : _analyticsRepository = analyticsRepository;

  final AnalyticsRepository _analyticsRepository;
  final Map<Route<dynamic>, RouteSettings> _histories = {};

  void _sendScreenView(Route<dynamic> route) {
    final screenName = route.settings.name;
    final routeData = route.settings.arguments as RouteData?;
    if (screenName?.isNotEmpty ?? false) {
      _analyticsRepository.trackRoute(
        screenName: screenName!,
        parameters: routeData?.toMap(),
      );
      Clarity.setCurrentScreenName(screenName);
    }
  }

  bool _routeFilter(Route<dynamic>? route) =>
      route is PageRoute || route is DialogRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _histories.putIfAbsent(route, () => route.settings);
    if (_routeFilter(route)) _sendScreenView(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null && _routeFilter(newRoute)) _sendScreenView(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _histories.remove(route);
    if (previousRoute != null && _routeFilter(previousRoute) && _routeFilter(route)) {
      _sendScreenView(previousRoute);
    }
  }

  bool isCurrentRoute(AppPageRoute route) {
    final lastRouteSettings = _histories.values.last;
    return route.settings.name == lastRouteSettings.name;
  }
}
```

---

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
