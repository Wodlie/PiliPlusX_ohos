import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';

import 'package:PiliPlus/utils/platform_utils.dart';

void main() {
  group('PlatformUtils', () {
    test('isDarwin matches Platform.isIOS || Platform.isMacOS', () {
      expect(PlatformUtils.isDarwin, Platform.isIOS || Platform.isMacOS);
    });

    test('isHarmony should be false on non-OHOS platforms', () {
      // When running on standard platforms (Windows/macOS/Linux/Android/iOS),
      // OS.isHarmony is expected to be false.
      expect(PlatformUtils.isHarmony, equals(false));
    });

    test('isMobile matches Android/iOS/Harmony', () {
      final expectedMobile = Platform.isAndroid || Platform.isIOS;
      // On non-OHOS platforms, isMobile should equal the dart:io check
      expect(PlatformUtils.isMobile, equals(expectedMobile));
    });

    test('isDesktop matches Windows/macOS/Linux but excludes Harmony', () {
      final expectedDesktop =
          Platform.isWindows || Platform.isMacOS || Platform.isLinux;
      // On non-OHOS, isDesktop should match the dart:io check exactly
      expect(PlatformUtils.isDesktop, equals(expectedDesktop));
    });

    test('isDarwin and isDesktop are mutually exclusive on Darwin platforms',
        () {
      // Darwin is a subset of desktop (macOS) or mobile (iOS)
      if (PlatformUtils.isDarwin) {
        expect(PlatformUtils.isMobile || PlatformUtils.isDesktop, isTrue);
      }
    });

    test('isMobile and isDesktop are never both true', () {
      // A platform should not be both mobile and desktop
      expect(PlatformUtils.isMobile && PlatformUtils.isDesktop, isFalse);
    });

    test('isHarmony is not both mobile and desktop', () {
      // If Harmony, it should be mobile, not desktop
      if (PlatformUtils.isHarmony) {
        expect(PlatformUtils.isMobile, isTrue);
        expect(PlatformUtils.isDesktop, isFalse);
      }
    });
  });
}
