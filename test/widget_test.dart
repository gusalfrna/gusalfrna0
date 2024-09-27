import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gusalfrna0/main.dart'; // Använd ditt faktiska paketnamn här.

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Bygg vår app och trigga en ram.
    await tester.pumpWidget(const TodoApp());

    // Verifiera att vår räknare börjar på 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tryck på '+' ikonen och trigga en ram.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verifiera att vår räknare har ökat.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
