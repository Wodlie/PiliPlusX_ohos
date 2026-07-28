import 'package:flutter_test/flutter_test.dart';
import 'package:PiliPlus/utils/device_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeviceUtils', () {
    test('sdkInt is null on non-Android platforms', () {
      // On non-Android platforms (including test runner), sdkInt should be null.
      expect(DeviceUtils.sdkInt, isNull);
    });

    test('isTablet does not throw', () {
      expect(() => DeviceUtils.isTablet, returnsNormally);
    });

    test('size returns non-zero dimensions', () {
      // Screen size should be positive in any environment.
      expect(DeviceUtils.size.width, greaterThan(0));
      expect(DeviceUtils.size.height, greaterThan(0));
    });

    test('platformName returns one of desktop/pad/phone', () {
      expect(
        ['desktop', 'pad', 'phone'],
        contains(DeviceUtils.platformName),
      );
    });

    test('isTablet logic: size.shortestSide >= 600', () {
      // Verify the threshold logic is correct.
      final screenSize = DeviceUtils.size;
      final expectedTablet = screenSize.shortestSide >= 600;
      expect(DeviceUtils.isTablet, equals(expectedTablet));
    });
  });
}
