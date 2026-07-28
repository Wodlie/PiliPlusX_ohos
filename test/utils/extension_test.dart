import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// dimension_ext & iterable_ext — self-contained unit tests.
// selectable_region_ext tests included here also compile cleanly
// because the Flutter core types (SelectableRegion, SelectableRegionState)
// are available without pulling in page_utils.dart.
import 'package:PiliPlus/grpc/bilibili/app/archive/v1.pb.dart'
    show Dimension;
import 'package:PiliPlus/utils/extension/dimension_ext.dart';
import 'package:PiliPlus/utils/extension/iterable_ext.dart';
import 'package:PiliPlus/utils/extension/nested_scroll_ext.dart';
// selectable_region_ext excluded here because it transitively imports
// page_utils.dart which hits pre-existing project-wide compilation errors.
// See test/utils/selectable_region_ext_test.dart for standalone tests.

void main() {
  group('dimension_ext — DimensionExt', () {
    test('isVertical: portrait (height>width, rotate=0) returns true', () {
      final dim = Dimension(width: Int64(720), height: Int64(1280));
      expect(dim.isVertical, true);
    });

    test('isVertical: landscape (width>height, rotate=0) returns false', () {
      final dim = Dimension(width: Int64(1920), height: Int64(1080));
      expect(dim.isVertical, false);
    });

    test('isVertical: rotate=1 swaps the sense', () {
      final dim = Dimension(
        width: Int64(1280),
        height: Int64(720),
        rotate: Int64(1),
      );
      expect(dim.isVertical, true);
    });

    test('isVertical: rotate=1 with height>width => landscape', () {
      final dim = Dimension(
        width: Int64(720),
        height: Int64(1280),
        rotate: Int64(1),
      );
      expect(dim.isVertical, false);
    });

    test('isVertical: equal dimensions returns false', () {
      final dim = Dimension(width: Int64(100), height: Int64(100));
      expect(dim.isVertical, false);
    });
  });

  group('dimension_ext — StringExt.isVerticalFromUri', () {
    test('portrait URI with player_rotate=0', () {
      const uri =
          'https://example.com/video?player_width=720&player_height=1280&player_rotate=0';
      expect(uri.isVerticalFromUri, true);
    });

    test('landscape URI with player_rotate=0', () {
      const uri =
          'https://example.com/video?player_width=1920&player_height=1080&player_rotate=0';
      expect(uri.isVerticalFromUri, false);
    });

    test('rotated landscape (rotate=1, width>height) => vertical', () {
      const uri =
          'https://example.com/video?player_width=1280&player_height=720&player_rotate=1';
      expect(uri.isVerticalFromUri, true);
    });

    test('rotated portrait (rotate=1, height>width) => landscape', () {
      const uri =
          'https://example.com/video?player_width=720&player_height=1280&player_rotate=1';
      expect(uri.isVerticalFromUri, false);
    });

    test('invalid URI returns false', () {
      expect('invalid-uri'.isVerticalFromUri, false);
    });

    test('non-numeric params returns false', () {
      const uri =
          'https://example.com?player_width=abc&player_height=def&player_rotate=0';
      expect(uri.isVerticalFromUri, false);
    });
  });

  group('iterable_ext — ListExt.insertOrAdd', () {
    test('inserts at index when within bounds', () {
      final list = <int>[1, 2, 3];
      list.insertOrAdd(1, 99);
      expect(list, [1, 99, 2, 3]);
    });

    test('inserts at index when index equals length', () {
      final list = <int>[1, 2, 3];
      list.insertOrAdd(3, 99);
      expect(list, [1, 2, 3, 99]);
    });

    test('appends when index exceeds length', () {
      final list = <int>[1, 2, 3];
      list.insertOrAdd(10, 99);
      expect(list, [1, 2, 3, 99]);
    });

    test('inserts at index 0 on empty list', () {
      final list = <int>[];
      list.insertOrAdd(0, 42);
      expect(list, [42]);
    });
  });

  group('iterable_ext — ListExt.getOrNull', () {
    test('returns element at valid index', () {
      expect([10, 20, 30].getOrNull(1), 20);
    });

    test('returns null for negative index', () {
      expect([10, 20, 30].getOrNull(-1), isNull);
    });

    test('returns null when index exceeds length', () {
      expect([10, 20, 30].getOrNull(10), isNull);
    });

    test('returns null on empty list', () {
      expect(<int>[].getOrNull(0), isNull);
    });
  });

  group('iterable_ext — ListExt.getOrFirst', () {
    test('returns element at valid index', () {
      expect([10, 20, 30].getOrFirst(1), 20);
    });

    test('returns first when index out of bounds', () {
      expect([10, 20, 30].getOrFirst(10), 10);
    });

    test('returns first when index negative', () {
      expect([10, 20, 30].getOrFirst(-1), 10);
    });
  });

  group('nested_scroll_ext — ExtendedNestedScrollViewStateExt', () {
    testWidgets('refresh() does not throw when mounted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExtendedNestedScrollView(
            headerSliverBuilder: (context, _) => [
              const SliverAppBar(title: Text('Header')),
            ],
            body: const SingleChildScrollView(child: Text('Body')),
          ),
        ),
      );

      final state = tester.state<ExtendedNestedScrollViewState>(
        find.byType(ExtendedNestedScrollView),
      );

      expect(state.refresh, returnsNormally);
    });

    testWidgets('animToTop() does not throw when mounted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ExtendedNestedScrollView(
            headerSliverBuilder: (context, _) => [
              const SliverAppBar(title: Text('Header')),
            ],
            body: const SingleChildScrollView(child: Text('Body')),
          ),
        ),
      );

      final state = tester.state<ExtendedNestedScrollViewState>(
        find.byType(ExtendedNestedScrollView),
      );

      expect(state.animToTop, returnsNormally);
    });
  });

}
