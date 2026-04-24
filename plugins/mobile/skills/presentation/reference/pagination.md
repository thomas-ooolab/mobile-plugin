# Pagination Reference

## Base Class Implementations

### PaginationInterface

```dart
// components/pagination/interfaces/pagination_interface.dart
abstract interface class PaginationInterface<T> {
  int get limit;
  bool get isInitialLoading;
  bool get isLoading;
  bool get isRefreshing;
  bool get isError;
  List<T> get items;
  void loadMore();
}
```

### RefreshInterface

```dart
// components/pagination/interfaces/refresh_interface.dart
abstract interface class RefreshInterface {
  Future<void> refresh();
}
```

### PaginationCubitMixin

```dart
// components/pagination/mixins/pagination_cubit_mixin.dart
mixin PaginationCubitMixin<Model, State> on Cubit<State>
    implements PaginationInterface<Model>, RefreshInterface {
  bool _isLoading = false;
  bool _isRefreshing = false;
  int _page = 0;
  int _total = 0;
  int _limit = PaginationConst.pageLimit; // default 10
  bool _isError = false;
  final List<Model> _items = [];

  @override bool get isRefreshing => _isRefreshing;
  @override bool get isLoading => _isLoading;
  @override int get limit => _limit;
  set limit(int value) => _limit = value;
  @override List<Model> get items => _items;

  int get nextPage => _page + 1;
  int get total => _total;

  // MUST override — call API here; call addMore(); emit success
  Future<void> getPageData();

  // MUST override — emit failure state
  void onException();

  bool get _ended => items.length == total;
  bool get _ableToLoadMore => !isLoading && !isRefreshing && !_ended;

  Future<void> _load() async {
    _isError = false;
    _isLoading = true;
    try {
      await getPageData();
    } catch (e, s) {
      onError(e, s);
      _isError = true;
      _isLoading = false;
      _isRefreshing = false;
      _page = 0;
      _items.clear();
      onException();
    } finally {
      _isLoading = false;
      _isRefreshing = false;
    }
  }

  @mustCallSuper
  Future<void> loadInitial() async => _load();

  // Accumulates items from API response — call inside getPageData()
  void addMore({required Pagination<Model> pagination}) {
    _page = pagination.page;
    _total = pagination.total;
    if (_isRefreshing) _items.clear();
    if (pagination.items != null) _items.addAll(pagination.items!);
  }

  @mustCallSuper
  @override
  Future<void> refresh() async {
    if (_isLoading) return;
    _isRefreshing = true;
    _page = 0;
    await _load();
  }

  void reset() {
    _page = 0;
    _items.clear();
  }

  @override
  void loadMore() {
    if (_ableToLoadMore) unawaited(_load());
  }

  @override
  bool get isError => _isError;

  @override
  bool get isInitialLoading => (_page == 0) && !isRefreshing && !isError;
}
```

---

## Overview

| Component | Role |
|-----------|------|
| `Pagination<T>` | API response wrapper — items + total + page |
| `PaginationCubitMixin<Model, State>` | Cubit mixin — manages page, items, loading/error state |
| `PaginationListView<T>` | Vertical or horizontal list with auto load-more |
| `PaginationGridView<T>` | Grid with auto load-more |
| `SliverPaginationListView<T>` | Sliver list — use inside `CustomScrollView` with headers |
| `SliverPaginationGridView<T>` | Sliver grid — use inside `CustomScrollView` with headers |
| `PullDownRefreshWidget` | Wraps any pagination view with pull-to-refresh |

Import: `package:app/components/pagination/pagination.dart`

Default page size: `PaginationConst.pageLimit = 10`

---

## State

State uses `@freezed` per the standard pattern (see `@state`). Initial status is `DataLoadStatus.initial`. The `items` field mirrors what the cubit accumulates internally via `addMore()`.

```dart
// feature_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/state_management/state_management.dart';

part 'feature_state.freezed.dart';

@freezed
class FeatureState with _$FeatureState {
  const factory FeatureState({
    @Default(DataLoadStatus.initial) DataLoadStatus status,
    @Default([]) List<FeatureModel> items,
    String? errorMessage,
  }) = _FeatureState;
}
```

---

## Cubit

Mix `PaginationCubitMixin<Model, State>` and `CubitMixin<State>` — order matters, `PaginationCubitMixin` first.

**Required overrides:**

| Method | When to call | What to do |
|--------|-------------|-----------|
| `getPageData()` | Called by mixin automatically | Call repo with `nextPage` + `limit`; call `addMore()`; emit success |
| `onException()` | Called by mixin on any exception | Emit failure state |

**Optional override:**

| Method | When to override |
|--------|----------------|
| `refresh()` | Override to emit `refreshing` status before calling `super.refresh()` |

```dart
// feature_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:app/components/pagination/pagination.dart';
import 'package:app/core/state_management/state_management.dart';

@injectable
class FeatureCubit extends Cubit<FeatureState>
    with
        PaginationCubitMixin<FeatureModel, FeatureState>,
        CubitMixin<FeatureState> {
  FeatureCubit({required FeatureRepository repository})
      : _repository = repository,
        super(const FeatureState());

  final FeatureRepository _repository;

  @override
  Future<void> getPageData() async {
    safeEmit(state.copyWith(status: DataLoadStatus.loading));
    final pagination = await _repository.getItems(
      page: nextPage,
      limit: limit,
    );
    addMore(pagination: pagination);
    safeEmit(state.copyWith(status: DataLoadStatus.success, items: items));
  }

  @override
  Future<void> refresh() {
    safeEmit(state.copyWith(status: DataLoadStatus.refreshing));
    return super.refresh();
  }

  @override
  void onException() =>
      safeEmit(state.copyWith(status: DataLoadStatus.failure));
}
```

**Custom page size** — override `limit` in the constructor:

```dart
FeatureCubit(...) : super(const FeatureState()) {
  limit = 20;
}
```

**Call `loadInitial()` when providing the cubit:**

```dart
BlocProvider(create: (_) => sl<FeatureCubit>()..loadInitial())
```

---

## Pagination<T> Entity

Repository methods return `Pagination<T>` from `package:entity/entity.dart`.

```dart
class Pagination<T> {
  final List<T>? items;
  final int total;   // total items across all pages
  final int page;    // current page number
  final int perPage;
  final String? sortBy;
  final String? order;
}
```

Pass it directly to `addMore()` inside `getPageData()`.

---

## Views

All pagination views take the cubit as `controller` — the cubit implements `PaginationInterface<T>`. Wrap in `BlocBuilder` so the view rebuilds on state changes.

### PaginationListView

```dart
BlocBuilder<FeatureCubit, FeatureState>(
  builder: (context, state) {
    return PaginationListView<FeatureModel>(
      controller: context.read<FeatureCubit>(),
      itemBuilder: (context, index, item) => FeatureItem(item: item),
      separatorBuilder: (context, index) => const VleSpace.vertical16(),
      loadingEffectItemBuilder: (context, index) => FeatureItem.loading(),
      emptyWidget: const EmptyFeatureWidget(),
      padding: const EdgeInsets.all(VleDimens.px16),
    );
  },
)
```

**Key params:**

| Param | Type | Notes |
|-------|------|-------|
| `controller` | `PaginationInterface<T>` | Pass the cubit — required |
| `itemBuilder` | `(ctx, index, item) → Widget` | Builds each item — required |
| `separatorBuilder` | `(ctx, index) → Widget` | Separator between items |
| `loadingEffectItemBuilder` | `(ctx, index) → Widget` | Shimmer/skeleton during initial load |
| `loadingIndicatorBuilder` | `(ctx) → Widget` | Bottom spinner while loading more |
| `emptyWidget` | `Widget` | Shown when list is empty |
| `padding` | `EdgeInsets` | Defaults to `EdgeInsets.zero` |
| `physics` | `ScrollPhysics?` | Pass `NeverScrollableScrollPhysics()` inside nested scrollables |
| `scrollController` | `ScrollController?` | External controller |

**Horizontal list:**

```dart
PaginationListView.horizontal(
  controller: context.read<FeatureCubit>(),
  itemBuilder: (context, index, item) => FeatureCard(item: item),
  itemWidth: 160,
)
```

### PaginationGridView

```dart
BlocBuilder<FeatureCubit, FeatureState>(
  builder: (context, state) {
    return PaginationGridView<FeatureModel>(
      controller: context.read<FeatureCubit>(),
      itemBuilder: (context, index, item) => FeatureCard(item: item),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: VleDimens.px12,
        mainAxisSpacing: VleDimens.px12,
        childAspectRatio: 1.2,
      ),
      loadingEffectItemBuilder: (context, index) => FeatureCard.loading(),
      emptyWidget: const EmptyFeatureWidget(),
      padding: const EdgeInsets.all(VleDimens.px16),
    );
  },
)
```

### Sliver Variants

Use `SliverPaginationListView` / `SliverPaginationGridView` when the screen has sticky headers or other slivers above the list.

```dart
SliverPaginationListView<FeatureModel>(
  controller: context.read<FeatureCubit>(),
  itemBuilder: (context, index, item) => FeatureItem(item: item),
  sliverHeaders: [
    SliverToBoxAdapter(child: FeatureHeader()),
    SliverPersistentHeader(delegate: FilterBarDelegate(), pinned: true),
  ],
  loadingEffectItemBuilder: (context, index) => FeatureItem.loading(),
  emptyWidget: const EmptyFeatureWidget(),
  padding: const EdgeInsets.symmetric(horizontal: VleDimens.px16),
)
```

`sliverHeaders` are placed above the list inside the internal `CustomScrollView`.

---

## Pull-to-Refresh

Wrap any pagination view with `PullDownRefreshWidget`. The cubit implements `RefreshInterface` so pass it as `controller`.

```dart
PullDownRefreshWidget(
  controller: context.read<FeatureCubit>(),
  child: PaginationListView<FeatureModel>(
    controller: context.read<FeatureCubit>(),
    itemBuilder: (context, index, item) => FeatureItem(item: item),
    ...
  ),
)
```

Custom refresh callback (e.g. to chain extra logic):

```dart
PullDownRefreshWidget(
  controller: context.read<FeatureCubit>(),
  onRefresh: () async {
    await context.read<FeatureCubit>().refresh();
    await context.read<FilterCubit>().reload();
  },
  child: PaginationListView(...),
)
```

---

## NEVER

- Call `getPageData()` directly — call `loadInitial()` to start; the mixin handles subsequent pages
- Forget `onException()` — without it, errors leave the cubit in a broken loading state
- Use `PaginationCubitMixin` without `CubitMixin` — `safeEmit` is needed for async safety
- Use `@freezed` `sealed` union states with pagination — data loss on status transitions; use single state with `DataLoadStatus`
