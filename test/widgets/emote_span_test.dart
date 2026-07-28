import 'package:PiliPlus/common/widgets/emote_span.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmoteSpan', () {
    testWidgets('can be created with required child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Text.rich(
            TextSpan(
              children: [
                EmoteSpan(
                  rawText: '[emote]',
                  child: const SizedBox(width: 24, height: 24),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(EmoteSpan), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    test('stores rawText', () {
      const span = EmoteSpan(
        rawText: '[test_emote]',
        child: SizedBox(width: 10, height: 10),
      );

      expect(span.rawText, equals('[test_emote]'));
    });

    test('rawText defaults to null', () {
      const span = EmoteSpan(
        child: SizedBox(width: 10, height: 10),
      );

      expect(span.rawText, isNull);
    });

    test('is a WidgetSpan subclass', () {
      const span = EmoteSpan(
        child: SizedBox(width: 10, height: 10),
      );

      expect(span, isA<WidgetSpan>());
    });
  });
}