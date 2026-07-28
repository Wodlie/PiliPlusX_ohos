import 'package:PiliPlus/grpc/bilibili/app/archive/v1.pb.dart' as archive;
import 'package:PiliPlus/grpc/bilibili/app/interfaces/v1.pb.dart';
import 'package:PiliPlus/pages/member_search/child/widgets/search_archive_grpc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixnum/fixnum.dart';

Arc _createTestArc() {
  return Arc(
    archive: archive.Arc(
      aid: Int64(12345),
      title: 'Test Video Title',
      pic: 'https://example.com/cover.jpg',
      duration: Int64(300),
      pubdate: Int64(1700000000),
      author: archive.Author(name: 'Test Author'),
      stat: archive.Stat(view: 1000, danmaku: 50),
      firstCid: Int64(1),
      dimension: archive.Dimension(),
    ),
    isPugv: false,
    uri: '',
  );
}

void main() {
  group('SearchArchiveGrpc', () {
    testWidgets('renders video info', (tester) async {
      final item = _createTestArc();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchArchiveGrpc(item: item),
          ),
        ),
      );

      expect(find.byType(SearchArchiveGrpc), findsOneWidget);
    });

    testWidgets('handles PUGV item', (tester) async {
      final pugvItem = Arc(
        archive: archive.Arc(
          aid: Int64(999),
          title: 'Course Title',
          pic: 'https://example.com/course.jpg',
          duration: Int64(0),
          pubdate: Int64(0),
          author: archive.Author(name: 'Teacher'),
          stat: archive.Stat(view: 0, danmaku: 0),
          firstCid: Int64(1),
          dimension: archive.Dimension(),
        ),
        isPugv: true,
        uri: 'https://bilibili.com/course/999',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchArchiveGrpc(item: pugvItem),
          ),
        ),
      );

      expect(find.byType(SearchArchiveGrpc), findsOneWidget);
    });
  });
}
