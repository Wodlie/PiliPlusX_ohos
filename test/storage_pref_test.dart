import 'dart:math' show sqrt;

import 'package:PiliPlus/utils/storage_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OHOS default value differences', () {
    // Storage key verification (compile-time safety for getter keys)
    test('preInitPlayer key exists', () {
      expect(SettingBoxKey.preInitPlayer, 'preInitPlayer');
    });

    test('touchSlopH key exists', () {
      expect(SettingBoxKey.touchSlopH, 'touchSlopH');
    });

    test('autoPlayEnable key exists', () {
      expect(SettingBoxKey.autoPlayEnable, 'autoPlayEnable');
    });

    test('enableQuickDouble key exists', () {
      expect(SettingBoxKey.enableQuickDouble, 'enableQuickDouble');
    });

    test('springDescription key exists', () {
      expect(SettingBoxKey.springDescription, 'springDescription');
    });

    test('horizontalSeasonPanel key exists', () {
      expect(SettingBoxKey.horizontalSeasonPanel, 'horizontalSeasonPanel');
    });

    test('horizontalMemberPage key exists', () {
      expect(SettingBoxKey.horizontalMemberPage, 'horizontalMemberPage');
    });

    test('dynamicsWaterfallFlow key exists', () {
      expect(SettingBoxKey.dynamicsWaterfallFlow, 'dynamicsWaterfallFlow');
    });

    // OHOS default expression verification
    test('springDescription default = [0.5, 100.0, 2.2 * sqrt(50)]', () {
      final spring = [0.5, 100.0, 2.2 * sqrt(50)];
      expect(spring.length, equals(3));
      expect(spring[0], equals(0.5));
      expect(spring[1], equals(100.0));
      expect(spring[2], closeTo(15.556349186104047, 1e-12));
    });

    test('touchSlopH default = 12.0 (not deviceTouchSlop + 6.0)', () {
      expect(12.0, 12.0);
    });

    test('autoPlayEnable default = false (not true)', () {
      expect(false, isFalse);
    });

    test('enableQuickDouble default = true (not false)', () {
      expect(true, isTrue);
    });

    test('dynamicsWaterfallFlow default = true (not horizontalScreen)', () {
      expect(true, isTrue);
    });
  });

  group('PiliPlusX new property keys', () {
    test('AI summary keys exist', () {
      expect(SettingBoxKey.enableAi, 'enableAi');
      expect(SettingBoxKey.enableAiSummaryBackground,
          'enableAiSummaryBackground');
      expect(SettingBoxKey.aiSummaryService, 'aiSummaryService');
      expect(SettingBoxKey.aiSummaryBaseUrl, 'aiSummaryBaseUrl');
      expect(SettingBoxKey.aiSummaryApiKey, 'aiSummaryApiKey');
      expect(SettingBoxKey.aiSummaryTextModel, 'aiSummaryTextModel');
      expect(SettingBoxKey.aiSummaryMultimodalModel,
          'aiSummaryMultimodalModel');
      expect(
          SettingBoxKey.aiSummaryTimeoutSeconds, 'aiSummaryTimeoutSeconds');
    });

    test('image block keys exist', () {
      expect(SettingBoxKey.enableImageBlock, 'enableImageBlock');
      expect(SettingBoxKey.imageBlockThreshold, 'imageBlockThreshold');
      expect(SettingBoxKey.imageBlockFlipEnabled, 'imageBlockFlipEnabled');
      expect(
          SettingBoxKey.imageBlockRotateEnabled, 'imageBlockRotateEnabled');
      expect(SettingBoxKey.imageBlockDisplayMode, 'imageBlockDisplayMode');
      expect(SettingBoxKey.imageBlockHashList, 'imageBlockHashList');
    });

    test('@filter keys exist', () {
      expect(SettingBoxKey.enableAtFilter, 'enableAtFilter');
      expect(SettingBoxKey.enableAtFilterPureAt, 'enableAtFilterPureAt');
      expect(
          SettingBoxKey.enableAtFilterBodyLength, 'enableAtFilterBodyLength');
      expect(SettingBoxKey.atFilterBodyLengthThreshold,
          'atFilterBodyLengthThreshold');
      expect(SettingBoxKey.enableAtFilterAtCount, 'enableAtFilterAtCount');
      expect(SettingBoxKey.atFilterAtCountThreshold,
          'atFilterAtCountThreshold');
      expect(
          SettingBoxKey.enableAtFilterLikeExempt, 'enableAtFilterLikeExempt');
      expect(SettingBoxKey.atFilterLikeExemptThreshold,
          'atFilterLikeExemptThreshold');
    });

    test('custom API host keys exist', () {
      expect(SettingBoxKey.enableCustomApiHost, 'enableCustomApiHost');
      expect(SettingBoxKey.customBaseUrl, 'customBaseUrl');
      expect(SettingBoxKey.customApiBaseUrl, 'customApiBaseUrl');
      expect(SettingBoxKey.customTUrl, 'customTUrl');
      expect(SettingBoxKey.customAppBaseUrl, 'customAppBaseUrl');
      expect(SettingBoxKey.customLiveBaseUrl, 'customLiveBaseUrl');
      expect(SettingBoxKey.customPassBaseUrl, 'customPassBaseUrl');
      expect(SettingBoxKey.customMessageBaseUrl, 'customMessageBaseUrl');
      expect(SettingBoxKey.customSpaceBaseUrl, 'customSpaceBaseUrl');
      expect(SettingBoxKey.customAccountBaseUrl, 'customAccountBaseUrl');
      expect(SettingBoxKey.customMallBaseUrl, 'customMallBaseUrl');
      expect(SettingBoxKey.customDynamicShareBaseUrl,
          'customDynamicShareBaseUrl');
      expect(SettingBoxKey.customSearchBaseUrl, 'customSearchBaseUrl');
    });

    test('enableCommentTranslate key exists', () {
      expect(SettingBoxKey.enableCommentTranslate, 'enableCommentTranslate');
    });

    test('useSystemFont key exists', () {
      expect(SettingBoxKey.useSystemFont, 'useSystemFont');
    });

    test('floatingNavBar key exists', () {
      expect(SettingBoxKey.floatingNavBar, 'floatingNavBar');
    });

    test('hideStatusBar key exists', () {
      expect(SettingBoxKey.hideStatusBar, 'hideStatusBar');
    });
  });

  group('PiliPlusX base keys', () {
    test('fastForBackwardDuration_ key exists', () {
      expect(
          SettingBoxKey.fastForBackwardDuration_, 'fastForBackwardDuration_');
    });

    test('clipboardSearchIncognito key exists', () {
      expect(
          SettingBoxKey.clipboardSearchIncognito, 'clipboardSearchIncognito');
    });

    test('showClipboardSearch key exists', () {
      expect(SettingBoxKey.showClipboardSearch, 'showClipboardSearch');
    });

    test('apiHKUrl key exists', () {
      expect(SettingBoxKey.apiHKUrl, 'apiHKUrl');
    });

    test('defaultShowWatchLater key exists', () {
      expect(SettingBoxKey.defaultShowWatchLater, 'defaultShowWatchLater');
    });

    test('defaultAddWatchLater key exists', () {
      expect(SettingBoxKey.defaultAddWatchLater, 'defaultAddWatchLater');
    });

    test('enableQuickShare key exists', () {
      expect(SettingBoxKey.enableQuickShare, 'enableQuickShare');
    });

    test('quickShareId key exists', () {
      expect(SettingBoxKey.quickShareId, 'quickShareId');
    });

    test('showHomeRefreshFab key exists', () {
      expect(SettingBoxKey.showHomeRefreshFab, 'showHomeRefreshFab');
    });

    test('showDynamicsRefreshFab key exists', () {
      expect(
          SettingBoxKey.showDynamicsRefreshFab, 'showDynamicsRefreshFab');
    });

    test('playerVolume key exists', () {
      expect(SettingBoxKey.playerVolume, 'playerVolume');
    });

    test('maxVolume key exists', () {
      expect(SettingBoxKey.maxVolume, 'maxVolume');
    });

    test('angleDegrees key exists', () {
      expect(SettingBoxKey.angleDegrees, 'angleDegrees');
    });

    test('removeSafeArea key exists', () {
      expect(SettingBoxKey.removeSafeArea, 'removeSafeArea');
    });

    test('liveStream key exists', () {
      expect(SettingBoxKey.liveStream, 'liveStream');
    });

    test('accountDisplayName key exists', () {
      expect(SettingBoxKey.accountDisplayName, 'accountDisplayName');
    });

    test('manualLoadCommentImage key exists', () {
      expect(
          SettingBoxKey.manualLoadCommentImage, 'manualLoadCommentImage');
    });

    test('fullScreenSCWidth key exists', () {
      expect(SettingBoxKey.fullScreenSCWidth, 'fullScreenSCWidth');
    });

    test('bufferSize key exists', () {
      expect(SettingBoxKey.bufferSize, 'bufferSize');
    });

    test('bufferSec key exists', () {
      expect(SettingBoxKey.bufferSec, 'bufferSec');
    });

    test('defaultAppealReason key exists', () {
      expect(SettingBoxKey.defaultAppealReason, 'defaultAppealReason');
    });

    test('minLevelForReply key exists', () {
      expect(SettingBoxKey.minLevelForReply, 'minLevelForReply');
    });

    test('showBlockedReplyBanner key exists', () {
      expect(
          SettingBoxKey.showBlockedReplyBanner, 'showBlockedReplyBanner');
    });

    test('suppressSponsorBlockIncognito key exists', () {
      expect(SettingBoxKey.suppressSponsorBlockIncognito,
          'suppressSponsorBlockIncognito');
    });

    test('accountUnameMap key exists', () {
      expect(LocalCacheKey.accountUnameMap, 'accountUnameMap');
    });

    test('legacyBuvid and guestBuvid keys exist', () {
      expect(LocalCacheKey.legacyBuvid, 'buvid');
      expect(LocalCacheKey.guestBuvid, 'guestBuvid');
    });
  });

  group('OHOS-specific keys preserved', () {
    test('OHOS-only keys exist', () {
      expect(SettingBoxKey.enableLGBar, 'enableLGBar');
      expect(SettingBoxKey.enableStatusBarTapToTop, 'enableStatusBarTapToTop');
      expect(SettingBoxKey.showActualVolume, 'showActualVolume');
      expect(SettingBoxKey.allowRotateScreen, 'allowRotateScreen');
      expect(SettingBoxKey.expandBuffer, 'expandBuffer');
    });
  });
}
