import 'package:PiliPlus/grpc/bilibili/main/community/reply/v1.pb.dart'
    show MainListReply, VoteCard, ReplyInfo;
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/common/common_list_controller.dart';

mixin ReplyVoteMixin on CommonListController<MainListReply, ReplyInfo> {
  VoteCard? voteCard;

  @override
  bool customHandleResponse(bool isRefresh, Success<dynamic> response) {
    if (isRefresh && response.response is MainListReply) {
      final res = response.response as MainListReply;
      if (res.hasVoteCard()) {
        voteCard = res.voteCard;
      }
    }
    return super.customHandleResponse(isRefresh, response as Success<MainListReply>);
  }
}
