import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/dynamic/dyn_reaction/item.dart';
import 'package:PiliPlus/pages/common/dyn/reaction/controller.dart';
import 'package:PiliPlus/pages/common/dyn/reaction/view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  group('DynReactController', () {
    test('initial state', () {
      final controller = DynReactController('test_id');
      expect(controller.count.value, -1);
      expect(controller.id, 'test_id');
    });

    test('initial state with custom count', () {
      final controller = DynReactController('id2', count: 42);
      expect(controller.count.value, 42);
    });
  });

  group('DynReactPage', () {
    testWidgets('renders without crashing', (tester) async {
      final controller = DynReactController('test_id');
      await tester.pumpWidget(
        GetMaterialApp(
          home: DynReactPage(
            id: 'test_id',
            isPortrait: true,
            controller: controller,
          ),
        ),
      );
      expect(find.byType(DynReactPage), findsOneWidget);
    });
  });
}
