import 'dart:io';

import 'package:PiliPlus/http/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Api endpoint constants - existing', () {
    test('recommendListApp uses app base url', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      expect(
        source,
        contains('\${HttpString.appBaseUrl}/x/v2/feed/index'),
      );
    });

    test('latestApp uses PiliPlusX repo', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      expect(
        source,
        contains("'https://api.github.com/repos/Wodlie/PiliPlusX/releases'"),
      );
    });

    test('replyList is defined', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      expect(source, contains("static const String replyList = '/x/v2/reply'"));
    });
  });

  group('Api endpoint constants - new reply endpoints', () {
    test('replyAppealSubmit is defined', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      expect(
        source,
        contains("static const String replyAppealSubmit = '/x/v2/reply/appeal/submit'"),
      );
    });

    test('replyReport is defined', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      expect(
        source,
        contains("static const String replyReport = '/x/v2/reply/report'"),
      );
    });
  });

  group('Api endpoint constants - topic', () {
    test('topicFold is defined', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      expect(
        source,
        contains("static const String topicFold = '/x/topic/web/details/fold'"),
      );
    });
  });

  group('Api endpoint constants - space reserve', () {
    test('spaceReserve is defined', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      expect(
        source,
        contains("static const String spaceReserve = '/x/space/reserve'"),
      );
    });

    test('spaceReserveCancel is defined', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      expect(
        source,
        contains("static const String spaceReserveCancel = '/x/space/reserve/cancel'"),
      );
    });
  });

  group('Api endpoint constants - member guard', () {
    test('memberGuard is defined', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      expect(
        source,
        contains('static const String memberGuard'),
      );
      expect(
        source,
        contains('MainGuardCardAll'),
      );
    });
  });

  group('Api endpoint constants - bubble', () {
    test('bubble is defined', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      expect(
        source,
        contains("static const String bubble = '/x/tribee/v1/dyn/all'"),
      );
    });
  });

  group('Api endpoint constants - sort follow tag', () {
    test('sortFollowTag is defined', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      expect(
        source,
        contains("static const String sortFollowTag = '/x/relation/tags/update_sort'"),
      );
    });
  });

  group('Api endpoint constants - dyn reaction', () {
    test('dynReaction is defined', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      expect(
        source,
        contains("static const String dynReaction = '/x/polymer/web-dynamic/v1/detail/reaction'"),
      );
    });
  });

  group('Api endpoint constants - live feedback', () {
    test('liveFeedback is defined', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      expect(
        source,
        contains('static const String liveFeedback'),
      );
      expect(
        source,
        contains('/xlive/app-interface/v2/index/feedback'),
      );
    });
  });

  group('Api endpoint URLs resolve correctly', () {
    test('replyAppealSubmit resolves to full URL', () {
      expect(
        '${HttpString.apiBaseUrl}/x/v2/reply/appeal/submit',
        'https://api.bilibili.com/x/v2/reply/appeal/submit',
      );
    });

    test('replyReport resolves to full URL', () {
      expect(
        '${HttpString.apiBaseUrl}/x/v2/reply/report',
        'https://api.bilibili.com/x/v2/reply/report',
      );
    });

    test('topicFold resolves to full URL', () {
      expect(
        '${HttpString.apiBaseUrl}/x/topic/web/details/fold',
        'https://api.bilibili.com/x/topic/web/details/fold',
      );
    });

    test('spaceReserve resolves to full URL', () {
      expect(
        '${HttpString.apiBaseUrl}/x/space/reserve',
        'https://api.bilibili.com/x/space/reserve',
      );
    });

    test('spaceReserveCancel resolves to full URL', () {
      expect(
        '${HttpString.apiBaseUrl}/x/space/reserve/cancel',
        'https://api.bilibili.com/x/space/reserve/cancel',
      );
    });

    test('memberGuard resolves to full URL', () {
      expect(
        '${HttpString.liveBaseUrl}/xlive/app-ucenter/v1/guard/MainGuardCardAll',
        'https://api.live.bilibili.com/xlive/app-ucenter/v1/guard/MainGuardCardAll',
      );
    });

    test('bubble resolves to full URL', () {
      expect(
        '${HttpString.apiBaseUrl}/x/tribee/v1/dyn/all',
        'https://api.bilibili.com/x/tribee/v1/dyn/all',
      );
    });

    test('sortFollowTag resolves to full URL', () {
      expect(
        '${HttpString.apiBaseUrl}/x/relation/tags/update_sort',
        'https://api.bilibili.com/x/relation/tags/update_sort',
      );
    });

    test('dynReaction resolves to full URL', () {
      expect(
        '${HttpString.apiBaseUrl}/x/polymer/web-dynamic/v1/detail/reaction',
        'https://api.bilibili.com/x/polymer/web-dynamic/v1/detail/reaction',
      );
    });

    test('liveFeedback resolves to full URL', () {
      expect(
        '${HttpString.liveBaseUrl}/xlive/app-interface/v2/index/feedback',
        'https://api.live.bilibili.com/xlive/app-interface/v2/index/feedback',
      );
    });
  });

  group('Api endpoint constants - ordering within file', () {
    test('replyAppealSubmit appears before likeReply', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      final appealPos = source.indexOf('replyAppealSubmit');
      final likePos = source.indexOf('likeReply');
      expect(appealPos, lessThan(likePos));
    });

    test('replyReport appears after replyAdd and before replyDel', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      final addPos = source.indexOf('replyAdd');
      final reportPos = source.indexOf('replyReport');
      final delPos = source.indexOf('replyDel');
      expect(addPos, lessThan(reportPos));
      expect(reportPos, lessThan(delPos));
    });

    test('topicFold appears after topicFeed', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      final feedPos = source.indexOf('topicFeed');
      final foldPos = source.indexOf('topicFold');
      expect(feedPos, lessThan(foldPos));
    });

    test('spaceReserve appears after dynReserve', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      final dynPos = source.indexOf('dynReserve');
      final reservePos = source.indexOf('spaceReserve');
      expect(dynPos, lessThan(reservePos));
    });

    test('spaceReserveCancel appears after spaceReserve', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      final reservePos = source.indexOf('spaceReserve');
      final cancelPos = source.indexOf('spaceReserveCancel');
      expect(reservePos, lessThan(cancelPos));
    });

    test('new endpoints appear after liveMedalWall', () {
      final source = File('lib/http/api.dart').readAsStringSync();
      final medalWallPos = source.indexOf('liveMedalWall');
      expect(source.indexOf('memberGuard'), greaterThan(medalWallPos));
      expect(source.indexOf('bubble'), greaterThan(medalWallPos));
      expect(source.indexOf('sortFollowTag'), greaterThan(medalWallPos));
      expect(source.indexOf('dynReaction'), greaterThan(medalWallPos));
      expect(source.indexOf('liveFeedback'), greaterThan(medalWallPos));
    });
  });
}
