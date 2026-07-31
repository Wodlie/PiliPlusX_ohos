# Task 15 — 评论翻译横幅 + 评论申诉（QA 证据）

**日期:** 2026-08-01
**范围:** port-a-features Task 15（参考 A=D:\coding\PiliPlusX，改造 B=D:\coding\PiliPlusX_ohos）
**T14 前置:** reply_item_grpc 已转 StatefulWidget + `forceShowOriginalContent`（T14 完成）

## 变更文件（6 个）

| 文件 | 变更 |
|------|------|
| `lib/pages/video/reply/controller.dart` | 新增 `translatedReplies` RxMap<Int64, String> + `translateReply(ReplyInfo)`（适配 B 的 gRPC 单条签名 `translateReply(type/oid/rpid)`） |
| `lib/pages/video/reply/widgets/reply_item_grpc.dart` | 新增 `translatedText`/`isTranslating`/`onTranslate` 参数；横幅式翻译（`_buildContent` 前置"翻译中/译文"横幅，正文恒渲染 `content`）；删除旧 `_buildTranslateBtn`（内联改 `translatedContent` 替换原文的上游式实现） |
| `lib/pages/video/reply/view.dart` | 消费接线：Obx 内读 `translatedReplies.length` 触发重建 + 传 `translatedText/isTranslating/onTranslate` |
| `lib/http/reply.dart` | 恢复 `ReplyHttp.appealComment(url, reason)`（站内申诉，B 模式 `Accounts.main.csrf`） |
| `lib/http/api.dart` | 恢复 `Api.replyAppealSubmit = '/x/v2/reply/appeal/submit'` |
| `lib/utils/reply_utils.dart` | 恢复 8 状态机（normal/shadowBan/deleted/invisible/underReview/suspectedNoProblem/unknown + `replyStateDesc`）+ 站内申诉对话框（`Pref.defaultAppealReason` + `ReplyHttp.appealComment`） |

## 关键适配（相对 A 的差异）

- **B 保留签名**：`ReplyGrpc.translateReply` 为 `{required Int64 type, required Int64 oid, required Int64 rpid}` 单条（T14 已保留），controller 按此调用，不强改批量。
- **SelectableText**（B 模式）：`showReplyCheckResult` 内容用 `SelectableText(displayMessage)`，未恢复 A 的 `SelectionText`。
- **Accounts.main**（B 既有漂移）：appealComment 用 `Accounts.main.csrf`；`_checkReply` 的 biliSendCommAntifraud 分支保留 `Accounts.main.cookieJar`。
- **B 的 replyReplyList 无 `account:` 参数**：状态机调用 `isLogin: true` 时直接走 `Accounts.main`，不传 `account:`。
- **不碰**：`reply_translate.dart`（SAME）、`*.pb*.dart`、T14 屏蔽逻辑（checkBlockReason/banner）、T16 范围（canSort/长按菜单/手动加载图）。
- **view.dart 是必要接线点**：EXPECTED OUTCOME 未列 view.dart，但 `onTranslate`/`translatedText`/`isTranslating` 必须由消费方传入，否则翻译按钮不显示（`onTranslate == null` 时按钮区回退 cardLabels）。此为功能必需，非范围蔓延。

## dart analyze 验收

```bash
dart analyze --no-fatal-warnings
```

- **error 总数: 116**（T14 基线 116，不增不减）——6 个改动文件 0 error 0 warning。
- 移除 `_buildTranslateBtn` 后 `http/loading_state.dart` import 变孤儿 → 已删（避免新增 unused_import warning）。
- 删除 `utils/accounts/account.dart` import 会丢 `BiliCookieJar` extension 的 `toJson()`（`DefaultCookieJar` 无原生 toJson）→ 已恢复该 import（extension 方法算作 import 使用，无 unused 警告）。

## 测试（RED 契约）

- `grep appealComment|translateReply test/**` → **0 命中**（除 `test/grpc/reply_translate_test.dart` 引用的 pb 层 `translatedReplies` map，与本任务无关）。无 RED 测试需转绿。
- `blocked_reply_banner_test.dart`（T14）仍通过——本任务未动 BlockedReplyBanner。

## 留给 T16 的协调说明

- `reply_item_grpc.dart` 现为 `_ReplyItemGrpcState`，状态：`_expanded`（T14）+ 无手动加载图状态（T16 需加 `_loadManualImages`，原 T14 前版本有，见 A 同文件 `_buildCommentImages`）。
- 翻译按钮条件 `onTranslate != null && Pref.enableCommentTranslate && translationSwitch == TRANSLATION_SWITCH_SHOW_TRANSLATION` 占用了 buttonAction 中 `cardLabels` 分支之前的位置——T16 若在 buttonAction 增按钮注意分支顺序。
- `Pref.defaultAppealReason` 消费点已就位（reply_utils 申诉对话框），T28 设置 UI 直接写该 pref 即可。
- `forceShowOriginalContent`（T26 保存评论图消费）语义不变：true 时跳过屏蔽横幅，直接渲染 `_buildContent`。
