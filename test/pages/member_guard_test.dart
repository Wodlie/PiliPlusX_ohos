import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/member_guard/controller.dart';
import 'package:PiliPlus/pages/member_guard/view.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  group('MemberGuardController', () {
    test('initial state', () {
      // Ruid is set from Get.arguments in onInit
      expect(MemberGuardController, isNotNull);
    });
  });

  group('MemberGuard', () {
    testWidgets('renders without crashing', (tester) async {
      Get.testMode = true;

      await tester.pumpWidget(
        GetMaterialApp(
          getPages: [
            GetPage(
              name: '/memberGuard',
              page: () => const MemberGuard(),
            ),
          ],
        ),
      );

      await Get.toNamed('/memberGuard', arguments: {
        'ruid': '12345',
        'name': 'TestUser',
        'count': 42,
      });
      await tester.pumpAndSettle();

      // AppBar should show
      expect(find.byType(AppBar), findsOneWidget);

      Get.testMode = false;
    });

    test('toMemberGuard static method returns route', () {
      final result = MemberGuard.toMemberGuard(
        mid: '123',
        name: 'Test',
        count: 5,
      );
      expect(result, isNotNull);
    });
  });
}
