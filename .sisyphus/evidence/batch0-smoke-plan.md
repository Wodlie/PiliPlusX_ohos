# Batch 0 Smoke Plan

> Task 4（port-a-features）侦察产物 · 只读，未修改任何代码 · 2026-07-31
> 工具基线：B 使用 `D:\Program\Flutter\flutter-ohos`（**Flutter 3.41.10-ohos-0.0.2-beta**，CI 为 oh-3.41.9-release）；A 使用 `D:\Program\Flutter\flutter`（3.44.4）。
> ⚠️ 本地 `.dart_tool/package_config.json` 现指向 **3.44.4（错误 SDK）**，`flutter` 包解析到 `D:/Program/Flutter/flutter`。下列本地 analyze 结论已区分「真实」与「SDK 混用假象」。

---

## 一、selectable_region_ext 可行性分析

### 1.1 与 text_selection.dart:2921,3044 的冲突检查 → 无直接冲突

- 实读 B `lib/common/widgets/flutter/text_field/text_selection.dart` 2921-2929 与 3044-3052：
  - 被注释的是 `_handleStartHandleDragUpdate` / `_handleEndHandleDragUpdate` 中的 **"补发 drag start"逻辑**（`// //  TODO 直接注释掉的代码 3.32.4-ohos-0.0.1不支持`）：当另一手柄拖动被阻塞（Apple/web 单手柄约束）时，在 drag-update 阶段补发 `onStartHandleDragStart`/`onEndHandleDragStart` 回调。
  - 属 **TextField 选区手柄覆盖层（`_TextSelectionHandleOverlay`）**，与 `SelectableRegion`/`SelectionArea` 是**两个独立子系统**。
- 实读 A `lib/utils/extension/selectable_region_ext.dart`（52 行全文）：扩展只操作 **`SelectableRegionState`**（SelectionArea 的 state），逐行不引用 text_selection.dart 任何符号。
- **结论：guardrail「不恢复 text_selection.dart:2921,3044 注释」不阻碍 selectable_region_ext 的功能移植。**

### 1.2 A 扩展的真实依赖面（逐依赖核对）

| A 扩展依赖 | B 侧状态 | 判定 |
|---|---|---|
| `SelectableRegionState.hideToolbar()` / `clearSelection()` | B SDK 公共方法（selectable_region.dart:1841 / 1579） | ✅ 存在 |
| `ContextMenuButtonItem` | SDK | ✅ 存在 |
| `PageUtils.launchURL` | `lib/utils/page_utils.dart:450` | ✅ 存在 |
| `List.insertOrAdd` | B `iterable_ext.dart` **已删**（Task 27 恢复） | ⚠️ 待恢复 |
| `StaticSelectionContainerDelegate`（类型） | B SDK 公共类（selectable_region.dart:2103） | ✅ 存在 |
| `.value.status == .uncollapsed`（`SelectionStatus`） | B SDK 有 `SelectionStatus.uncollapsed`（selectable_region.dart:304） | ✅ 存在 |
| `Selectable.getSelectedContent()` | B rendering 接口（selection.dart:95） | ✅ 存在 |
| **`(this as dynamic).selectable` / `(this as dynamic).selectionDelegate`** | 两 SDK（3.44.4 与 3.41.10-ohos）`SelectableRegionState` 只有私有 `_selectable`/`_selectionDelegate`，**无任何公共 getter** | ❌ **运行时必崩** |

**关键实证**：
- 两 SDK 的 `SelectableRegionState` 均无公共 `selectable`/`selectionDelegate` getter（A 3.44.4 selectable_region.dart:404-406；B 3.41.10-ohos:405-407；`TextSelectionDelegate` mixin 亦无，services/text_input.dart:1244-1325）。
- dynamic 访问不存在的成员 → **NoSuchMethodError**（temp 脚本实证：`C:\Users\dashan\AppData\Local\Temp\opencode\dyn_test`，`(f as dynamic).selectable` 抛 NoSuchMethodError）。
- 因此 **A 的扩展 `selectedText`/`isUncollapsed` 在 A 自身运行时也抛 NoSuchMethodError**——「打开」功能在 A 是坏设计（用 `(this as dynamic)` 企图越权访问私有字段，语言层面不可能成功）。
- 佐证：B 维护者**今日**提交 `d1916d920`（"fix: resolve CI build errors (dart_imagehash dep, Account.buvid)"）已以 "referencing nonexistent APIs" 为由**删除** `selectable_region_ext.dart`（52 行）与 `request_identity_adapter.dart`（211 行）。

### 1.3 B 中的消费点现状（3 个孤儿 part 文件）

- 引用扩展方法的 3 个文件均为 **孤儿 part**（父库已删除 `part` 声明，函数无人调用 = 死代码），造成 B 当前 **85 个真实 analyze 错误**：
  - `lib/common/widgets/context_menu/reply_menu_helper.dart`（40 err；`showReplyCopyDialog` 全库无调用方）
  - `lib/common/widgets/context_menu/dyn_menu_helper.dart`（37 err；`dynTextMenuBuilder` 无调用方）
  - `lib/common/widgets/context_menu/live_menu_helper.dart`（8 err）
- B 现行文本选择实现（均已改用 `EditableTextState` / `SelectionArea`，绕开孤儿文件）：
  - dynamics：`SelectableText.rich` + `contextMenuBuilder:(_, state)` → `_contextMenuBuilder(EditableTextState state, …)`（`content_panel.dart:73-80,110`）
  - reply：`SelectableText` + `contextMenuBuilder:(_, editableTextState)`（`reply_item_grpc.dart:1194-1198`）
  - superchat：`SelectionArea`（`superchat_card.dart:240`）
- **`EditableTextState.textEditingValue` 为公共 API**（B SDK editable_text.dart:4966）→ 在 SelectableText 菜单中可**公开地**取得选区文本。

### 1.4 结论 + 替代方案

> **可行性结论：功能可移植，但 A 原文件不可原样移植（运行时必崩）；且其 B 侧唯一消费方是 3 个死代码孤儿文件。建议替代实现，不恢复孤儿文件。**

1. **不要原样移植** `selectable_region_ext.dart`（依赖不存在的公共 API；`selectedText`/`isUncollapsed` 在 A 中即坏）。
2. **不要恢复** 3 个孤儿 part 文件——它们是死代码且贡献 85 个基线 analyze 错误（Task 16 guardrail「不动 reply_menu_helper.dart（SAME 文件）」基于错误假设：该文件 B 与 A 相同但 A 中也是孤儿，B 中已无消费方，**需 orchestrator 更新 guardrail**：允许删除/改写这 3 个文件）。
3. **替代方案（推荐）**：在 B 现有 SelectableText 菜单中直接实现「打开」按钮：
   - `content_panel.dart::_contextMenuBuilder` 与 `reply_item_grpc.dart::_filterMenuBuilder` 的 `buttonItems` 追加 `ContextMenuButtonItem(label: '打开', onPressed: () => PageUtils.launchURL(选区文本))`；选区文本 = `state.textEditingValue.selection.textInside(state.textEditingValue.text)`（全公共 API，无隐私越权）。
   - superchat（`SelectionArea`）无公共选区文本 → **不实现**（与 A 实际损坏行为一致）。
   - 若坚持保留 `SelectableRegionStateExt` 形态：唯一途径是经 B 的 `lib/scripts/*.patch` 机制给 OHOS fork SDK `selectable_region.dart` 打补丁暴露 `selectable`/`selectionDelegate` 公共 getter，成本高、风险大（改 SDK），**不推荐**。
4. Task 27 仍应恢复：`ListExt.insertOrAdd`（消除 `extension_test.dart` 4 错误 + 4 处调用点）、`viewPugv(progress:)`。
5. 可复用 B 独有工具：`lib/common/widgets/selectable_text.dart`（`selectableText`/`selectableRichText`，桌面用 SelectionArea / 其余用 SelectableText）与 `lib/common/widgets/flutter/selectable_text/*`（6 文件 vendored 框架，含 `text.dart`/`selection_area.dart`/`selectable_region.dart` 等）——**已确认存在且可用**。

---

## 二、19 功能族冒烟路径矩阵

> 验证方式图例：
> **C** = 编译验证（`dart analyze --no-fatal-warnings` 0 error）｜ **W** = 符号接线（grep/lsp 证明从 `main.dart` 可达，对应 Task 31 的 19 符号）｜ **M** = Hive 迁移测试（`dart test test/hive_migration_test.dart`，Task 6 新建）｜ **S** = 临时断言脚本（AccountType 6 / wbi dm_img / grpc 头）｜ **R** = 复用 B `test/` 中继承自 A 的测试文件（编译 + `flutter test` 运行，详见 §四）｜ **P** = runtime-pending（仅设备）

| # | 功能族（计划 Must Have） | 验证方式 | 说明 / 关键符号 |
|---|---|---|---|
| F1 | 账号身份体系（AccountType 6 值、每账号 BUVID/deviceProfile、RequestIdentityAdapter、gRPC 头、wbi 风控、BUVID 激活重试、登出清理、昵称缓存） | C + M + S + R + W | M：4→6 迁移无崩溃（全计划最高优先级）。S：`AccountType.values.length==6` 且 reply/blacklist desc 非空；`encWbi` 输出含 dm_img_* 风控字段；`GrpcHeaders` 含 x-bili-mid / restriction-bin / ticket / deviceProfile。R：`buvid_lifecycle_test` / `identity_migration_test` / `identity_profile_test` / `grpc_identity_test` / `web_gaia_identity_test` / `request_identity_adapters_test`。W：`RequestIdentityAdapter` 在 `lib/http/*.dart` 被消费。P：登录/切换/登出网络流 |
| F2 | 自定义 API Host + 港澳台代理拦截器 | C + R + W | R：`test/http/init_test.dart` 断言拦截器链顺序（Retry→CustomHost→HkApiRetry→Log）。W：两个拦截器在 `init.dart` 链中；`api_host_page` 设置入口可达。P：真实 URL 重写/代理连通 |
| F3 | 港澳台番剧（hk_bangumi + media_hk_bangumi + pgc 代理） | C + W | W：`hk_bangumi` 枚举 + pgc controller 消费 + 搜索 tab + `apiHKUrl` 未配置 Error 提示。P：代理网络请求 |
| F4 | AI 总结多服务（router + legacy/multimodal adapter + 设置组） | C + R + W | R：`video_summary_routing_test` / `video_summary_failure_states_test` / `video_summary_settings_test` / `video_summary_ugc_widget_test`。W：`AiSummaryServiceRouter` 被 ai_conclusion view 消费。P：真实 AI 服务调用 |
| F5 | 评论屏蔽（checkBlockReason 5 策略 + BlockedReplyBanner） | C + R + W | R：`block_reason_test` / `blocked_reply_filter_test` / `blocked_reply_banner_test`（5 策略为纯逻辑，可无设备断言）。W：`checkBlockReason` 在 `lib/grpc/reply.dart` 且被消费；`BlockedReplyBanner` 非静默删除。P：横幅 UI 交互 |
| F6 | 评论翻译横幅 + 申诉 | C + W | W：`translatedReplies` + `forceShowOriginalContent` 在 reply controller/widgets；`appealComment`/`replyAppealSubmit`/`defaultAppealReason` 消费。P：翻译/申诉网络 + UI |
| F7 | canSort + 长按拉黑/分享 + 手动加载图 | C + W | W：`canSort`+`switcherType`；长按菜单 `relationMod`(act:5)+`ShareUtils.shareText`；`manualLoadCommentImage` 消费。P：菜单交互 |
| F8 | 互动视频 Stein（进度恢复 + 回溯面板 + BottomControlType.stein） | C + W | W：`steinResumeNode`/`goToSteinStoryNode` 在 video controller；`showStein`/`interactiveChild` 在 pl_player；`BottomControlType.stein`。**P（核心）：回溯面板/进度恢复须真机播放互动视频** |
| F9 | 图片屏蔽 pHash UI | C + R + W | R：`image_block_service_test` + `phash_cross_resolution_test`（pHash 算法可无设备跑）。W：`ImageBlockService` 在 image_grid_view / `BlockedImagePlaceholder` / `report.dart::onBlockImages`。P：屏蔽菜单 UX |
| F10 | 私信会话详情 + whisper 标为已读 | C + W | W：`ImGrpc.sessionDetail` + `GrpcUrl.sessionDetail`；whisper item 标为已读菜单。P：gRPC 网络 + UI |
| F11 | 直播反馈 + 卡片反馈按钮 | C + W | W：`Api.liveFeedback` + `LiveHttp.liveFeedback` + `live_item_app.dart` 按钮；api_type recommend 路由表含之。**P（核心）：直播网络** |
| F12 | 快速分享 + pmShare | C + W + ast_grep | W：`pmShare`（SelectableText 适配，无 SelectionText）；分享按钮 `onLongPress` 3 处；`enableQuickShare`/`quickShareId` 消费。ast_grep：`SelectionText(` 0 命中。P：分享流程 |
| F13 | 历史续播 + SponsorBlock 无痕 | C + W | W：`viewPgc`/`viewUgc` progress 参数传递；`suppressSponsorBlockIncognito` + `_doVote` catchError。P：续播跳转 + 网络 |
| F14 | 动态/首页刷新 FAB + 剪贴板搜索 | C + W | W：`showDynamicsRefreshFab`/`showHomeRefreshFab`/`showClipboardSearch` 消费激活。P：FAB 动画、剪贴板读取 |
| F15 | 播放器快捷操作（长按倍速/比例、fastForBackwardDuration_、HDR 提示） | C + W | W：`onLongPress`（speed/qa 控件）、`fastForBackwardDuration_` 双时长、HDR/杜比提示符号。**P（核心）：播放器** |
| F16 | 下载按 UP 过滤 + 保存评论图原文 | C + W | W：下载搜索 `upName`/`filterUp`；`forceShowOriginalContent`（F6 联动）。**P（核心）：下载子系统** |
| F17 | selectable_region_ext + ListExt.insertOrAdd + viewPugv(progress:) | C + R + W | 结论见 §一：替代实现/清理孤儿文件，不原样移植。R：`utils/extension_test.dart`（insertOrAdd 4 断言恢复后通过）。W：`insertOrAdd` 定义 + 消费；`viewPugv(progress:)` 签名。P：菜单 UI |
| F18 | 视频换源 videoPush + 隐藏状态栏 + 账号昵称 + 无痕空降 | C + W | W：`videoPush` 弹窗（-404 路径）；`hideStatusBar` 消费；`setAccountUname`（login/mine）；`incognitoMode` 不发空降查询。P：-404 场景、状态栏、网络 |
| F19 | 设置项恢复（AI 组/评论 AI 翻译/申诉理由/图片路径/快速分享目标/HK URL） | C + W | W：6 项设置 UI + Pref 消费点激活（非死键）；账号选择器昵称。P：设置交互 |

### 符号接线（W）总锚点（对应 Task 31 的 19 符号）
`AccountType.values.length==6` ｜ `CustomHostInterceptor` ｜ `hk_bangumi` ｜ `AiSummaryServiceRouter` ｜ `checkBlockReason` ｜ `BlockedReplyBanner` ｜ `translatedReplies` ｜ `appealComment` ｜ `canSort` ｜ `sessionDetail` ｜ `liveFeedback` ｜ `videoPush` ｜ `pmShare` ｜ `progress`(续播) ｜ `suppressSponsorBlockIncognito` ｜ FAB Pref ｜ `stein`/`showStein` ｜ `fastForBackwardDuration_` ｜ `imageBlock` UI

---

## 三、runtime-pending 清单（仅设备可验证）

| 序号 | 功能 | 说明 |
|---|---|---|
| 1 | **播放器**（F15 + F13 续播 + F18 隐藏状态栏/videoPush） | 长按倍速/比例、HDR/杜比 SDR 提示、快退双时长、进度续播、状态栏显隐、-404 换源弹窗均需真机播放 |
| 2 | **Stein 互动视频**（F8） | 进度恢复对话框、回溯面板、interactiveChild——需真机播放互动视频（rights.isSteinGate） |
| 3 | **直播**（F11 + live_menu） | liveFeedback 提交、直播卡片反馈按钮——需真实直播流 |
| 4 | **下载**（F16） | 下载搜索按 UP 过滤的实际下载流程（B 下载子系统为 OHOS 适配密集区） |
| 5 | **图片 pHash 屏蔽 UX**（F9） | 屏蔽/临时解屏蔽菜单交互（pHash 算法本身可被 `phash_cross_resolution_test` 无设备覆盖） |
| 6 | 快速分享 pmShare（F12） | 长按分享 → 私信目标选择流程 |
| 7 | 评论翻译横幅 / 申诉（F6）、评论长按拉黑/分享（F7）、BlockedReplyBanner（F5） | 网络调用 + 横幅/菜单交互 |
| 8 | 港澳台番剧（F3）、自定义 API Host / 港澳台代理（F2） | 真实网络 + 代理连通 |
| 9 | AI 总结（F4） | 真实 AI 服务调用（router 路由与失败态可被测试覆盖） |
| 10 | 剪贴板搜索（F14）、动态/首页 FAB 动画（F14） | 剪贴板读取 + 滚动手势动画 |
| 11 | 历史续播跳转（F13）、SponsorBlock 无痕抑制（F13） | 播放页跳转 + 无痕/游客网络抑制 |
| 12 | 账号登录/切换/登出、BUVID 激活重试（F1） | 网络 + 身份状态机 |

> 无设备验收口径（与计划一致）：以上项以「编译 + analyze + 符号接线 + 逻辑测试」为通过线，如实标记 runtime-pending，不虚构设备验证结果。

---

## 四、对 T27 与 Batch 5 验证的执行建议

### 4.1 对 Task 27（selectable_region_ext + insertOrAdd + viewPugv）

1. **先清基线**：处理 3 个孤儿 part 文件（删除 `reply_menu_helper.dart`/`dyn_menu_helper.dart`/`live_menu_helper.dart`，或把其函数并入现行 SelectableText 菜单）→ 消除 **85 个真实 analyze 错误**。⚠️ 与计划 Task 16 guardrail「不动 reply_menu_helper.dart」冲突 → **需 orchestrator 批准更新 guardrail**。
2. **insertOrAdd**：恢复 `ListExt.insertOrAdd`（A 参照：length<=index 则 add 否则 insert）→ 一并修复 4 处调用点 + `utils/extension_test.dart` 4 个断言。
3. **selectable_region_ext**：按 §1.4 替代实现（在 `content_panel._contextMenuBuilder` / `reply_item_grpc._filterMenuBuilder` 用 `EditableTextState.textEditingValue` 加「打开」项）；不创建 A 原文件；superchat（SelectionArea）不实现「打开」。
4. **viewPugv(progress:)**：恢复课程续播参数（B 现签名无 progress）。
5. 不恢复 `text_selection.dart:2921,3044`；不删 B 的 `selectable_text.dart` 工具。

### 4.2 对 Batch 5 验证（Task 30-33）的前置与执行

1. **前置（必须）**：本地 `.dart_tool/package_config.json` 指向错误 SDK（3.44.4）。先以 **OHOS SDK** 重新 `flutter pub get` 后再 analyze/build：
   - 否则 `TargetPlatform.ohos`（vertical_slider.dart）、`ExtendSelectionByPageIntent`（editable_text.dart）错误均为 **SDK 混用假象**。
   - 本地 `file_picker_ohos` 错误为 **缓存假象**：pubspec.lock 钉 `04eec7fdb`(v10.3.8)，本地缓存是另一 commit（name=file_picker v8.0.6）→ 清缓存/重解析即可；CI 不受影响。
2. **Task 30 基线**：B HEAD 本地 analyze = **276 errors**（真实 vs 假象）：
   - 真实 ≈ 85（孤儿 part）+ ~191（`test/` 引用未移植符号：request_identity_adapter、selectable_region_ext、custom_host_interceptor 等，随 F1/F2/F17 移植逐项消失）。
   - 假象（修 pub get 后复核）：`TargetPlatform.ohos`、`ExtendSelectionByPageIntent`、`file_picker_ohos`。
3. **Task 31 接线**：按 §二 W 锚点 19 符号 grep/lsp；**双保险**——让对应 `test/` 继承文件编译通过即证明符号存在于库中且可被外部引用。
4. **Task 33 冒烟**：
   - `dart test test/hive_migration_test.dart`（Task 6 产物）。
   - 临时断言脚本（放 `tool/` 或 `test/` 一次性）：① AccountType 6 值 + desc；② `wbi_sign.encWbi` 含 dm_img_*（纯 Dart 可跑）；③ `GrpcHeaders` 结构字段断言（可构造假账号）。
   - 回归 F17 复用测试 `utils/extension_test.dart`（insertOrAdd）。
   - 其余 F 族的逻辑断言优先复用 §二 R 列的继承测试（`flutter test test/<feature>_test.dart`）。
5. **交付**：runtime-pending 按 §三 清单如实标注（未验证不虚标）。

### 4.3 关键文件/提交索引（供后续任务复核）
- B 删除记录：commit `d1916d920`（删 `selectable_region_ext.dart` + `request_identity_adapter.dart`，今日）。
- A 扩展全文：`D:\coding\PiliPlusX\lib\utils\extension\selectable_region_ext.dart`。
- B 现行菜单：`content_panel.dart:73-118`、`reply_item_grpc.dart:1194-1198`、`superchat_card.dart:240`。
- B 孤儿文件：`lib/common/widgets/context_menu/{reply_menu_helper,dyn_menu_helper,live_menu_helper}.dart`。
- B 可复用：`lib/common/widgets/selectable_text.dart`、`lib/common/widgets/flutter/selectable_text/*`（6 文件）。
