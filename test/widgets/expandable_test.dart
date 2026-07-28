import 'package:PiliPlus/common/widgets/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpandablePanel', () {
    testWidgets('shows collapsed child when expand is false', (tester) async {
      const collapsedKey = Key('collapsed');
      const expandedKey = Key('expanded');

      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            height: 300,
            child: ExpandablePanel(
              expand: false,
              collapsed: SizedBox(key: collapsedKey, height: 50),
              expanded: SizedBox(key: expandedKey, height: 200),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Both children are in the tree (cross-fade), but collapsed is visible
      expect(find.byKey(collapsedKey), findsOneWidget);
      expect(find.byKey(expandedKey), findsOneWidget);
    });

    testWidgets('shows expanded child when expand is true', (tester) async {
      const collapsedKey = Key('collapsed');
      const expandedKey = Key('expanded');

      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(
            height: 300,
            child: ExpandablePanel(
              expand: true,
              collapsed: SizedBox(key: collapsedKey, height: 50),
              expanded: SizedBox(key: expandedKey, height: 200),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(collapsedKey), findsOneWidget);
      expect(find.byKey(expandedKey), findsOneWidget);
    });

    testWidgets('can toggle between collapsed and expanded', (tester) async {
      bool expand = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: SizedBox(
                height: 300,
                child: ExpandablePanel(
                  expand: expand,
                  collapsed: const Text('collapsed'),
                  expanded: const Text('expanded'),
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('collapsed'), findsOneWidget);
      expect(find.text('expanded'), findsOneWidget);

      // Toggle expand
      expand = true;
      await tester.pumpAndSettle();

      expect(find.text('collapsed'), findsOneWidget);
      expect(find.text('expanded'), findsOneWidget);
    });
  });
}