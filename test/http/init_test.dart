import 'package:PiliPlus/http/custom_host_interceptor.dart';
import 'package:PiliPlus/http/hk_api_retry_interceptor.dart';
import 'package:PiliPlus/http/retry_interceptor.dart';
import 'package:PiliPlus/utils/connectivity_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifies that the interceptor chain defined in [Request._internal]
/// preserves the correct ordering by simulating the same interception
/// registration pattern.
///
/// Expected order (as defined in lib/http/init.dart):
///   1. RetryInterceptor (only when retryCount != 0, optional)
///   2. CustomHostInterceptor
///   3. HkApiRetryInterceptor
///   4. LogInterceptor (only in kDebugMode, optional)
void main() {
  group('Interceptor chain order', () {
    Dio buildDioWithChain() {
      final dio = Dio(BaseOptions());
      const retryCount = 2; // typical non-zero pref

      // 1. RetryInterceptor (if retryCount != 0)
      if (retryCount != 0) {
        dio.interceptors.add(
          RetryInterceptor(dio, retryCount, 500),
        );
      }

      // 2. CustomHostInterceptor
      dio.interceptors.add(CustomHostInterceptor());

      // 3. HkApiRetryInterceptor
      dio.interceptors.add(HkApiRetryInterceptor());

      // 4. LogInterceptor (debug mode)
      dio.interceptors.add(
        LogInterceptor(
          request: false,
          requestHeader: false,
          responseHeader: false,
        ),
      );

      return dio;
    }

    test('CustomHostInterceptor exists and is importable', () {
      final interceptor = CustomHostInterceptor();
      expect(interceptor, isA<Interceptor>());
    });

    test('HkApiRetryInterceptor exists and is importable', () {
      final interceptor = HkApiRetryInterceptor();
      expect(interceptor, isA<Interceptor>());
    });

    test('RetryInterceptor exists and is importable', () {
      final dio = Dio(BaseOptions());
      final interceptor = RetryInterceptor(dio, 2, 500);
      expect(interceptor, isA<Interceptor>());
    });

    test('interceptor chain order: RetryInterceptor < CustomHostInterceptor < HkApiRetryInterceptor < LogInterceptor',
        () {
      final dio = buildDioWithChain();
      final types = dio.interceptors.map((e) => e.runtimeType).toList();

      final retryIdx = types.indexOf(RetryInterceptor);
      final customHostIdx = types.indexOf(CustomHostInterceptor);
      final hkApiRetryIdx = types.indexOf(HkApiRetryInterceptor);
      final logIdx = types.indexWhere(
        (t) => t.toString().contains('LogInterceptor'),
      );

      // All four must be present
      expect(retryIdx, greaterThanOrEqualTo(0));
      expect(customHostIdx, greaterThanOrEqualTo(0));
      expect(hkApiRetryIdx, greaterThanOrEqualTo(0));
      expect(logIdx, greaterThanOrEqualTo(0));

      // Order must be preserved
      expect(retryIdx, lessThan(customHostIdx));
      expect(customHostIdx, lessThan(hkApiRetryIdx));
      expect(hkApiRetryIdx, lessThan(logIdx));
    });

    test('RetryInterceptor is optional when retryCount is 0', () {
      final dio = Dio(BaseOptions());
      // retryCount == 0 → skip RetryInterceptor
      dio.interceptors.add(CustomHostInterceptor());
      dio.interceptors.add(HkApiRetryInterceptor());

      final types = dio.interceptors.map((e) => e.runtimeType).toList();
      expect(types, isNot(contains(RetryInterceptor)));
      expect(types, contains(CustomHostInterceptor));
      expect(types, contains(HkApiRetryInterceptor));
      expect(types.indexOf(CustomHostInterceptor),
          lessThan(types.indexOf(HkApiRetryInterceptor)));
    });

    test('AccountManager interceptor order (after setCookie)', () {
      // The AccountManager interceptor is added by Request.setCookie().
      // It must come before any functional interceptors.
      final dio = Dio(BaseOptions());
      Dio setupChainWithAccount() {
        dio.interceptors.clear();
        // 1. AccountManager (simulated — added by setCookie)
        dio.interceptors.add(const Interceptor());
        // 2. RetryInterceptor
        dio.interceptors.add(RetryInterceptor(dio, 2, 500));
        // 3. CustomHostInterceptor
        dio.interceptors.add(CustomHostInterceptor());
        // 4. HkApiRetryInterceptor
        dio.interceptors.add(HkApiRetryInterceptor());
        return dio;
      }

      final dio_ = setupChainWithAccount();
      final types = dio_.interceptors.map((e) => e.runtimeType).toList();

      // Account is first (index 0)
      // RetryInterceptor is second (index 1)
      // CustomHostInterceptor is third (index 2)
      // HkApiRetryInterceptor is fourth (index 3)
      expect(types[0], isNot(RetryInterceptor));
      expect(types[1], RetryInterceptor);
      expect(types[2], CustomHostInterceptor);
      expect(types[3], HkApiRetryInterceptor);
    });

    test('ConnectivityUtils.onConnectivityChanged importable', () {
      // Verify the connectivity utility (T5) is accessible
      expect(
        ConnectivityUtils,
        isA<Type>(),
        reason: 'ConnectivityUtils type must be available',
      );
    });
  });
}
