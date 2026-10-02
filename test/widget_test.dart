// Basic smoke test: the app boots and lands on a screen without throwing.
//
// The default `flutter create` template test references a `MyApp` class
// that doesn't exist in this project (our root widget is `HabitTrackerApp`,
// wrapped in a ProviderScope for Riverpod) — this replaces that stub.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/app/app.dart';

void main() {
  testWidgets('App boots without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: HabitTrackerApp()),
    );
    await tester.pump();

    // Just verifying the widget tree built successfully is enough for a
    // smoke test here — no specific text assertion, since the Today screen's
    // content depends on the (empty, in tests) database state.
    expect(find.byType(HabitTrackerApp), findsOneWidget);
  });
}