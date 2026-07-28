// NOTE: This test file requires page_utils.dart which transitively imports
// several modules with pre-existing compilation errors.
// Once those project-wide issues are resolved, run:
//   flutter test test/utils/selectable_region_ext_test.dart
//
// The extension under test (SelectableRegionStateExt) is already ported to
// lib/utils/extension/selectable_region_ext.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:PiliPlus/utils/extension/selectable_region_ext.dart';

void main() {
  group('SelectableRegionStateExt', () {
    testWidgets('hideAndClear() does not throw', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectionArea(
            child: SelectableRegion(
              focusNode: FocusNode(),
              selectionControls: materialTextSelectionControls,
              child: const Text('Hello'),
            ),
          ),
        ),
      );

      final state = tester.state<SelectableRegionState>(
        find.byType(SelectableRegion),
      );

      expect(state.hideAndClear, returnsNormally);
    });

    testWidgets('selectedText is null when no selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectionArea(
            child: SelectableRegion(
              focusNode: FocusNode(),
              selectionControls: materialTextSelectionControls,
              child: const Text('Hello'),
            ),
          ),
        ),
      );

      final state = tester.state<SelectableRegionState>(
        find.byType(SelectableRegion),
      );

      expect(state.selectedText, isNull);
    });

    testWidgets('isUncollapsed when no selection', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SelectionArea(
            child: SelectableRegion(
              focusNode: FocusNode(),
              selectionControls: materialTextSelectionControls,
              child: const Text('Hello'),
            ),
          ),
        ),
      );

      final state = tester.state<SelectableRegionState>(
        find.byType(SelectableRegion),
      );

      expect(state.isUncollapsed, false);
    });
  });
}
