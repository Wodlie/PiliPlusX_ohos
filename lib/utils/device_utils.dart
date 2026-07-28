import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding, Size;
import 'package:os_type/os_type.dart';

abstract final class DeviceUtils {
  /// Android SDK int. Returns null on non-Android platforms (including HarmonyOS).
  static final int? sdkInt = OS.isHarmony ? null : null;

  static bool get isTablet {
    return size.shortestSide >= 600;
  }

  static Size get size {
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    return view.physicalSize / view.devicePixelRatio;
  }

  static String get platformName => PlatformUtils.isDesktop
      ? 'desktop'
      : isTablet
      ? 'pad'
      : 'phone';
}
