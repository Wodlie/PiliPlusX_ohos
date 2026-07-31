# Task 17 — 私信会话详情恢复 + build* 包装 + whisper 标为已读

**Date:** 2026-07-31
**Repo:** D:\coding\PiliPlusX_ohos
**Baseline:** 163 errors (T11 后，T9 已将 sendMsg/syncFetchSessionMsgs 的 devId 接入 `GrpcHeaders.currentImDeviceId()`)

## 1. 修改文件（3 个，全部 0 新增 error）

### lib/grpc/im.dart
- 恢复 `ImGrpc.sessionDetail({Int64? talkerId, int? sessionType, Int64? uid})` → `LoadingState<SessionInfo>`（POST `GrpcUrl.sessionDetail`，请求 `ReqSessionDetail`，响应 `SessionInfo.fromBuffer`）
- 恢复 `buildSendMsgRequest({senderUid, receiverId, content, msgType})` → `ReqSendMsg`（devId 用 T9 的 `GrpcHeaders.currentImDeviceId()`，**保留 T9 改造**）
- 恢复 `buildSyncFetchSessionMsgsRequest({talkerId, endSeqno, beginSeqno})` → `ReqSessionMsg`（devId 同上）
- `sendMsg`/`syncFetchSessionMsgs` 改为调用 build* 包装方法（A 的方法签名一致，T9 注入点保留）
- import 首行加 `hide SessionInfo`（`SessionInfo` 同时存在于 `app/im/v1.pb.dart:4137` 与 `im/type.pb.dart:3055`，A 用 type.pb 的——其含 `ackSeqno` 字段供标已读使用）

### lib/grpc/url.dart
- 恢复 `static const sessionDetail = '$im/SessionDetail'`（= `/bilibili.im.interface.v1.ImInterface/SessionDetail`）

### lib/pages/whisper/widgets/item.dart
- 恢复 `_updateAck(BuildContext)`：`ImGrpc.sessionDetail` 取 `ackSeqno` → `MsgHttp.ackSessionMsg` → toast「已标为已读」+ `item.clearUnread()` + `markNeedsBuild`
- 长按菜单：置顶下方新增「标为已读」DialogOption（`if (kDebugMode || item.hasUnread())`，privateId.hasTalkerUid 门控内，A 模式）
- 右键菜单（desktop）：`items: <PopupMenuEntry<Never>>[...]` 显式类型（spread 下无法推断 E），置顶下方新增「标为已读」PopupMenuItem
- 长按 dialog builder 改 `(_)`，保证 `_updateAck(context)` 使用 ListTile 外层 context（markNeedsBuild 作用于列表项）
- 新增 imports：grpc/im.dart、http/loading_state.dart、http/msg.dart、flutter/foundation.dart (kDebugMode)

## 2. 约束遵守
- **未编辑任何 `*.pb*.dart`**：`ReqSessionDetail`（interfaces/v1.pb.dart:1764）、`SessionInfo`（type.pb.dart:3055，含 ackSeqno:3273）、`ReqSendMsg`/`ReqSessionMsg`（含 devId）均为两仓 SAME 已有类型，直接消费
- **保留 B 的 im.dart 现有方法**（T9 的 currentImDeviceId 接入 sendMsg:31 / syncFetchSessionMsgs:58 原样保留）
- **未新增桌面分支**（`PlatformUtils.isDesktop` 右键菜单沿用 B 现有模式，仅加菜单项）
- `MsgHttp.ackSessionMsg`（http/msg.dart:346）B 已存在，签名一致

## 3. 验证

### dart analyze --no-fatal-warnings（连跑 3 次稳定）
```
total errors: 159   (= 163 基线 − 4)
grpc_identity errors: 0
whisper errors: 0
im.dart errors: 0
url.dart errors: 0
```

### grpc_identity_test.dart（test/grpc_identity_test.dart）
- RED 时 4 errors：`ImGrpc.buildSendMsgRequest`（line 86, 170）×2 + `ImGrpc.buildSyncFetchSessionMsgsRequest`（line 91, 175）×2
- 现 0 errors，全部转绿；测试断言 `sendMsgRequest.devId == derived.deviceId` 且 `isNot('1')`（devId 真实身份）由 build* 内 `GrpcHeaders.currentImDeviceId()` 满足

### 错误分布（与基线结构一致）
| 组 | 数 | 说明 |
|----|----|----|
| lib/common/widgets/context_menu/* | 85 | 3 个孤儿 part 文件（已知基线） |
| test/ | 68 | 非 T17 测试 RED（基线 72 − 4） |
| lib/common/widgets/flutter/* | 6 | vendored 引擎补丁（已知基线） |

> 注：首轮 analyze 曾瞬时报 250（并行 T12/T13 正在写 pgc/search 文件），稳定后 159，与 163−4 精确一致。

## 4. 消费点接线（whisper 标为已读链路）
`WhisperSessionItem._updateAck` → `ImGrpc.sessionDetail`（本任务恢复）→ `response.ackSeqno`（type.pb SessionInfo）→ `MsgHttp.ackSessionMsg`（B 已有）→ UI 更新。全链路类型签名与 A 逐字段一致。
