import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';

/// Adapter wrapping connectivity_plus 5.x (single [ConnectivityResult]) into
/// the 7.x+ API style (List<ConnectivityResult>), so PiliPlusX code using
/// `.contains()` compiles unchanged on the OHOS platform.
abstract final class ConnectivityUtils {
  /// Returns the current connectivity status as a list (7.x+ style).
  ///
  /// On 5.x, [checkConnectivity] returns a single [ConnectivityResult]; this
  /// method wraps it into a one-element list.  If the platform plugin is
  /// unavailable (e.g. OHOS emulator), [MissingPluginException] is caught and
  /// [ConnectivityResult.none] is returned.
  static Future<List<ConnectivityResult>> checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return [result];
    } on MissingPluginException {
      return [ConnectivityResult.none];
    }
  }

  /// Stream of connectivity changes (7.x+ style).
  ///
  /// Each 5.x [ConnectivityResult] event is wrapped into a one-element list.
  /// If the platform plugin is unavailable the stream emits
  /// [ConnectivityResult.none] once.
  static Stream<List<ConnectivityResult>> get onConnectivityChanged async* {
    try {
      await for (final result in Connectivity().onConnectivityChanged) {
        yield [result];
      }
    } on MissingPluginException {
      yield [ConnectivityResult.none];
    }
  }

  /// Whether the device is connected via Wi-Fi.
  static Future<bool> isWifi() async {
    final results = await checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }

  /// Whether the device is connected via mobile data.
  static Future<bool> isMobile() async {
    final results = await checkConnectivity();
    return results.contains(ConnectivityResult.mobile);
  }

  /// Whether the device has no connectivity.
  static Future<bool> isNone() async {
    final results = await checkConnectivity();
    return results.contains(ConnectivityResult.none);
  }
}
