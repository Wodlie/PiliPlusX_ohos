import 'package:flutter_test/flutter_test.dart';
import 'package:PiliPlus/models_new/dynamic/dyn_reaction/data.dart';
import 'package:PiliPlus/models_new/dynamic/dyn_reaction/item.dart';

void main() {
  group('DynReactionItem', () {
    test('fromJson parses all fields', () {
      final json = {
        'action': 'like',
        'face': 'https://example.com/face.png',
        'mid': '123456789',
        'name': 'ReactUser',
      };
      final result = DynReactionItem.fromJson(json);
      expect(result.action, 'like');
      expect(result.face, 'https://example.com/face.png');
      expect(result.mid, '123456789');
      expect(result.name, 'ReactUser');
    });

    test('fromJson handles null fields', () {
      final json = <String, dynamic>{};
      final result = DynReactionItem.fromJson(json);
      expect(result.action, isNull);
      expect(result.face, isNull);
      expect(result.mid, isNull);
      expect(result.name, isNull);
    });
  });

  group('DynReactionData', () {
    test('fromJson parses full structure with items', () {
      final json = {
        'has_more': true,
        'items': [
          {
            'action': 'like',
            'face': 'https://face1',
            'mid': '111',
            'name': 'User1',
          },
          {
            'action': 'dislike',
            'face': 'https://face2',
            'mid': '222',
            'name': 'User2',
          },
        ],
        'offset': 'offset_abc',
        'total': 42,
      };
      final result = DynReactionData.fromJson(json);
      expect(result.hasMore, true);
      expect(result.items, hasLength(2));
      expect(result.items![0].action, 'like');
      expect(result.items![0].name, 'User1');
      expect(result.items![1].mid, '222');
      expect(result.offset, 'offset_abc');
      expect(result.total, 42);
    });

    test('fromJson handles null items and default total', () {
      final json = {
        'has_more': false,
        'total': 0,
      };
      final result = DynReactionData.fromJson(json);
      expect(result.hasMore, false);
      expect(result.items, isNull);
      expect(result.offset, isNull);
      expect(result.total, 0);
    });

    test('fromJson defaults total to 0 when null', () {
      final json = {
        'has_more': false,
      };
      final result = DynReactionData.fromJson(json);
      expect(result.hasMore, false);
      expect(result.items, isNull);
      expect(result.total, 0);
    });
  });
}
