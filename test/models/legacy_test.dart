import 'package:PiliPlus/models/common/video/ai_summary_service.dart';
import 'package:PiliPlus/models/horizontal_video_model.dart';
import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/models_new/video/video_detail/dimension.dart';
import 'package:flutter_test/flutter_test.dart';

/// Concrete subclass of [HorizontalVideoModel] for testing.
class TestHorizontalVideoModel extends HorizontalVideoModel {
  @override
  int? aid;

  @override
  String? desc;

  @override
  int? pubdate;

  @override
  bool isFollowed = false;

  @override
  String title = '';

  @override
  String? bvid;

  @override
  int? cid;

  @override
  String? cover;

  @override
  int duration = -1;

  @override
  late BaseOwner owner;

  @override
  late BaseStat stat;

  TestHorizontalVideoModel({this.title = ''}) {
    owner = _TestOwner(mid: 0, name: '');
    stat = _TestStat();
  }

  factory TestHorizontalVideoModel.withAllFields({
    required String title,
    String? bvid,
    int? cid,
    String? cover,
    int duration = -1,
    int? aid,
    String? desc,
    int? pubdate,
    bool isFollowed = false,
    bool? isPugv,
    int? seasonId,
    int? roomId,
    bool? isLive,
    Dimension? dimension,
    String? badge,
    num? progress,
    String? redirectUrl,
    List<({bool isEm, String text})>? titleList,
  }) {
    final model = TestHorizontalVideoModel(title: title)
      ..aid = aid
      ..desc = desc
      ..pubdate = pubdate
      ..isFollowed = isFollowed
      ..bvid = bvid
      ..cid = cid
      ..cover = cover
      ..duration = duration;
    model.isPugv = isPugv;
    model.seasonId = seasonId;
    model.roomId = roomId;
    model.isLive = isLive;
    model.dimension = dimension;
    model.badge = badge;
    model.progress = progress;
    model.redirectUrl = redirectUrl;
    model.titleList = titleList;
    return model;
  }
}

class _TestOwner extends BaseOwner {
  @override
  int? mid;
  @override
  String? name;

  _TestOwner({this.mid, this.name});
}

class _TestStat extends BaseStat {
  @override
  int? view;
  @override
  int? like;
  @override
  int? danmu;
}

class TestDimension extends Dimension {
  final int? width;
  final int? height;
  final bool? rotate;

  TestDimension({this.width, this.height, this.rotate});
}

void main() {
  group('AiSummaryService', () {
    test('has three values', () {
      expect(AiSummaryService.values.length, 3);
    });

    test('subtitleAi has correct label', () {
      expect(AiSummaryService.subtitleAi.label, '字幕 AI 总结');
    });

    test('multimodalAi has correct label', () {
      expect(AiSummaryService.multimodalAi.label, '多模态 AI 总结');
    });

    test('bilibiliLegacyDeprecated has correct label', () {
      expect(
        AiSummaryService.bilibiliLegacyDeprecated.label,
        '哔哩哔哩 AI 总结',
      );
    });

    test('labels are const', () {
      const service = AiSummaryService.subtitleAi;
      expect(service.label, '字幕 AI 总结');
    });
  });

  group('HorizontalVideoModel', () {
    test('concrete subclass stores all fields', () {
      final dimension = TestDimension(width: 1920, height: 1080, rotate: false);
      final model = TestHorizontalVideoModel.withAllFields(
        title: 'Test Video',
        bvid: 'BV1xx411c7mD',
        cid: 100,
        cover: 'https://example.com/cover.jpg',
        duration: 300,
        aid: 42,
        desc: 'A test video description',
        pubdate: 1700000000,
        isPugv: false,
        seasonId: 5,
        roomId: 123,
        isLive: false,
        dimension: dimension,
        badge: '独家',
        progress: 0.5,
        redirectUrl: 'https://example.com/redirect',
        titleList: [
          (isEm: false, text: 'Test'),
          (isEm: true, text: 'Video'),
        ],
      );

      expect(model.title, 'Test Video');
      expect(model.bvid, 'BV1xx411c7mD');
      expect(model.cid, 100);
      expect(model.cover, 'https://example.com/cover.jpg');
      expect(model.duration, 300);
      expect(model.aid, 42);
      expect(model.desc, 'A test video description');
      expect(model.pubdate, 1700000000);
      expect(model.isPugv, isFalse);
      expect(model.seasonId, 5);
      expect(model.roomId, 123);
      expect(model.isLive, isFalse);
      expect(model.dimension, same(dimension));
      expect(model.badge, '独家');
      expect(model.progress, 0.5);
      expect(model.redirectUrl, 'https://example.com/redirect');
      expect(model.titleList, hasLength(2));
      expect(model.titleList![0].text, 'Test');
      expect(model.titleList![1].text, 'Video');
    });

    test('inherits BaseVideoItemModel defaults', () {
      final model = TestHorizontalVideoModel(title: 'Minimal');
      expect(model.isFollowed, isFalse);
      expect(model.duration, -1);
      expect(model.owner, isA<BaseOwner>());
      expect(model.stat, isA<BaseStat>());
    });
  });
}
