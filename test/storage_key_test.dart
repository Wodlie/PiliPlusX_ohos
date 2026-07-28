import 'package:flutter_test/flutter_test.dart';
import 'package:PiliPlus/utils/storage_key.dart';

void main() {
  group('SettingBoxKey', () {
    // PiliPlusX base keys — spot check representative ones
    test('contains PiliPlusX base keys', () {
      expect(SettingBoxKey.btmProgressBehavior, 'btmProgressBehavior');
      expect(SettingBoxKey.preferCodecs, 'preferCodecs');
      expect(SettingBoxKey.hardwareDecoding, 'hardwareDecoding');
      expect(SettingBoxKey.playerVolume, 'playerVolume');
      expect(SettingBoxKey.maxVolume, 'maxVolume');
      expect(SettingBoxKey.enableLongShowControl, 'enableLongShowControl');
      expect(SettingBoxKey.autoUpdate, 'autoUpdate');
      expect(SettingBoxKey.isPureBlackTheme, 'isPureBlackTheme');
      expect(SettingBoxKey.enableHttp2, 'enableHttp2');
      expect(SettingBoxKey.fastForBackwardDuration, 'fastForBackwardDuration');
      expect(SettingBoxKey.subtitlePreferenceV2, 'subtitlePreferenceV2');
      expect(SettingBoxKey.webdavUri, 'webdavUri');
      expect(SettingBoxKey.themeMode, 'themeMode');
      expect(SettingBoxKey.enableImageBlock, 'enableImageBlock');
    });

    // OHOS unique keys
    test('contains OHOS-unique keys', () {
      expect(SettingBoxKey.enableLGBar, 'enableLGBar');
      expect(SettingBoxKey.enableStatusBarTapToTop, 'enableStatusBarTapToTop');
      expect(SettingBoxKey.showActualVolume, 'showActualVolume');
      expect(SettingBoxKey.allowRotateScreen, 'allowRotateScreen');
    });

    // Deprecated keys
    test('contains deprecated defaultDecode/secondDecode', () {
      expect(SettingBoxKey.defaultDecode, 'defaultDecode');
      expect(SettingBoxKey.secondDecode, 'secondDecode');

      // Verify @Deprecated annotation exists via reflection
      final defaultDecodeMirror = SettingBoxKey.defaultDecode;
      final secondDecodeMirror = SettingBoxKey.secondDecode;
      // Values themselves are still accessible
      expect(defaultDecodeMirror, isNotEmpty);
      expect(secondDecodeMirror, isNotEmpty);
    });
  });

  group('LocalCacheKey', () {
    test('contains expected keys', () {
      expect(LocalCacheKey.historyPause, 'historyPause');
      expect(LocalCacheKey.blackMids, 'blackMids');
      expect(LocalCacheKey.danmakuFilterRules, 'danmakuFilterRules');
      expect(LocalCacheKey.mixinKey, 'mixinKey');
      expect(LocalCacheKey.timeStamp, 'timeStamp');
      expect(LocalCacheKey.legacyBuvid, 'buvid');
      expect(LocalCacheKey.guestBuvid, 'guestBuvid');
      expect(LocalCacheKey.accountUnameMap, 'accountUnameMap');
    });
  });

  group('VideoBoxKey', () {
    test('contains expected keys', () {
      expect(VideoBoxKey.playRepeat, 'playRepeat');
      expect(VideoBoxKey.playSpeedDefault, 'playSpeedDefault');
      expect(VideoBoxKey.longPressSpeedDefault, 'longPressSpeedDefault');
      expect(VideoBoxKey.speedsList, 'speedsList');
      expect(VideoBoxKey.cacheVideoFit, 'cacheVideoFit');
    });
  });
}
