import 'package:flutter_test/flutter_test.dart';
import 'package:PiliPlus/models_new/bubble/base_info.dart';
import 'package:PiliPlus/models_new/bubble/basic_info.dart';
import 'package:PiliPlus/models_new/bubble/category.dart';
import 'package:PiliPlus/models_new/bubble/category_list.dart';
import 'package:PiliPlus/models_new/bubble/content.dart';
import 'package:PiliPlus/models_new/bubble/data.dart';
import 'package:PiliPlus/models_new/bubble/dyn_list.dart';
import 'package:PiliPlus/models_new/bubble/meta.dart';
import 'package:PiliPlus/models_new/bubble/sort_info.dart';
import 'package:PiliPlus/models_new/bubble/sort_item.dart';
import 'package:PiliPlus/models_new/bubble/tribee_info.dart';

void main() {
  group('TribeInfo', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': '123',
        'title': 'Test Tribe',
        'sub_title': 'Subtitle',
        'face_url': 'https://example.com/face.png',
        'jump_uri': 'https://example.com',
        'summary': 'A test tribe',
      };
      final result = TribeInfo.fromJson(json);
      expect(result.id, '123');
      expect(result.title, 'Test Tribe');
      expect(result.subTitle, 'Subtitle');
      expect(result.faceUrl, 'https://example.com/face.png');
      expect(result.jumpUri, 'https://example.com');
      expect(result.summary, 'A test tribe');
    });

    test('fromJson handles null fields', () {
      final json = <String, dynamic>{};
      final result = TribeInfo.fromJson(json);
      expect(result.id, isNull);
      expect(result.title, isNull);
      expect(result.subTitle, isNull);
      expect(result.faceUrl, isNull);
      expect(result.jumpUri, isNull);
      expect(result.summary, isNull);
    });
  });

  group('BaseInfo', () {
    test('fromJson parses all fields', () {
      final json = {
        'tribee_info': {
          'id': '456',
          'title': 'My Tribe',
          'sub_title': 'My Sub',
          'face_url': 'https://example.com/face2.png',
          'jump_uri': 'https://example.com/2',
          'summary': 'Another tribe',
        },
        'is_joined': true,
      };
      final result = BaseInfo.fromJson(json);
      expect(result.isJoined, true);
      expect(result.tribeInfo, isA<TribeInfo>());
      expect(result.tribeInfo!.id, '456');
      expect(result.tribeInfo!.title, 'My Tribe');
    });

    test('fromJson handles null nested tribeInfo', () {
      final json = {'is_joined': false};
      final result = BaseInfo.fromJson(json);
      expect(result.isJoined, false);
      expect(result.tribeInfo, isNull);
    });
  });

  group('BasicInfo', () {
    test('fromJson parses all fields', () {
      final json = {
        'icon': 'https://example.com/icon.png',
        'title': 'Info Title',
        'jump_uri': 'https://example.com/jump',
      };
      final result = BasicInfo.fromJson(json);
      expect(result.icon, 'https://example.com/icon.png');
      expect(result.title, 'Info Title');
      expect(result.jumpUri, 'https://example.com/jump');
    });

    test('fromJson handles null fields', () {
      final json = <String, dynamic>{};
      final result = BasicInfo.fromJson(json);
      expect(result.icon, isNull);
      expect(result.title, isNull);
      expect(result.jumpUri, isNull);
    });
  });

  group('Meta', () {
    test('fromJson parses all fields', () {
      final json = {
        'author': 'User123',
        'time_text': '3小时前',
        'reply_count': '42',
        'view_stat': '1.2万',
      };
      final result = Meta.fromJson(json);
      expect(result.author, 'User123');
      expect(result.timeText, '3小时前');
      expect(result.replyCount, '42');
      expect(result.viewStat, '1.2万');
    });

    test('fromJson handles null fields', () {
      final json = <String, dynamic>{};
      final result = Meta.fromJson(json);
      expect(result.author, isNull);
      expect(result.timeText, isNull);
      expect(result.replyCount, isNull);
      expect(result.viewStat, isNull);
    });
  });

  group('DynList', () {
    test('fromJson parses all fields', () {
      final json = {
        'dyn_id': 'dyn789',
        'title': 'Dynamic Title',
        'meta': {
          'author': 'Author1',
          'time_text': '1天前',
          'reply_count': '10',
          'view_stat': '500',
        },
      };
      final result = DynList.fromJson(json);
      expect(result.dynId, 'dyn789');
      expect(result.title, 'Dynamic Title');
      expect(result.meta, isA<Meta>());
      expect(result.meta!.author, 'Author1');
      expect(result.meta!.timeText, '1天前');
    });

    test('fromJson handles null meta', () {
      final json = {'dyn_id': 'dyn000', 'title': 'No Meta'};
      final result = DynList.fromJson(json);
      expect(result.dynId, 'dyn000');
      expect(result.title, 'No Meta');
      expect(result.meta, isNull);
    });
  });

  group('Content', () {
    test('fromJson parses all fields', () {
      final json = {
        'count': '5',
        'dyn_list': [
          {'dyn_id': 'dyn1', 'title': 'First', 'meta': null},
          {'dyn_id': 'dyn2', 'title': 'Second', 'meta': null},
        ],
      };
      final result = Content.fromJson(json);
      expect(result.count, '5');
      expect(result.dynList, hasLength(2));
      expect(result.dynList![0].dynId, 'dyn1');
      expect(result.dynList![1].title, 'Second');
    });

    test('fromJson handles null dynList', () {
      final json = {'count': '0'};
      final result = Content.fromJson(json);
      expect(result.count, '0');
      expect(result.dynList, isNull);
    });
  });

  group('CategoryList', () {
    test('fromJson parses all fields', () {
      final json = {'id': 'cat1', 'name': 'Category A', 'type': 1};
      final result = CategoryList.fromJson(json);
      expect(result.id, 'cat1');
      expect(result.name, 'Category A');
      expect(result.type, 1);
    });

    test('fromJson handles null fields', () {
      final json = <String, dynamic>{};
      final result = CategoryList.fromJson(json);
      expect(result.id, isNull);
      expect(result.name, isNull);
      expect(result.type, isNull);
    });
  });

  group('Category', () {
    test('fromJson parses category list', () {
      final json = {
        'category_list': [
          {'id': 'c1', 'name': 'Hot', 'type': 0},
          {'id': 'c2', 'name': 'New', 'type': 1},
        ],
      };
      final result = Category.fromJson(json);
      expect(result.categoryList, hasLength(2));
      expect(result.categoryList![0].id, 'c1');
      expect(result.categoryList![1].name, 'New');
    });

    test('fromJson handles null categoryList', () {
      final json = <String, dynamic>{};
      final result = Category.fromJson(json);
      expect(result.categoryList, isNull);
    });
  });

  group('SortItem', () {
    test('fromJson parses all fields', () {
      final json = {'sort_type': 2, 'text': 'Most Recent'};
      final result = SortItem.fromJson(json);
      expect(result.sortType, 2);
      expect(result.text, 'Most Recent');
    });

    test('fromJson handles null fields', () {
      final json = <String, dynamic>{};
      final result = SortItem.fromJson(json);
      expect(result.sortType, isNull);
      expect(result.text, isNull);
    });
  });

  group('SortInfo', () {
    test('fromJson parses all fields', () {
      final json = {
        'show_sort': true,
        'sort_items': [
          {'sort_type': 1, 'text': 'Newest'},
          {'sort_type': 2, 'text': 'Hottest'},
        ],
        'cur_sort_type': 1,
      };
      final result = SortInfo.fromJson(json);
      expect(result.showSort, true);
      expect(result.sortItems, hasLength(2));
      expect(result.sortItems![0].sortType, 1);
      expect(result.sortItems![1].text, 'Hottest');
      expect(result.curSortType, 1);
    });

    test('fromJson handles null fields', () {
      final json = <String, dynamic>{};
      final result = SortInfo.fromJson(json);
      expect(result.showSort, isNull);
      expect(result.sortItems, isNull);
      expect(result.curSortType, isNull);
    });
  });

  group('BubbleData', () {
    test('fromJson parses full structure', () {
      final json = {
        'base_info': {
          'tribee_info': {
            'id': '1',
            'title': 'Tribe',
            'sub_title': 'Sub',
            'face_url': 'https://face',
            'jump_uri': 'https://jump',
            'summary': 'Summary',
          },
          'is_joined': true,
        },
        'content': {
          'count': '3',
          'dyn_list': [
            {'dyn_id': 'd1', 'title': 'Post 1', 'meta': null},
          ],
        },
        'category': {
          'category_list': [
            {'id': 'c1', 'name': 'All', 'type': 0},
          ],
        },
        'sort_info': {
          'show_sort': true,
          'sort_items': [
            {'sort_type': 1, 'text': 'Default'},
          ],
          'cur_sort_type': 1,
        },
      };
      final result = BubbleData.fromJson(json);
      expect(result.baseInfo, isA<BaseInfo>());
      expect(result.baseInfo!.isJoined, true);
      expect(result.content, isA<Content>());
      expect(result.content!.count, '3');
      expect(result.category, isA<Category>());
      expect(result.category!.categoryList, hasLength(1));
      expect(result.sortInfo, isA<SortInfo>());
      expect(result.sortInfo!.showSort, true);
    });

    test('fromJson handles all-null nested objects', () {
      final json = <String, dynamic>{};
      final result = BubbleData.fromJson(json);
      expect(result.baseInfo, isNull);
      expect(result.content, isNull);
      expect(result.category, isNull);
      expect(result.sortInfo, isNull);
    });
  });
}
