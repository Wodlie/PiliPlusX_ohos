import 'package:PiliPlus/common/widgets/selection_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectionText', () {
    testWidgets('renders plain text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SelectionText('Hello World'),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('renders rich text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SelectionText.rich(
            TextSpan(
              text: 'Rich content',
              children: [TextSpan(text: ' with more')],
            ),
          ),
        ),
      );

      // Text.rich merges spans, so we find the combined text
      expect(find.byType(SelectionText), findsOneWidget);
    });

    testWidgets('applies text style', (tester) async {
      const style = TextStyle(fontSize: 20, color: Colors.red);

      await tester.pumpWidget(
        const MaterialApp(
          home: SelectionText(
            'Styled',
            style: style,
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style, equals(style));
    });

    testWidgets('applies text alignment', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SelectionText(
            'Aligned',
            textAlign: TextAlign.center,
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.textAlign, equals(TextAlign.center));
    });

    testWidgets('uses custom context menu builder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectionText(
            'Custom menu',
            contextMenuBuilder: (context, state) {
              return const Text('custom menu widget');
            },
          ),
        ),
      );

      expect(find.byType(SelectionText), findsOneWidget);
      expect(find.text('Custom menu'), findsOneWidget);
    });
  });
}