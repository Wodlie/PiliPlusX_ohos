import 'package:flutter_test/flutter_test.dart';
import 'package:PiliPlus/utils/android/android_helper.dart';

void main() {
  group('AndroidHelper stubs', () {
    test('biliSendCommAntifraud throws UnsupportedError on OHOS', () {
      expect(
        () => AndroidHelper.biliSendCommAntifraud(
          1,   // action
          2,   // oid
          3,   // type
          4,   // rpId
          5,   // root
          6,   // parent
          7,   // ctime
          'test comment', // commentText
          [],  // pictures
          'source', // sourceId
          8,   // uid
          'cookie', // cookie
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('back throws UnsupportedError on OHOS', () {
      expect(
        () => AndroidHelper.back(),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('openLinkVerifySettings throws UnsupportedError on OHOS', () {
      expect(
        () => AndroidHelper.openLinkVerifySettings(),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('stubs do not throw unexpected errors (type-safe)', () {
      // Verify error messages are descriptive
      try {
        AndroidHelper.back();
      } on UnsupportedError catch (e) {
        expect(e.message, contains('not available on OHOS'));
      }

      try {
        AndroidHelper.openLinkVerifySettings();
      } on UnsupportedError catch (e) {
        expect(e.message, contains('not available on OHOS'));
      }

      try {
        AndroidHelper.biliSendCommAntifraud(
          0, 0, 0, 0, 0, 0, 0, '', [], '', 0, '',
        );
      } on UnsupportedError catch (e) {
        expect(e.message, contains('not available on OHOS'));
      }
    });
  });
}
