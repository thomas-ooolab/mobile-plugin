# Widget Testing

## Table of Contents
- [Screen Testing with Cubit](#screen-testing-with-cubit)
- [Widget Testing with Pagination](#widget-testing-with-pagination)
- [Simple Widget Test (No Cubit)](#simple-widget-test-no-cubit)

---

## Screen Testing with Cubit

```dart
import '../../../test_helpers/test_helpers.dart';

// Define private mock cubits in the test file
class _MockFeatureCubit extends MockCubit<FeatureState>
    implements FeatureCubit {}

void main() {
  group(FeatureScreen, () {
    late _MockFeatureCubit mockFeatureCubit;
    
    setUp(() {
      mockFeatureCubit = _MockFeatureCubit();
      final state = FeatureState(status: DataLoadStatus.success);
      whenListen(
        mockFeatureCubit,
        Stream.value(state),
        initialState: state,
      );
    });
    
    testWidgets('can be instantiated', (tester) async {
      await tester.pumpWidgetWithMaterialApp(
        child: FeatureScreen(),
      );
      
      expect(find.byType(FeatureView), findsOneWidget);
    });
    
    testWidgets('should render the layout as design expectation', (
      tester,
    ) async {
      await tester.pumpWidgetWithMaterialApp(
        child: BlocProvider<FeatureCubit>(
          create: (context) => mockFeatureCubit,
          child: FeatureScreen(),
        ),
      );
      
      expect(find.text('Expected Text'), findsOneWidget);
      expect(find.byType(FeatureWidget), findsWidgets);
    });
    
    testWidgets('should call cubit method when button tapped', (
      tester,
    ) async {
      when(() => mockFeatureCubit.loadMore()).thenAnswer((_) async {});
      
      await tester.pumpWidgetWithMaterialApp(
        child: BlocProvider<FeatureCubit>(
          create: (context) => mockFeatureCubit,
          child: FeatureScreen(),
        ),
      );
      
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      
      verify(() => mockFeatureCubit.loadMore()).called(1);
    });
  });
}
```

---

## Widget Testing with Pagination

```dart
testWidgets('should render pagination items', (tester) async {
  final items = List.generate(
    5,
    (index) => Feature(id: index, name: 'Feature $index'),
  );
  
  mockPaginationViewMixin(
    controller: mockFeatureCubit,
    items: items,
    isLoading: false,
  );
  
  await tester.pumpWidgetWithMaterialApp(
    child: BlocProvider<FeatureCubit>(
      create: (context) => mockFeatureCubit,
      child: FeatureListView(),
    ),
  );
  
  expect(find.text('Feature 0'), findsOneWidget);
  expect(find.text('Feature 4'), findsOneWidget);
});
```

---

## Simple Widget Test (No Cubit)

```dart
void main() {
  group(SimpleWidget, () {
    testWidgets('displays correct text', (tester) async {
      await tester.pumpWidgetWithMaterialApp(
        child: SimpleWidget(text: 'Hello World'),
      );
      
      expect(find.text('Hello World'), findsOneWidget);
    });
  });
}
```
