import 'package:flutter_test/flutter_test.dart';
import 'package:PiliPlus/utils/bili_utils.dart';

void main() {
  group('BiliUtils', () {
    group('isDefaultFav', () {
      test('returns false for null input', () {
        expect(BiliUtils.isDefaultFav(null), false);
      });

      test('returns true when bit 1 is 0 (attr=0)', () {
        // attr=0: bit 1 (0x2) is 0 → isDefaultFav = true
        expect(BiliUtils.isDefaultFav(0), true);
      });

      test('returns true when bit 1 is 0 (attr=1)', () {
        // attr=1: binary 01, bit 1 (0x2) is 0 → isDefaultFav = true
        expect(BiliUtils.isDefaultFav(1), true);
      });

      test('returns false when bit 1 is set (attr=2)', () {
        // attr=2: binary 10, bit 1 (0x2) is 1 → isDefaultFav = false
        expect(BiliUtils.isDefaultFav(2), false);
      });

      test('returns false when bit 1 is set (attr=3)', () {
        // attr=3: binary 11, bit 1 (0x2) is 1 → isDefaultFav = false
        expect(BiliUtils.isDefaultFav(3), false);
      });
    });

    group('isPublicFav', () {
      test('returns true when bit 0 is 0 (even numbers)', () {
        expect(BiliUtils.isPublicFav(0), true);
        expect(BiliUtils.isPublicFav(2), true);
        expect(BiliUtils.isPublicFav(4), true);
      });

      test('returns false when bit 0 is 1 (odd numbers)', () {
        expect(BiliUtils.isPublicFav(1), false);
        expect(BiliUtils.isPublicFav(3), false);
      });
    });

    group('isPublicFavText', () {
      test('returns empty string for null attr', () {
        expect(BiliUtils.isPublicFavText(null), '');
      });

      test('returns 公开 for public fav', () {
        expect(BiliUtils.isPublicFavText(0), '公开');
        expect(BiliUtils.isPublicFavText(2), '公开');
      });

      test('returns 私密 for private fav', () {
        expect(BiliUtils.isPublicFavText(1), '私密');
        expect(BiliUtils.isPublicFavText(3), '私密');
      });
    });

    group('isCustomFollowTag', () {
      test('returns false for null tagid', () {
        expect(BiliUtils.isCustomFollowTag(null), false);
      });

      test('returns false for tagid 0', () {
        expect(BiliUtils.isCustomFollowTag(0), false);
      });

      test('returns false for tagid -10', () {
        expect(BiliUtils.isCustomFollowTag(-10), false);
      });

      test('returns false for tagid -2', () {
        expect(BiliUtils.isCustomFollowTag(-2), false);
      });

      test('returns true for other tagids', () {
        expect(BiliUtils.isCustomFollowTag(1), true);
        expect(BiliUtils.isCustomFollowTag(-1), true);
        expect(BiliUtils.isCustomFollowTag(100), true);
        expect(BiliUtils.isCustomFollowTag(-5), true);
      });
    });
  });
}
