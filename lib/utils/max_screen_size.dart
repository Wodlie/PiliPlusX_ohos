import 'dart:io' show Platform;

import 'package:os_type/os_type.dart';

abstract final class MaxScreenSize {
  /// On Android this stores the maximum screen dimensions for foldable detection.
  /// On OHOS this is unused (no foldable screen concept in this context).
  static int? _maxWidth;
  static int? _maxHeight;

  /// Initializes screen size tracking.
  /// No-op on HarmonyOS where foldable screen detection is not applicable.
  static void init() {
    // Foldable screen detection is Android-only via JNI.
    // HarmonyOS devices don't support this flow.
  }

  /// Returns true if the given dimensions do NOT match the stored max screen
  /// size, indicating windowed mode.
  ///
  /// Always returns false on non-Android platforms (including HarmonyOS).
  static bool isWindowMode({required num width, required num height}) {
    if (OS.isHarmony || !Platform.isAndroid) return false;
    width = width.round();
    height = height.round();
    final hasWidthMatch = width == _maxWidth || width == _maxHeight;
    final hasHeightMatch = height == _maxWidth || height == _maxHeight;
    return !(hasWidthMatch && hasHeightMatch);
  }
}
