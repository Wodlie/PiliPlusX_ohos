import 'dart:io' show Platform;

import 'package:os_type/os_type.dart';

abstract final class PlatformUtils {
  /// Whether the current OS is a mobile OS (Android, iOS, or HarmonyOS).
  static final bool isMobile =
      Platform.isAndroid || Platform.isIOS || OS.isHarmony;

  /// Whether the current OS is a desktop OS (Windows, macOS, Linux),
  /// but NOT HarmonyOS.
  static final bool isDesktop =
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux) &&
          !OS.isHarmony;

  /// Whether the current OS is macOS or iOS.
  @pragma("vm:platform-const")
  static final bool isDarwin = Platform.isIOS || Platform.isMacOS;

  /// Whether the current OS is HarmonyOS.
  static final bool isHarmony = OS.isHarmony;
}
