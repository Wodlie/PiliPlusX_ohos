import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/follow/controller.dart';
import 'package:PiliPlus/pages/follow_tag_sort/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  group('FollowTagSortPage', () {
    testWidgets('renders with controller', (tester) async {
      final controller = FollowController();
      Get.put(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          home: FollowTagSortPage(controller: controller),
        ),
      );

      expect(find.byType(FollowTagSortPage), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      Get.delete<FollowController>();
    });

    testWidgets('shows title', (tester) async {
      final controller = FollowController();
      Get.put(controller);

      await tester.pumpWidget(
        GetMaterialApp(
          home: FollowTagSortPage(controller: controller),
        ),
      );

      expect(find.text('关注分组排序'), findsOneWidget);

      Get.delete<FollowController>();
    });
  });
}
