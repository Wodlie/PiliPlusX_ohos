import 'package:PiliPlus/common/widgets/translucent_column.dart';
import 'package:PiliPlus/common/widgets/translucent_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TranslucentColumn', () {
    testWidgets('renders children vertically', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 200,
            height: 300,
            child: TranslucentColumn(
              children: [
                SizedBox(key: Key('a'), height: 50),
                SizedBox(key: Key('b'), height: 50),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('a')), findsOneWidget);
      expect(find.byKey(const Key('b')), findsOneWidget);

      // Verify vertical layout: 'a' should be above 'b'
      final aRect = tester.getTopLeft(find.byKey(const Key('a')));
      final bRect = tester.getTopLeft(find.byKey(const Key('b')));
      expect(aRect.dy, lessThan(bRect.dy));
    });

    testWidgets('NoTranslucentArea wraps child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NoTranslucentArea(
            child: SizedBox(width: 50, height: 50),
          ),
        ),
      );

      expect(find.byType(NoTranslucentArea), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);
    });
  });

  group('TranslucentRow', () {
    testWidgets('renders children horizontally', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 300,
            height: 100,
            child: TranslucentRow(
              extraWidth: 0,
              children: [
                SizedBox(key: Key('a'), width: 50),
                SizedBox(key: Key('b'), width: 50),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('a')), findsOneWidget);
      expect(find.byKey(const Key('b')), findsOneWidget);

      // Verify horizontal layout: 'a' should be left of 'b'
      final aRect = tester.getTopLeft(find.byKey(const Key('a')));
      final bRect = tester.getTopLeft(find.byKey(const Key('b')));
      expect(aRect.dx, lessThan(bRect.dx));
    });

    testWidgets('requires extraWidth parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            width: 300,
            height: 100,
            child: TranslucentRow(
              extraWidth: 100,
              children: [],
            ),
          ),
        ),
      );

      final row = tester.widget<TranslucentRow>(find.byType(TranslucentRow));
      expect(row.extraWidth, equals(100.0));
    });
  });
}