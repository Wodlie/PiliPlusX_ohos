/// Convenience alias matching the upstream class name used in tests.
typedef AndroidHelper = PiliAndroidHelper;

/// Stub for [PiliAndroidHelper] on OpenHarmony.
///
/// PiliAndroidHelper provides Android-specific utilities (anti-fraud, navigation,
/// music intents, link verification, PiP, shortcuts) that require JNI.
/// Not available on OHOS — all methods throw [UnsupportedError].
///
/// Callers MUST guard with `if (!OS.isHarmony && Platform.isAndroid)` checks.
abstract final class PiliAndroidHelper {
  /// Triggers Android system back navigation.
  /// Not available on OHOS — use Navigator directly.
  static void back() {
    throw UnsupportedError(
      'PiliAndroidHelper.back is not available on OHOS',
    );
  }

  /// Sends anti-fraud metadata when posting comments/replies.
  static void biliSendCommAntifraud(
    int action,
    int oid,
    int type,
    int rpId,
    int root,
    int parent,
    int ctime,
    String commentText,
    List pictures,
    String sourceId,
    int uid,
    String cookie,
  ) {
    throw UnsupportedError(
      'biliSendCommAntifraud is not available on OHOS',
    );
  }

  /// Opens Android link verification settings.
  static void openLinkVerifySettings() {
    throw UnsupportedError(
      'Link verification settings are not available on OHOS',
    );
  }

  /// Opens a music app via Android intent.
  /// Not available on OHOS — returns false (fallback to text copy).
  static bool openMusic(String title, String? artist, String? album) {
    return false;
  }

  /// Enters Android Picture-in-Picture mode.
  static void enterPip(
    int width,
    int height, {
    required bool autoEnter,
    required bool isLive,
    required bool isPlaying,
  }) {
    throw UnsupportedError(
      'PiP is not available on OHOS',
    );
  }

  /// Disables auto-enter PiP.
  static void disableAutoEnterPip() {
    throw UnsupportedError(
      'disableAutoEnterPip is not available on OHOS',
    );
  }

  /// Returns max screen size via Android API.
  /// Not available on OHOS — returns null.
  static (int, int)? maxScreenSize() {
    return null;
  }

  /// Creates a shortcut via Android API.
  static void createShortcut(
      String id, String uri, String label, String path) {
    throw UnsupportedError(
      'createShortcut is not available on OHOS',
    );
  }
}
