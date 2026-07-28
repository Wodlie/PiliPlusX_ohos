import 'package:PiliPlus/common/widgets/animated_multi_height.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnimatedMultiHeight', () {
    testWidgets('renders child at full height when expand is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 200,
            child: AnimatedMultiHeight(
              duration: const Duration(milliseconds: 200),
              expand: true,
              child: const SizedBox(height: 80, width: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final box = tester.getSize(find.byType(AnimatedMultiHeight));
      expect(box.height, equals(80.0));
    });

    testWidgets('renders child at full height when expand is false initially',
        (tester) async {
      // AnimatedMultiHeight doesn't hide when expand=false; it animates
      // from the current size to the child's size. On first build with
      // expand=false, the controller starts at 0.0, so the height is 0.
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 200,
            child: AnimatedMultiHeight(
              duration: const Duration(milliseconds: 200),
              expand: false,
              child: const SizedBox(height: 80, width: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final box = tester.getSize(find.byType(AnimatedMultiHeight));
      // When expand=false initially, controller value is 0.0, so
      // the animated size interpolates from 0 to child height (80).
      // After settling, the animation completes and height = 80.
      expect(box.height, equals(80.0));
    });

    testWidgets('calls onEnd when animation completes', (tester) async {
      bool onEndCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 200,
            child: AnimatedMultiHeight(
              duration: const Duration(milliseconds: 100),
              expand: true,
              onEnd: () {
                onEndCalled = true;
              },
              child: const SizedBox(height: 80, width: 100),
            ),
          ),
        ),
      );

      // Initially expand=true, controller starts at 1.0 (no animation).
      // Toggle to expand=false to trigger animation.
      await tester.pumpAndSettle();

      // Now we need to toggle expand to trigger animation
      // Since the widget is stateless from outside, we rebuild with expand=false
      onEndCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 200,
            child: AnimatedMultiHeight(
              duration: const Duration(milliseconds: 100),
              expand: false,
              onEnd: () {
                onEndCalled = true;
              },
              child: const SizedBox(height: 80, width: 100),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(onEndCalled, isTrue);
    });
  });
}