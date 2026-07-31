# F3 — Real Manual QA（Final Verification Wave 审查 #3）

> **Task:** port-a-features Final Wave F3 · 执行 batch0-smoke-plan 的可执行 QA 场景 + 跨功能链路复核
> **Date:** 2026-08-01
> **Repo:** D:\coding\PiliPlusX_ohos (B)
> **HEAD:** `5971e081a` verify(batch5)
> **工具链:** Dart 3.12.2（全局）；`.dart_tool/version` = **3.41.10-ohos-0.0.2-beta**（package_config 8/1 2:04 重新生成，现已解析 OHOS SDK）
> **方法:** 重跑 3 个纯 Dart harness + 全量 `dart analyze` + AccountType 运行时断言 + 5 条跨功能链路 grep/read 实证
> **约束:** 零代码修改（纯 QA）；runtime-pending 项如实标注，不虚构设备结果

---

## 一、Harness 重跑（运行级证据）

> 先核验 harness 内真实复制文件与当前仓库字节一致（证明断言的是当前代码逻辑），仅 import 路径/stub 替换除外。

| # | Harness | 关键文件 hash vs 仓库 | 重跑结果 | 与 T6/T9/T14 evidence 一致 |
|---|---------|----------------------|----------|---------------------------|
| 1 | `%LOCALAPPDATA%\Temp\opencode\hive_migration_verify` | `account_type.dart` **一致**；`account.dart`/`account_adapter`/`account_migration`/`app_device_profile` 仅 import 路径差异（Compare-Object 证实非迁移逻辑行） | **`ALL PASS (31 checks)`** | ✅ 31/31（T6/T33 逐字节一致） |
| 2 | `%LOCALAPPDATA%\Temp\opencode\t9_harness` | `grpc_headers.dart` hash **392EE4A3… == 仓库** | **`PASS: 56  FAIL: 0`** | ✅ 56/56（T9/T33 一致） |
| 3 | `%LOCALAPPDATA%\Temp\opencode\t14_reply_harness` | `reply.dart` hash **DB663DAE… == 仓库** | **`RESULT: 72 passed, 0 failed`** | ✅ 72/72（T14 一致） |

**Hive 迁移覆盖（31 项）:** A1-A14 旧 4 字段解码 + 迁移回填（field4==cookie buvid3、field5=确定性档案）；B1-B2 幂等；C1-C2 空 box；D1-D6 缺 buvid3 容错；E1-E5 重开稳定/已 6 字段跳过；F1-F2 跨启动值稳定。
**gRPC 头覆盖（56 项）:** 登录 mid=2101 → x-bili-mid/aurora-eid/authorization/真实 device 字段；游客 mid=0 无 aurora-eid；`Pref.guestBuvid` 兜底；fawkes 可解码。
**评论 5 策略覆盖（72 项）:** keyword/goods/level/@-filter/blacklist 全策略 + banner/remove 双模式 + `ReplyGrpc.mainList` 真实递归 auto-page（GrpcReq FIFO 桩驱动）。

**结论:** 三 harness 全部通过，无回归。T6 全计划最高优先级验收项（Hive 4→6 迁移）复核仍绿。

---

## 二、AccountType 运行时断言（非仅 grep）

临时脚本 `dart run` 直接执行（`account_type.dart` 零依赖纯枚举）：

```
PASS: length==6
PASS: reply index 4
PASS: blacklist index 5
PASS: main/heartbeat/recommend/video order preserved (0-3)
PASS: all title+desc nonempty
ACCOUNT_TYPE_ASSERT: PASS
```

> 首跑出现 1 个 FAIL（order preserved）为**脚本自身 bug**：Dart `List ==` 是身份比较非逐元素。改用逐元素比较后 5/5 PASS。枚举文件 `lib/models/common/account_type.dart:2-7` 逐行确认：main(0)/heartbeat(1)/recommend(2)/video(3)/reply(4)/blacklist(5)，原序保留 + 尾部追加，与 A 及 Hive 按 index 序列化约束一致。

---

## 三、dart analyze — 18 errors（基线等价，端口文件 0 错误）

`dart analyze --no-fatal-warnings` 实测 **18 errors**，错误分布：

| 文件 | 数 | 类别 | 判定 |
|------|----|------|------|
| `lib/utils/platform_shortcuts.dart` | 1 | `non_exhaustive_switch_statement`（switch 无 `TargetPlatform.ohos` 分支） | **pre-existing**：文件唯一提交 = `5a4dd671f init`（git diff 50039f462..HEAD 空）；在 OHOS SDK 解析下才浮现（此前标准 SDK 无 `.ohos` 枚举值） |
| `test/android_helper_test.dart` | 6 | `AndroidHelper` undefined | test/ RED 基线，与 batch5-build 表逐项一致 |
| `test/connectivity_utils_test.dart` | 7 | checkConnectivity/isNone/isWifi/isMobile/onConnectivityChanged undefined | test/ RED 基线，逐项一致 |
| `test/platform_utils_test.dart` | 4 | isDarwin/isHarmony undefined | test/ RED 基线，逐项一致 |
| **合计** | **18** | | 0 个在移植 lib/ 文件 |

**23 → 18 差异归因（环境性，非代码回归）:**
- `package_config.json` 于 8/1 02:04 重新生成，`version` = 3.41.10-ohos（Batch 5 时解析到标准 SDK 3.44.4）。
- 在 OHOS SDK 下：`ExtendSelectionByPageIntent`（editable_text）与 `TargetPlatform.ohos`（vertical_slider）**已被定义** → batch5 报告的 6 个 vendored-engine 假象错误消失（batch5-build.md:21-22 自述"compiles only under OHOS engine / undefined on standard SDK"）。
- 同一解析下 `platform_shortcuts.dart` 的 `switch (defaultTargetPlatform)` 缺 `.ohos` 分支被静态标记（运行时 `if (OS.isHarmony)` 提前返回，永不触达）——init 遗留的 OHOS 已知项，非本移植引入。
- 17 个 test/ RED 与 batch5 基线逐文件、逐错误类型完全一致。

**结论:** 移植的 19 功能族涉及 lib/ 文件 **0 错误**；总数变化由 SDK 解析切换导致，端口零新增。CI（oh-3.41.9-release）仍为 .hap 权威。

---

## 四、runtime-pending 清单核对（15 项）

batch5-smoke.md §五 的 15 项与 batch0-smoke-plan §三 12 项 + F17/F19/T29 细分补充映射如下，逐项核对无虚标：

| # | batch5-smoke §五 | 对应 batch0-smoke-plan §三 | 核对 |
|---|---|---|---|
| 1 | 播放器（F15/F13/F18） | §三.1 | ✅ |
| 2 | Stein（F8） | §三.2 | ✅ |
| 3 | 直播（F11） | §三.3 | ✅ |
| 4 | 下载（F16） | §三.4 | ✅ |
| 5 | 图片 pHash 屏蔽 UX（F9/F20） | §三.5 | ✅ |
| 6 | 快速分享 pmShare（F12） | §三.6 | ✅ |
| 7 | 评论翻译/申诉/拉黑/分享/BlockedReplyBanner（F5/F6/F7） | §三.7 | ✅ |
| 8 | 港澳台番剧 + 自定义 API Host/代理（F3/F2） | §三.8 | ✅ |
| 9 | AI 总结（F4） | §三.9 | ✅ |
| 10 | 剪贴板搜索 + FAB 动画（F14） | §三.10 | ✅ |
| 11 | 历史续播 + SponsorBlock 无痕（F13） | §三.11 | ✅ |
| 12 | 账号登录/切换/登出、BUVID 重试（F1） | §三.12 | ✅ |
| 13 | 「打开」菜单按钮（F17） | F17 细分（T27 §6） | ✅ 新增细分 |
| 14 | 设置交互（F19） | F19 细分（T28 待真机） | ✅ 新增细分 |
| 15 | 无痕空降（F18/T29） | T29 §runtime-pending | ✅ 新增细分 |

> 12 项与 batch0-smoke-plan §三一一对应；13-15 为 F17/F19/T29 的进一步细分（batch5-smoke §五 已注明）。全部以"仅设备可验证"口径标注，无虚构设备结果。

---

## 五、跨功能交互接线复核（5 条关键链路）

> 全部真实 grep/read 命中；「T31 已做 19/19，本任务复核 5 条端到端链路」。

### 链路 1：账号切换 → 评论屏蔽 → 翻译横幅 ✅
```
lib/utils/accounts.dart:18  static Account get main => get(AccountType.main);
lib/utils/accounts.dart:35  static Account get reply { … }         ← 评论专用账号
lib/utils/accounts/api_type.dart:102  AccountType.reply: { Api.replyAdd, … }
lib/grpc/reply.dart:239   static String? checkBlockReason(ReplyInfo reply)   ← 5 策略
lib/grpc/reply.dart:311   checkBlockReason(reply) != null                    ← isClientBlocked
lib/pages/video/reply/controller.dart:30  final RxMap<Int64, String> translatedReplies
lib/pages/video/reply/controller.dart:50  translateReply → ReplyGrpc.translateReply
```
账号身份经 `account_mgr._resolveAccountSelection`（api_type 路由表）注入评论 gRPC 请求 → `checkBlockReason` 过滤 → 翻译横幅由 controller `translatedReplies` 驱动。链路完整。

### 链路 2：设置项 → 功能消费（enableQuickShare → 长按分享） ✅
```
lib/pages/setting/models/extra_settings.dart:569  setKey: SettingBoxKey.enableQuickShare  ← 设置写入
lib/utils/storage_pref.dart:845  static bool get enableQuickShare … defaultValue: false
lib/pages/video/widgets/header_control.dart:2193  onLongPress: () {
lib/pages/video/widgets/header_control.dart:2194    if (!Pref.enableQuickShare) { … }       ← 门控消费
lib/pages/video/widgets/header_control.dart:2209    RequestUtils.pmShare( … )
```
设置项 → Pref getter → header_control onLongPress 门控 → pmShare。链路完整。

### 链路 3：历史续播 → 播放页（resumeProgress → viewPgc progress） ✅
```
lib/pages/history/widgets/item.dart:42   final resumeProgress = switch (item.progress) { >0 => *1000, _ => null };
lib/pages/history/widgets/item.dart:78   PageUtils.viewPgc( …, progress: resumeProgress )
lib/pages/history/widgets/item.dart:86   viewPgcFromUri( …, progress: resumeProgress )
lib/pages/history/widgets/item.dart:112  toVideoPage( …, progress: resumeProgress )
lib/utils/page_utils.dart:560/600  int? progress, // milliseconds        ← 签名含 progress
lib/utils/page_utils.dart:612      progress: progress                    ← 透传
```
秒→毫秒换算后三入口透传。链路完整。

### 链路 4：无痕 → SponsorBlock 抑制（anonymity → suppressSponsorBlockIncognito） ✅
```
lib/pages/mine/controller.dart:42  static RxBool anonymity = …
lib/pages/mine/controller.dart:153 onChangeAnonymity()                     ← 无痕开关
lib/pages/sponsor_block/block_mixin.dart:68   if (Pref.suppressSponsorBlockIncognito && MineController.anonymity.value) return;
lib/pages/sponsor_block/block_mixin.dart:256  !(Pref.suppressSponsorBlockIncognito && …anonymity.value)
lib/pages/setting/models/extra_settings.dart:101 setKey: SettingBoxKey.suppressSponsorBlockIncognito
```
无痕状态 + 设置开关双条件在 query 与上报两处抑制。链路完整。

### 链路 5：Stein 进度恢复 → showStein 弹框 ✅
```
lib/pages/video/controller.dart:1153  late final Rx<HistoryNode?> steinResumeNode
lib/pages/video/controller.dart:1198  steinResumeNode.value = historyNode
lib/pages/video/view.dart:165  _steinResumeWorker = ever(steinResumeNode, …)
lib/pages/video/view.dart:170    → _showSteinResumeDialog(historyNode)        ← 进度恢复弹框
lib/pages/video/view.dart:1508  showStein: _showSteinHistorySheet              ← 回溯面板接线
lib/plugin/pl_player/view/view.dart:608/617  BottomControlType.stein → ComBtn(onTap: widget.showStein)
```
控制器 Rx 信号 → view ever 监听 → 恢复弹框 + 播放器回溯按钮。链路完整。

**跨功能链路 5/5 全部真实命中（非放水）。**

---

## 六、验证口径与边界

- 本机无 OHOS 真机/HOS SDK，UI/网络交互按 batch0-smoke-plan 口径以「编译 + analyze + 符号接线 + 逻辑 harness」为通过线；§四 15 项 runtime-pending 如实标注。
- `.dart_tool/package_config.json` 为 8/1 由前序任务重新生成（解析 OHOS SDK），本任务**未修改任何代码**（git status 仅 .sisyphus 与 AGENTS.md 未提交，均为前序/知识库内容）。
- 首跑 AccountType 断言 1 项 FAIL 为脚本 bug（List 身份比较），修正后 5/5 PASS；报告不掩盖首跑过程。

---

## 七、验收核对

- [x] 三 harness 重跑：Hive **31/31**、gRPC **56/56**、reply **72/72**（与各 task evidence 逐字节一致）
- [x] `dart analyze --no-fatal-warnings`：18 errors（= 17 test RED 基线逐项一致 + 1 platform_shortcuts pre-existing），移植文件 0 错误，基线确认无新增
- [x] AccountType 运行时断言 5/5（6 值/序/desc 全部符合）
- [x] runtime-pending 清单 15 项与 batch0-smoke-plan §三（12 项）+ F17/F19/T29 细分一致，无虚标
- [x] 跨功能链路 5/5 真实 grep/read 命中
- [x] 零代码修改

---

## VERDICT: **APPROVE**

`Scenarios 4/4 (31/31+56/56+72/72+5/5) | Integration 5/5 | Runtime-pending 15/15 确认 | VERDICT: APPROVE`

- **运行级**：Hive 迁移 31/31、gRPC 头 56/56、评论 5 策略 72/72、AccountType 5/5 全绿，无回归。
- **静态级**：analyze 错误全部为已知基线（17 test RED + 1 init 遗留 platform_shortcuts），移植文件 0 错误。
- **接线级**：19 功能族（T31）+ 5 条跨功能端到端链路全部有真实消费点。
- **诚实声明**：15 项 runtime-pending 未虚构设备验证；UI/网络行为以符号接线 + 逻辑测试为通过线，最终 .hap 以 CI（oh-3.41.9-release + HOS SDK）为准。
