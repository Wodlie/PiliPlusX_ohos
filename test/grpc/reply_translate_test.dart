import 'package:PiliPlus/grpc/bilibili/main/community/reply/v1.pb.dart'
    show ReplyInfo;
import 'package:PiliPlus/grpc/reply_translate.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TranslateReplyReq', () {
    test('constructs with all fields', () {
      final req = TranslateReplyReq(
        type: Int64(1),
        oid: Int64(12345),
        rpids: [Int64(67890), Int64(111213)],
      );

      expect(req.type, Int64(1));
      expect(req.oid, Int64(12345));
      expect(req.rpids, [Int64(67890), Int64(111213)]);
    });

    test('constructs with no fields (defaults)', () {
      final req = TranslateReplyReq();

      expect(req.hasType(), isFalse);
      expect(req.hasOid(), isFalse);
      expect(req.rpids, isEmpty);
    });

    test('constructs with partial fields', () {
      final req = TranslateReplyReq(type: Int64(2));

      expect(req.type, Int64(2));
      expect(req.hasOid(), isFalse);
      expect(req.rpids, isEmpty);
    });

    test('serializes and deserializes via buffer round-trip', () {
      final req = TranslateReplyReq(
        type: Int64(1),
        oid: Int64(99999),
        rpids: [Int64(100), Int64(200), Int64(300)],
      );

      final bytes = req.writeToBuffer();
      final restored = TranslateReplyReq.fromBuffer(bytes);

      expect(restored.type, Int64(1));
      expect(restored.oid, Int64(99999));
      expect(restored.rpids, [Int64(100), Int64(200), Int64(300)]);
    });

    test('serializes and deserializes via JSON round-trip', () {
      final req = TranslateReplyReq(
        type: Int64(3),
        oid: Int64(555),
        rpids: [Int64(777)],
      );

      final json = req.writeToJson();
      final restored = TranslateReplyReq.fromJson(json);

      expect(restored.type, Int64(3));
      expect(restored.oid, Int64(555));
      expect(restored.rpids, [Int64(777)]);
    });

    test('getDefault returns a default instance', () {
      final defaultInstance = TranslateReplyReq.getDefault();

      expect(defaultInstance.hasType(), isFalse);
      expect(defaultInstance.hasOid(), isFalse);
      expect(defaultInstance.rpids, isEmpty);
    });

    test('clone creates a deep copy', () {
      final req = TranslateReplyReq(
        type: Int64(5),
        oid: Int64(42),
        rpids: [Int64(1)],
      );

      // ignore: deprecated_member_use
      final cloned = req.clone();

      expect(cloned.type, Int64(5));
      expect(cloned.oid, Int64(42));
      expect(cloned.rpids, [Int64(1)]);

      // Modify original to verify deep copy
      // ignore: deprecated_member_use
      req.copyWith((m) {
        m.type = Int64(0);
        m.oid = Int64(0);
        m.rpids.clear();
      });

      expect(cloned.type, Int64(5));
      expect(cloned.oid, Int64(42));
      expect(cloned.rpids, [Int64(1)]);
    });

    test('clear methods reset fields', () {
      final req = TranslateReplyReq(
        type: Int64(1),
        oid: Int64(2),
        rpids: [Int64(3)],
      );

      req.clearType();
      expect(req.hasType(), isFalse);

      req.clearOid();
      expect(req.hasOid(), isFalse);
    });
  });

  group('TranslateReplyResp', () {
    test('constructs with translatedReplies map', () {
      final replyInfo = ReplyInfo();
      final resp = TranslateReplyResp(
        translatedReplies: {
          MapEntry(Int64(12345), replyInfo),
        },
      );

      expect(resp.translatedReplies, hasLength(1));
      expect(resp.translatedReplies[Int64(12345)], same(replyInfo));
    });

    test('constructs with no fields (defaults)', () {
      final resp = TranslateReplyResp();
      expect(resp.translatedReplies, isEmpty);
    });

    test('serializes and deserializes via buffer round-trip', () {
      final replyInfo = ReplyInfo.create();
      final resp = TranslateReplyResp(
        translatedReplies: {
          MapEntry(Int64(42), replyInfo),
        },
      );

      final bytes = resp.writeToBuffer();
      final restored = TranslateReplyResp.fromBuffer(bytes);

      expect(restored.translatedReplies, hasLength(1));
      expect(restored.translatedReplies.containsKey(Int64(42)), isTrue);
    });

    test('getDefault returns a default instance', () {
      final defaultInstance = TranslateReplyResp.getDefault();
      expect(defaultInstance.translatedReplies, isEmpty);
    });
  });
}
