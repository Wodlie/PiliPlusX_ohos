import 'package:flutter_test/flutter_test.dart';
import 'package:PiliPlus/utils/max_screen_size.dart';

void main() {
  group('MaxScreenSize', () {
    test('init does not throw', () {
      expect(() => MaxScreenSize.init(), returnsNormally);
    });

    group('isWindowMode', () {
      test('returns false on non-Android platforms', () {
        // On the test runner (non-Android), isWindowMode should always be false.
        expect(MaxScreenSize.isWindowMode(width: 1920, height: 1080), false);
        expect(MaxScreenSize.isWindowMode(width: 800, height: 600), false);
        expect(MaxScreenSize.isWindowMode(width: 0, height: 0), false);
      });
    });
  });
}
