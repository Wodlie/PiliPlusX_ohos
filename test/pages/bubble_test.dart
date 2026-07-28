import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/bubble/category_list.dart';
import 'package:PiliPlus/models_new/bubble/data.dart';
import 'package:PiliPlus/models_new/bubble/dyn_list.dart';
import 'package:PiliPlus/models_new/bubble/sort_info.dart';
import 'package:PiliPlus/pages/bubble/controller.dart';
import 'package:PiliPlus/pages/bubble/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  group('BubbleController', () {
    test('initial state', () {
      final controller = BubbleController(null);
      expect(controller.sortInfo.value, isNull);
      expect(controller.tabController, isNull);
      expect(controller.tribeName.value, isNull);
      expect(controller.tabs.value, isNull);
    });

    test('constructor stores categoryId', () {
      final controllerWithCat = BubbleController('cat1');
      final controllerWithout = BubbleController(null);
      expect(controllerWithCat.categoryId, 'cat1');
      expect(controllerWithout.categoryId, isNull);
    });
  });

  group('BubblePage', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const BubblePage(),
        ),
      );
      expect(find.byType(BubblePage), findsOneWidget);
      // Should show loading state initially
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders with categoryId tag', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          home: const BubblePage(categoryId: 'test_cat'),
        ),
      );
      expect(find.byType(BubblePage), findsOneWidget);
    });
  });
}
