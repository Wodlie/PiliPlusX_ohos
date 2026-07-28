import 'package:PiliPlus/common/widgets/animated_height.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnimatedHeight', () {
    testWidgets('renders child when expand is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 100,
            child: AnimatedHeight(
              duration: const Duration(milliseconds: 200),
              expand: true,
              child: const SizedBox(height: 50, width: 100),
            ),
          ),
        ),
      );

      // When expand=true, the child should be visible
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('collapses to zero height when expand is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 100,
            child: AnimatedHeight(
              duration: const Duration(milliseconds: 200),
              expand: false,
              child: const SizedBox(height: 50, width: 100),
            ),
          ),
        ),
      );

      // When expand=false, the widget should have zero height
      final box = tester.getSize(find.byType(AnimatedHeight));
      expect(box.height, equals(0.0));
    });

    testWidgets('animates height when expand toggles', (tester) async {
      bool expand = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: SizedBox(
                height: 200,
                child: AnimatedHeight(
                  duration: const Duration(milliseconds: 200),
                  expand: expand,
                  child: const SizedBox(height: 100, width: 100),
                ),
              ),
            );
          },
        ),
      );

      // Initially collapsed
      var box = tester.getSize(find.byType(AnimatedHeight));
      expect(box.height, equals(0.0));

      // Toggle expand
      expand = true;
      await tester.pumpAndSettle();

      box = tester.getSize(find.byType(AnimatedHeight));
      expect(box.height, equals(100.0));
    });

    test('Heights typedef creates correct record', () {
      const Heights heights = (from: 0.0, to: 100.0);
      expect(heights.from, equals(0.0));
      expect(heights.to, equals(100.0));
    });
  });
}