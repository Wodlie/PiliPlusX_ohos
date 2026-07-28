import 'package:flutter_test/flutter_test.dart';
import 'package:PiliPlus/models_new/member_guard/data.dart';
import 'package:PiliPlus/models_new/member_guard/guard_top_list.dart';

void main() {
  group('GuardItem', () {
    test('fromJson parses all required fields', () {
      final json = {
        'uid': 123456,
        'username': 'GuardUser',
        'face': 'https://example.com/face.png',
        'guard_level': 3,
      };
      final result = GuardItem.fromJson(json);
      expect(result.uid, 123456);
      expect(result.username, 'GuardUser');
      expect(result.face, 'https://example.com/face.png');
      expect(result.guardLevel, 3);
    });

    test('fromJson parses int uid correctly', () {
      final json = {
        'uid': 789012,
        'username': 'AnotherGuard',
        'face': 'https://example.com/face2.png',
        'guard_level': 1,
      };
      final result = GuardItem.fromJson(json);
      expect(result.uid, 789012);
      expect(result.username, 'AnotherGuard');
      expect(result.guardLevel, 1);
    });
  });

  group('MemberGuardData', () {
    test('fromJson parses guard list and hasMore', () {
      final json = {
        'guard_top_list': [
          {
            'uid': 111,
            'username': 'UserA',
            'face': 'https://face.a',
            'guard_level': 2,
          },
          {
            'uid': 222,
            'username': 'UserB',
            'face': 'https://face.b',
            'guard_level': 3,
          },
        ],
        'has_more': 1,
      };
      final result = MemberGuardData.fromJson(json);
      expect(result.guardTopList, hasLength(2));
      expect(result.guardTopList[0].uid, 111);
      expect(result.guardTopList[0].username, 'UserA');
      expect(result.guardTopList[1].guardLevel, 3);
      expect(result.hasMore, 1);
    });

    test('fromJson handles empty guard list', () {
      final json = {
        'guard_top_list': <dynamic>[],
        'has_more': 0,
      };
      final result = MemberGuardData.fromJson(json);
      expect(result.guardTopList, isEmpty);
      expect(result.hasMore, 0);
    });

    test('fromJson handles null hasMore', () {
      final json = {
        'guard_top_list': <dynamic>[],
      };
      final result = MemberGuardData.fromJson(json);
      expect(result.guardTopList, isEmpty);
      expect(result.hasMore, isNull);
    });
  });
}
