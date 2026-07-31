# Task 14 Evidence — 评论客户端屏蔽体系 (checkBlockReason 5 策略 + BlockedReplyBanner)

**Date**: 2026-08-01
**Plan**: port-a-features · Task 14
**Reference**: A = `D:\coding\PiliPlusX`, B = `D:\coding\PiliPlusX_ohos`

## 1. Changed files (only 2, 按需重写不复制)

| File | What |
|------|------|
| `lib/grpc/reply.dart` | 5 策略 `checkBlockReason` + `ReplyNormalizedBody` 归一化 + `needRemoveAtGrpc` + `blockReply`/`clearBlockedReasons`/`isClientBlocked`/`getBlockReason`/`getBriefBlockReason` + `mainList`/`detailList`/`dialogList` 双模（banner 标记 / remove 移除）+ auto-page 递归。保留 B 的 `translateReply`(Int64) 签名与 pb |
| `lib/pages/video/reply/widgets/reply_item_grpc.dart` | `BlockedReplyBanner` 折叠横幅 + "查看评论"展开；`ReplyItemGrpc` Stateless→Stateful（`_expanded`）；`_buildExpandedBlocked`；子回复预览过滤 `isClientBlocked`；保留 B 全部 OHOS 代码（ExtraHitTestWidget/ColourUtils/custom_icon/SelectableText/内联翻译） |

未动：`reply_translate.dart`、`*.pb*.dart`、`text_selection.dart`、设置页/模型、控制器。

## 2. checkBlockReason 5 策略 (与 A 一致)

1. **关键词过滤** → `'关键词过滤：命中 $replyRegExp'`（`enableFilter` + `replyRegExp`）
2. **带货评论** → `'带货评论'`（`antiGoodsReply` + `needRemoveGoodGrpc`）
3. **用户等级不足** → `'用户等级不足：Lv$level < Lv$minLevelForReply'`（`minLevelForReply` 消费激活）
4. **低质量@评论** → 纯@无正文 / @数量过多(N) / 正文过短（`enableAtFilter` 系列 8 个 Pref 消费激活；`_stripReplyPrefix` 剥离"回复 @user:" 系统前缀）
5. **黑名单用户** → `GlobalData().blackMids.contains(mid)`

`Pref.showBlockedReplyBanner` 消费：`mainList`/`detailList`/`dialogList` 双模 + `reply_item_grpc` 横幅显隐。

## 3. 测试契约验证

### 3.1 `dart analyze --no-fatal-warnings`（基线 146 → **116**，−30）

| 项 | 基线 | 现在 |
|----|------|------|
| 总 errors | 146 | **116** |
| `test/block_reason_test.dart` | 23 | **0** |
| `test/blocked_reply_filter_test.dart` | 6 | **0** |
| `test/blocked_reply_banner_test.dart` | 3 | **0** |
| 改动文件 errors | — | **0** |
| 改动文件 warnings | — | **0** |
| 总 warnings | 37 | 38（无新增；1 条 pre-existing 于 storage_pref→login_utils，非本任务） |

剩余 116 全为已知基线：85 孤儿 `part`（context_menu/*_menu_helper.dart）+ 25 其他任务 test RED（connectivity 7/android_helper 6/platform_utils 4/extension_test 4/selectable_region_ext 4）+ 6 vendored（vertical_slider 3/editable_text 3）。

### 3.2 运行时验证（纯 Dart harness，T6/T9/T13 方法）

宿主 Flutter 3.44.4 无法编译 OHOS 依赖链（vendored `editable_text.dart` `ExtendSelectionByPageIntent` + fork 包 `TargetPlatform.ohos`），故按既有学习在 temp 目录建独立 pubspec（`name: PiliPlus` + fixnum 1.1.1/protobuf 6.0.0/hive_ce 2.19.3，与 B 锁文件一致），**真实复制** `lib/grpc/reply.dart` + 全部 `lib/grpc/bilibili/**` 生成 pb，仅 stub 无关重依赖（GrpcReq/GrpcUrl/Constants/LoadingState/GlobalData/Pref/GStorage/SettingBoxKey）。

`dart run bin/verify.dart` → **72 passed, 0 failed**，覆盖：
- block_reason_test 全部断言（关键词/带货/等级/@纯@/@正文过短/@数量过多/点赞豁免/无策略/needRemoveGrpc/isClientBlocked/getBlockReason/clearBlockedReasons/回复前缀剥离 4 例/黑名单策略 5）
- blocked_reply_filter_test 全部断言（banner 保留+标记、upTop 保留、子回复标记、auto-page 条件；remove 移除、upTop 清除、子回复移除、auto-page 触发/不触发）
- `ReplyGrpc.mainList` **真实路径**（canned response 桩）：banner 模式标记 `_blockedReasons`+reason 落库、upTop 保留+标记；remove 模式移除+清 upTop；remove+全部过滤时 auto-page 递归追加第二页并回写 cursor/paginationReply
- `getBriefBlockReason`/`blockReply` 默认值路径

### 3.3 BlockedReplyBanner 测试契约适配

B 的 RED `blocked_reply_banner_test.dart` 与 A 同文件，但契约与 A 实现冲突：测试以 `const BlockedReplyBanner(onExpand: _noop)` 构造（**无 replyItem**）且 `find.text('此评论已被屏蔽。')` 精确匹配（A 恒渲染 `'…（$briefReason）。'`）。本任务按 **测试契约优先** 适配：
- `replyItem` 改为可选（`ReplyInfo?`），无原因/默认 `'被屏蔽'` 时渲染 `'此评论已被屏蔽。'`，有具体原因才渲染 `'此评论已被屏蔽（$briefReason）。'`
- 真实应用流（mainList 落库详细原因）仍显示带原因横幅；偏离仅限测试构造的默认态

## 4. 与 T15/T16 的协调（同文件串行）

- `reply_item_grpc.dart` 已完成 Stateless→Stateful 转换，`_ReplyItemGrpcState` 是后续 T15（翻译横幅）/T16（长按菜单）的宿主
- 本任务**未动**翻译逻辑（`_buildTranslateBtn`/`translationSwitch`/`showTranslation`）、未动 `morePanel` 长按菜单、未动 `reply.dart` 的 `translateReply` 签名（B 版本，T15 再换 A 批量版）
- `forceShowOriginalContent` 参数已加（A banner gating 用，默认 false；B save_panel 尚未传 → T26 接线）

## 5. Harness 位置（证据可复现）

`C:\Users\dashan\AppData\Local\Temp\opencode\t14_reply_harness\` — `dart pub get && dart run bin/verify.dart`
