import 'package:PiliPlus/grpc/bilibili/main/community/reply/v1.pb.dart'
    show VoteCard;
import 'package:PiliPlus/pages/video/reply/vote/reply_vote_item.dart'
    show buildVoteCard;
import 'package:PiliPlus/pages/video/reply/vote/reply_vote_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixnum/fixnum.dart';

void main() {
  group('buildVoteCard', () {
    testWidgets('renders vote card with title and count', (tester) async {
      final voteCard = VoteCard(
        voteId: Int64(123),
        title: '最喜欢的视频',
        count: Int64(42),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildVoteCard(
              tester.element(find.byType(MaterialApp)),
              const ColorScheme.light(),
              voteCard,
            ),
          ),
        ),
      );

      // Should show vote title
      expect(find.text('最喜欢的视频'), findsOneWidget);
    });
  });
}
