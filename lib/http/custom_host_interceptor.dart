import 'package:PiliPlus/http/api_hosts.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:dio/dio.dart';

/// Custom host URL rewriting interceptor for the Dio HTTP client.
///
/// Replaces official BiliBili API hosts with user-configured custom hosts
/// (configured via settings → custom API hosts).
///
/// Registered before [HkApiRetryInterceptor] in the interceptor chain,
/// so URL rewriting happens before HK retry logic.
class CustomHostInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 1. Check master toggle
    if (!Pref.enableCustomApiHost) {
      return handler.next(options);
    }

    // 2. Priority check: if HK proxy is configured, skip GET requests
    //    so the HK retry interceptor handles them on failure.
    if (Pref.apiHKUrl.isNotEmpty && options.method.toUpperCase() == 'GET') {
      return handler.next(options);
    }

    // 3. Build host mapping: officialHost -> customHost
    final Map<String, String> hostMap = {};
    for (final entry in apiHostEntries) {
      final customHost =
          GStorage.setting.get(entry.settingKey, defaultValue: '') as String;
      if (customHost.isNotEmpty) {
        hostMap[entry.defaultHost] = customHost;
      }
    }

    if (hostMap.isEmpty) {
      return handler.next(options);
    }

    // 4. Handle full URLs (options.path starts with http)
    if (options.path.startsWith('http')) {
      final uri = Uri.parse(options.path);
      final origin = '${uri.scheme}://${uri.host}';

      if (hostMap.containsKey(origin)) {
        final customUri = Uri.parse(hostMap[origin]!);
        options.path = uri
            .replace(
              scheme: customUri.scheme,
              host: customUri.host,
              port: customUri.port,
            )
            .toString();
      }
    } else {
      // 5. Handle relative paths: check options.baseUrl
      if (hostMap.containsKey(options.baseUrl)) {
        options.baseUrl = hostMap[options.baseUrl]!;
      }
    }

    handler.next(options);
  }
}
