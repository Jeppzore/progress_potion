import 'package:flutter_test/flutter_test.dart';
import 'package:progress_potion/app/progress_potion_app.dart';

void main() {
  testWidgets('renders the branded home shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ProgressPotionApp());
    await tester.pumpAndSettle();

    expect(find.text('ProgressPotion'), findsOneWidget);
    expect(find.text("Today's momentum"), findsOneWidget);
    expect(find.text('Active Habits'), findsOneWidget);
  });

  testWidgets('switches between home and task tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProgressPotionApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    expect(find.text('Task Forge'), findsOneWidget);
    expect(find.text('Ready today'), findsOneWidget);
    expect(find.text("Today's momentum"), findsNothing);
  });
}
