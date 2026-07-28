import 'package:PiliPlus/common/widgets/fractionally_sized_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomFractionallySizedBox', () {
    testWidgets('sizes child by width and height factors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: CustomFractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 0.5,
                maxWidth: 100,
                child: const SizedBox(width: 1000, height: 1000),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(CustomFractionallySizedBox));
      // 0.5 * 200 = 100 for both width and height
      expect(size.width, equals(100.0));
      expect(size.height, equals(100.0));
    });

    testWidgets('respects maxWidth constraint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              height: 300,
              child: CustomFractionallySizedBox(
                widthFactor: 0.8,
                heightFactor: 0.5,
                maxWidth: 200,
                child: const SizedBox(width: 1000, height: 1000),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(CustomFractionallySizedBox));
      // 0.8 * 300 = 240, but maxWidth is 200, so width should be 200
      expect(size.width, equals(200.0));
      // 0.5 * 300 = 150 for height
      expect(size.height, equals(150.0));
    });

    testWidgets('handles full size factors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: CustomFractionallySizedBox(
                widthFactor: 1.0,
                heightFactor: 1.0,
                maxWidth: 200,
                child: const SizedBox(width: 50, height: 50),
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(CustomFractionallySizedBox));
      expect(size.width, equals(100.0));
      expect(size.height, equals(100.0));
    });
  });
}