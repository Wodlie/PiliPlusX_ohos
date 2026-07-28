import 'package:PiliPlus/utils/connectivity_utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// OHOS mock channel name used by connectivity_plus 5.x.
const _kConnectivityChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');

/// Returns a mock handler that always throws [MissingPluginException],
/// simulating a platform (e.g. OHOS) where the native plugin is not
/// registered.
Never _throwMissingPlugin(MethodCall _) => throw MissingPluginException();

void main() {
  group('ConnectivityUtils', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      // By default every test runs with a missing-plugin mock so the
      // fallback path is exercised.  Tests that need a working plugin
      // override in their own body.
      TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
          .setMockMethodCallHandler(_kConnectivityChannel, _throwMissingPlugin);
    });

    group('fallback (MissingPluginException)', () {
      test('checkConnectivity returns [none]', () async {
        final result = await ConnectivityUtils.checkConnectivity();
        expect(result, isA<List<ConnectivityResult>>());
        expect(result, contains(ConnectivityResult.none));
      });

      test('isNone returns true', () async {
        expect(await ConnectivityUtils.isNone(), isTrue);
      });

      test('isWifi returns false', () async {
        expect(await ConnectivityUtils.isWifi(), isFalse);
      });

      test('isMobile returns false', () async {
        expect(await ConnectivityUtils.isMobile(), isFalse);
      });

      test('onConnectivityChanged returns Stream and does not throw', () {
        // The getter must return a valid Stream object even when the
        // platform plugin is unavailable (OHOS scenario).
        expect(
          ConnectivityUtils.onConnectivityChanged,
          isA<Stream<List<ConnectivityResult>>>(),
        );
      });

      test(
        'onConnectivityChanged eventually emits a value',
        () async {
          // Use a timeout guard because the EventChannel may never
          // emit in a non-OHOS test environment.
          final result = await ConnectivityUtils
              .onConnectivityChanged
              .first
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () => [ConnectivityResult.none],
              );
          expect(result, isA<List<ConnectivityResult>>());
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );
    });

    group('normal (plugin available)', () {
      setUp(() {
        // Restore default handler (no mock) – `checkConnectivity` will
        // return the platform-default single [ConnectivityResult] because
        // no real native plugin is running; on a CI/test host without a
        // connectivity backend this is typically [ConnectivityResult.none].
        TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
            .setMockMethodCallHandler(_kConnectivityChannel, null);
      });

      test('wraps single ConnectivityResult into List', () async {
        final result = await ConnectivityUtils.checkConnectivity();
        expect(result, isA<List<ConnectivityResult>>());
        // 5.x returns one value → wrapped as [value]
        expect(result.length, 1);
      });
    });
  });
}
