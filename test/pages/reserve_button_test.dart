import 'package:PiliPlus/pages/member/widget/reserve_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReserveButton', () {
    testWidgets('renders with count and color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReserveButton(
              count: 42,
              color: Colors.red,
              child: const SizedBox(width: 100, height: 50),
            ),
          ),
        ),
      );

      // The button should render without errors
      expect(find.byType(ReserveButton), findsOneWidget);
    });

    testWidgets('creates RenderReserveBtn', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReserveButton(
              count: 10,
              color: Colors.blue,
              child: const SizedBox(width: 100, height: 50),
            ),
          ),
        ),
      );

      final button = tester.widget<ReserveButton>(find.byType(ReserveButton));
      expect(button.count, 10);
      expect(button.color, Colors.blue);
    });

    testWidgets('RenderReserveBtn updates count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReserveButton(
              count: 5,
              color: Colors.green,
              child: const SizedBox(width: 100, height: 50),
            ),
          ),
        ),
      );

      // Rebuild with new count
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReserveButton(
              count: 99,
              color: Colors.green,
              child: const SizedBox(width: 100, height: 50),
            ),
          ),
        ),
      );

      final button = tester.widget<ReserveButton>(find.byType(ReserveButton));
      expect(button.count, 99);
    });
  });
}
