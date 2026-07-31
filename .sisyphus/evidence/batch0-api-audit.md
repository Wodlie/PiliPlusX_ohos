# Batch 0 API Audit

> **Task**: T3 — 3.44→3.41 API 可用性 + media_kit OHOS fork API 面检查（只读侦察，未修改任何代码）
> **Date**: 2026-07-31
> **A** = `D:\coding\PiliPlusX`（Flutter fvm 3.44.8 / pubspec flutter 3.44.4 / sdk >=3.12.0）
> **B** = `D:\coding\PiliPlusX_ohos`（Flutter fvm 3.41.9 / pubspec flutter >=3.41.9 / sdk >=3.11.1；OHOS 引擎 3.32.4-ohos 不可打补丁）
> **本机实际工具链**: `D:\Program\Flutter\flutter` = **Flutter 3.44.4 / Dart 3.12.2**（A 与 B 当前均解析到同一全局 SDK；fvm 3.41.9/3.44.8 均未本地安装）。下文"B 可用性"按 B 声明的目标（3.41.9 / Dart ≥3.11.1）判定，同时标注本机 3.44.4 实测结果。

---

## 〇、结论速览

| 类别 | 判定 |
|---|---|
| Dart 语言特性（点简写/records/patterns/switch 表达式） | **全部可用**（Dart ≥3.10 特性，B 约束 ≥3.11.1，本机 3.12.2；B 现有代码已大量使用 `const .symmetric(...)`、`({int tagid, String tagName})`） |
| Flutter 引擎漂移 API（`ScrollCacheExtent`/`enableInlinePrediction`/`Alignment.bottomStart`/`onFocusReceived`） | **不影响功能移植**（仅存在于 B 的 vendored `lib/common/widgets/flutter/**` 3.32.4 副本中，B 已自行适配；功能代码零命中） |
| media_kit fork API | **A fork（My-Responsitories 1.1.11）与 B fork（cnoim 1.2.3）API 面不同**：`Player.create`/`VideoController.create`/`setMediaHeader`/`SimpleVideo` 为 A fork 独有；B 用 `Player()`/`VideoController()`/`Media(httpHeaders:)`/`Video`。**4 个播放器功能本身只用 B fork 已有 API，但移植须 graft 到 B 现有结构而非复制 A 文件** |
| selectable_region_ext | **编译可用 / 运行时受阻**：`(this as dynamic).selectable` 与 `.selectionDelegate` 依赖 A 的引擎补丁（3.44.4 框架无这两个 getter），需改写或给 B 的 vendored selectable_region.dart 补 getter |
| ONLY_A 功能性文件（8 个） | 全部编译可用（详见一） |
| **受阻功能族** | **1 项受阻（selectable_region_ext，可改写解除）；0 项完全不可移植** |

---

## 一、Dart/Flutter API 兼容矩阵

判定标准：实读 A 使用点 + B 的 `pubspec.yaml`/`pubspec.lock` + B 依赖源码（Flutter SDK / pub-cache git 依赖）。

### 1.1 Dart 语言特性

| API | A 用法示例 | B 可用性 | 判定 |
|---|---|---|---|
| 点简写（dot shorthands） | `const .symmetric(horizontal: 8, vertical: 4)`（`pl_player/view/view.dart:1144`）、`.zero`、`.aligned` | Dart 3.10+ 特性；B `sdk: >=3.11.1`；B 现有代码已用 `const .symmetric(...)`（`pl_player/view/view.dart` 多处） | **可用** |
| records / record types | `ValueChanged<({int tagid, String tagName})>`（B request_utils 已有）、`(int, int)`（A fork SimpleVideo 订阅 `player.stream.size`） | Dart 3.0+；B 现有代码已用 | **可用** |
| patterns / if-case | `if (dataSource.audioSource case final audio? when (audio.isNotEmpty))`（A `pl_player/controller.dart:821`） | Dart 3.0+ | **可用** |
| switch 表达式 | `AiSummaryServiceRouter` 的 `return switch (service) {...}` | Dart 3.0+ | **可用** |
| `abstract final class` | `RequestIdentityAdapter`、`AiSummaryServiceRouter` | Dart 3.0+ | **可用** |
| `this._field` 私有命名参数 | A 的 `SelectionText(String this.data, ...)`（该文件两仓库 SAME） | Dart 3.0+ | **可用** |

### 1.2 Flutter 框架 API（版本漂移项）

| API | A 用法 | B 可用性 | 判定 |
|---|---|---|---|
| `ScrollCacheExtent` / `scrollCacheExtent` | 仅 A 的 vendored `lib/common/widgets/flutter/**`（page_view/scrollable 等） | B 对应 vendored 文件已改用 `cacheExtent`（3.32.4-ohos 引擎无此 API）；**功能代码零命中**（grep 排除 vendored 目录后为 0） | **不影响移植** |
| `enableInlinePrediction` | 仅 vendored text_field/editable_text | B vendored 已删除该参数 | **不影响移植** |
| `Alignment.bottomStart` / `SizeTransition(alignment:)` | 仅 A vendored `refresh_indicator.dart:523` | B vendored 已用 `SizeTransition(axisAlignment: 1.0)` | **不影响移植** |
| `onFocusReceived()` override | 仅 vendored editable_text | B vendored 已删除 | **不影响移植** |
| `NotificationListener<UserScrollNotification>`（T24 FAB） | `dynamics/view.dart` | 3.41.9 框架存在 | **可用** |
| `FloatingActionButton`/`SlideTransition`/`AnimationController`/`GetTickerProviderStateMixin`（T24） | dynamics/home | 全部存在 | **可用** |
| `AdaptiveTextSelectionToolbar.selectableRegion`（SelectionText） | `common/widgets/selection_text.dart`（两仓库 SAME 文件，B 存在但无人 import） | B 框架 3.41.9 有该方法 | **可用**（B 已存在该 widget 文件，可复用；guardrail 倾向用 B 的 `selectableText()` 帮助函数） |
| `SelectableRegionState`（selectable_region_ext） | `.contextMenuButtonItems`、`hideToolbar()`、`clearSelection()`（公共 API） | 编译可用（框架与 B vendored 副本都有） | **编译可用** |
| `(this as dynamic).selectable` / `(this as dynamic).selectionDelegate`（selectable_region_ext） | A 扩展的 `selectedText`/`isUncollapsed` getter 用 dynamic 反射 | **框架 3.44.4 与 B vendored 副本均只有私有 `_selectable`/`_selectionDelegate`，无公共 getter**；依赖 A 的 `selectable_region.patch`（12KB 引擎补丁，B 未复刻） | **运行时受阻 → 需改写**（见三.16/四） |

### 1.3 8 个 ONLY_A 功能性文件

| 文件 | 使用的 API | B 侧前置 | 判定 |
|---|---|---|---|
| `http/ai_summary_service_router.dart` | switch 表达式、`Pref.aiSummaryService`、3 个 adapter | `ai_summary_service.dart`/`service_result.dart` 模型 B 已存在；`bilibili_legacy_summary_adapter.dart` B SAME | **可用** |
| `http/bilibili_multimodal_summary_adapter.dart` | dio、`loading_state`、`video_summary_provider`、模型 | 模型 `model_result`/`outline`/`part_outline`/`video_play_info/data`/`subtitle` B 全部存在 | **可用** |
| `http/bilibili_subtitle_summary_adapter.dart` | 同上 + `dart:convert` | 同上 | **可用** |
| `http/custom_host_interceptor.dart` | dio `Interceptor.onRequest`、`Pref`/`GStorage`、`apiHostEntries` | dio 5.9.2 两仓库同版；`api_hosts.dart` B 存在 | **可用** |
| `http/hk_api_retry_interceptor.dart` | dio `onResponse`/`Request.dio.request`、`SmartDialog.showToast` | `Request.dio` B 存在；flutter_smart_dialog B 有（git fork） | **可用** |
| `utils/accounts/request_identity_adapter.dart` | 纯 Dart（Map/jsonEncode/base64）、identity_core 系列、`IdUtils` | identity 体系为 T5-T10 待移植项；`identity_owner.dart` 两仓库 SAME | **可用**（依赖 Batch 1） |
| `utils/extension/selectable_region_ext.dart` | `SelectableRegionState` 公共 API + 2 处 dynamic 反射 | 见 1.2 末行 | **需改写/部分受阻** |
| `pages/setting/api_host_page.dart`（A 顶层） vs B `pages/setting/pages/api_host_page.dart` | GetX + GStorage + SmartDialog | B 已有功能等价的 `ApiHostPage`（注册 `/apiHostSetting`） | **可用**（T11 只需加入口） |

### 1.4 其它版本相关
- **本机 Dart 3.12.2 > B 约束 3.11.1**：任何在 B 编译的代码均含 3.10+ 语法，无"语法超前"风险（方向为 A 3.44 → B 3.41，A 用到的语言特性 3.11 都有）。
- **vendored framework 副本**（`lib/common/widgets/flutter/**`）是 3.32.4-ohos 时代的独立拷贝，**不要用 3.41 新 API 改写它们**；功能代码只 import `package:flutter/*`（真实框架）即可。

---

## 二、media_kit OHOS fork API 面

### 2.1 依赖解析（实读 lock + package_config）

| 包 | A（My-Responsitories `version_1.2.5`） | B（cnoim `feat-ohos` + My-Responsitories） |
|---|---|---|
| media_kit | 1.1.11 | **1.2.3**（cnoim） |
| media_kit_video | 2.x（同 fork） | **2.0.1**（cnoim） |
| media_kit_libs_ohos | 无 | **1.0.0**（cnoim，B 独有） |
| media_kit_native_event_loop | 同 fork | 1.0.9（My-Responsitories） |
| media_kit_libs_android/windows_video | 同 fork | 1.3.7/1.0.10（My-Responsitories） |

B fork 源码位置：`C:\Users\dashan\AppData\Local\Pub\Cache\git\media-kit-9de37e13e54953c860d47429f18da6fc096e8992\`
A fork 源码位置：`C:\Users\dashan\AppData\Local\Pub\Cache\git\media-kit-deac6b62569584b6a5e28e6c60c187a0a7281b3a\`

### 2.2 API 存在性矩阵（≥10 项，实读 fork 源码）

| API | A fork (1.1.11) | B fork (1.2.3) | A 功能依赖 |
|---|---|---|---|
| `Player()` 构造 | ✓（`typedef Player = NativePlayer`） | ✓ `Player({configuration, platform})` | 4 播放器功能共用 |
| `Player.create(configuration:)` | ✓ `NativePlayer.create({PlayerConfiguration})`（real.dart:56） | **✗** | A `pl_player/controller.dart:750` |
| `VideoController(player, {configuration})` | ✓ | ✓ `VideoController(Player, {VideoControllerConfiguration})`（内部按 `Native/Android/Ohos/Web` 分平台 create） | A `controller.dart:759` 用 `VideoController.create` |
| `VideoController.create(player, configuration:)` | ✓ | **✗** | A `controller.dart:759` |
| `setProperty(String, String, {waitForInitialization})` | ✓ | ✓（real.dart:1222，`String value` 签名） | A 用 `setProperty('video-aspect',...)` 等；**B 现状即用 `maybeAsNativePlayer.setProperty(k,v)`** |
| `getProperty(String)` | ✓ | ✓（real.dart:1254） | 可用于 stein/qa 探测 |
| `command(...)` | ✓ | ✓（B controller.dart:1279 在用） | `setShader`/webp 工具 |
| `screenshot()` 返回类型 | **`Future<ui.Image?>`**（real.dart:870） | **`Future<Uint8List?>`**（`screenshot({format, includeLibassSubtitles})`） | A `takeScreenshot` 用 `image.toByteData`；**B 已适配为 `Image.memory(bytes)`**（B controller 已含） |
| `setMediaHeader({userAgent, referer, headers})` | ✓（real.dart:1906） | **✗** | A `controller.dart:768`；**B 改用 `Media(httpHeaders: {'user-agent':..., 'referer':...})`**（B controller.dart:861） |
| `Media(uri, {extras, httpHeaders, start, end})` | ✓ | ✓（media_native.dart:104） | A `controller.dart:863`（A 不传 httpHeaders，靠 setMediaHeader） |
| `player.state.volume / rate / position / duration / playing / width / height` | ✓ | ✓（PlayerState 全字段） | A `state.volume` 等；B 现状同 |
| `player.setRate(double)` | ✓ | ✓ | 长按倍速（T25） |
| `SimpleVideo` widget | ✓（`video/simple_video_texture.dart`，仅 A fork） | **✗** | A `pl_player/view/view.dart:2123`、`gallery_viewer.dart:514`；**B 已用 `Video(...)` 替代**（B view 及 gallery_viewer:512） |
| `Video(width, height, controls, fill, fit, aspectRatio, subtitleViewConfiguration, controller)` | ✓ | ✓（video_texture.dart:120，含 `NoVideoControls`=null 禁用内置控件） | T19 interactiveChild 挂载点 graft 到 B 的 Video 结构 |
| `edl://` 音视频拼接 | ✓（A controller:827） | 引擎支持但 **B 改用 `audio-files` mpv 属性**（B controller:892） | 移植 stein 播放时必须跟随 B 的 audio-files 方案 |
| `player.platform.maybeAsNativePlayer` | ✗（A 无此扩展） | ✓（B `lib/media_kit_adapt/media_kit_adapt.dart:128` `PlatformPlayerExtension`） | B 现状接入方式 |

### 2.3 4 个播放器功能族逐项确认

| 功能 | A 实现位置 | 依赖的 media_kit API | B fork 可用性 | 判定 |
|---|---|---|---|---|
| Stein 回溯（T18/T19） | `pages/video/controller.dart`（`steinResumeNode`/`goToSteinStoryNode`/`steinHistory`）+ `view.dart`（`_showSteinHistorySheet`）+ `pl_player`（`showStein`/`interactiveChild`/`BottomControlType.stein`） | **无 fork 特有 API**：纯 GetX 状态 + UI sheet + `player.open(Media)`（走 pl_player 现有入口） | — | **可用**（模型 `story_list.dart`/`interaction.dart` HistoryNode B 已存在；4 个 edgeinfo 模型为数据差异） |
| 长按倍速/比例（T25） | `view.dart:655-673, 826-838` | `player.setRate` ✓；`toggleVideoFit` 纯状态（controller:1231，无 media_kit）；`feedBack()` B 有 | ✓ | **可用** |
| `fastForBackwardDuration_`（T25） | `controller.dart:338` + `view.dart:2029`（`BackwardSeekIndicator`） | 纯 Dart `Duration` 字段 + 自绘指示器 widget | — | **可用** |
| HDR 提示（T25） | `view.dart:891-899` | 纯 `AlertDialog`（无 media_kit API） | — | **可用**（仅提示、不崩溃） |

> **关键结论**：4 个功能族所需的 media_kit API 在 B fork **全部存在**。真正的适配风险不在功能 API，而在 **A 的 `pl_player` 基座（controller/view）整体基于 A fork API（`Player.create`/`VideoController.create`/`setMediaHeader`/`SimpleVideo`/`edl://`）**。因此 T18/T19/T25 必须**graft 功能 hunk 到 B 现有 pl_player 结构**（B 已用 `Player()`/`VideoController()`/`maybeAsNativePlayer.setProperty`/`Media(httpHeaders:)`/`audio-files`/`Video`），**严禁整文件复制 A**。

---

## 三、19 功能族 API 可用性结论

| # | 功能族 | 任务 | 判定 | 改写建议 / 依据 |
|---|---|---|---|---|
| 1 | 账号身份体系（AccountType 6值/BUVID/deviceProfile/RequestIdentityAdapter/gRPC头/wbi） | T5-T10 | **可用** | 纯 Dart + Hive + crypto；`RequestIdentityAdapter`（ONLY_A）纯 Dart 无框架依赖；`identity_owner.dart` SAME 不动。Hive 4→6 见 T2 迁移方案 |
| 2 | 自定义 API Host + 港澳台代理拦截器 | T11 | **可用** | 两个 ONLY_A 拦截器纯 dio API（dio 5.9.2 同版）；`api_hosts.dart`/B `ApiHostPage` 已存在，只加设置入口 + 接 dio 链 |
| 3 | 港澳台番剧（hk_bangumi/media_hk_bangumi/pgc 代理） | T12 | **可用** | 枚举 + GetX controller + `Pref.apiHKUrl` 字符串拼接；无版本敏感 API |
| 4 | AI 总结多服务（router + legacy/multimodal/subtitle adapters） | T13 | **可用** | router 用 switch 表达式（Dart 3）；依赖模型 `AiSummaryService`/`AiSummaryServiceResult`/`ModelResult`/`Outline`/`PartOutline` **B 全部存在**；`openai_compatible_summary_provider.dart`/`bilibili_legacy_summary_adapter.dart` B SAME 复用；需恢复 `VideoHttp.ugcSummaryMp4Url`/`transcriptSubtitles`（纯 dio） |
| 5 | 评论屏蔽 5 策略 + BlockedReplyBanner | T14 | **可用** | 纯 Dart/gRPC 逻辑 + UI banner；pb 生成文件 B 有（DIFF 但同源）；`block_filter_settings.dart` 残留按 T1 决策复用 |
| 6 | 评论翻译横幅 + 申诉 | T15 | **可用** | `translatedReplies` GetX + `GrpcUrl.translateReply`（B SAME）；申诉 `appealComment` 纯 dio。A `reply_utils.dart` 用 `SelectionText` → B 用 `selectableText()`/`SelectableText`（guardrail） |
| 7 | canSort + 长按拉黑/分享 + 手动加载图 | T16 | **可用** | `subjectControl.switcherType` gRPC 字段；`relationMod`/`ShareUtils.shareText` 标准 API |
| 8 | 私信会话详情 + whisper 已读 | T17 | **可用** | pb `im/interfaces/v1.pb.dart` **两仓库都有 `sessionDetail`**（SAME）；仅需恢复 `ImGrpc.sessionDetail`/`GrpcUrl.sessionDetail` 包装 + UI 菜单 |
| 9 | 图片屏蔽 pHash UI | T20 | **可用** | `ImageBlockService`（SAME）+ `dart_imagehash`（B pubspec 有）+ `image` 包；`gallery_viewer` **B 已把 SimpleVideo 改 Video**，port 时沿用 B 结构；`VisibilityDetector` 需 T20 时确认 B 是否引入（B pubspec 无 `visibility_detector` 包，A 若用则需纯 Dart 替代——待 T20 检查） |
| 10 | 直播反馈 | T21 | **可用** | `Api.liveFeedback` + `LiveHttp.liveFeedback` 纯 dio + UI 按钮；live 子系统保留 B 的 OS.isHarmony 分支 |
| 11 | 快速分享 pmShare | T22 | **可用** | **B `request_utils.dart:73` 已有完整 `pmShare`**（用 `Accounts.main`，A 用 `Accounts.reply`，按 B 现状）；只需恢复分享按钮 `onLongPress`（3 处 UI）；分享对话框 A 用 `SelectionText` → B 用 `SelectableText` |
| 12 | 历史续播 + SponsorBlock 无痕 | T23 | **可用** | `viewPgc/viewUgc(progress:)` 纯参数传递；`suppressSponsorBlockIncognito` 纯逻辑 + `catchError` |
| 13 | 动态/首页刷新 FAB + 剪贴板搜索 | T24 | **可用** | `NotificationListener<UserScrollNotification>`/`SlideTransition`/`AnimationController`/`FloatingActionButton` 3.41 全部存在；`Clipboard` 标准 |
| 14 | 播放器快捷操作（长按倍速/比例、fastForBackwardDuration_、HDR） | T25 | **可用**（须 graft） | 见 2.3；setRate/toggleVideoFit/Duration/AlertDialog 全可用；**不要复制 A 的 `_initPlayer`/`_createVideoController`/`SimpleVideo` 段落** |
| 15 | 下载按 UP 过滤 + 保存评论图原文 | T26 | **可用** | `ownerName` 过滤纯 Dart；`forceShowOriginalContent` 与 T15 联动 |
| 16 | selectable_region_ext + insertOrAdd + viewPugv(progress:) | T27 | **受阻（可改写解除）** | 见下 §16 专项 |
| 17 | 设置项恢复（AI/翻译/申诉/图片路径/快速分享/HK URL） | T28 | **可用** | 多为 B 残留死 Pref 键激活 + 设置 UI；纯 GetX/widget |
| 18 | 视频换源 videoPush + 隐藏状态栏 + 昵称 + 无痕空降 | T29 | **可用** | `PiliScheme`（`app_scheme.dart` B 有 DIFF 版）；`hideStatusBar` OHOS 走 `HarmonyChannel`（B 有）；`setAccountUname`/`accountUnameMap` Pref 键 B 已有读取方 |
| 19 | 视频播放器核心（B 已移植的基座，供 T18/19/25 graft 依据） | — | **已适配** | B 现有：`Player()`/`VideoController()`/`maybeAsNativePlayer.setProperty`/`Media(httpHeaders:)`/`audio-files`/`Video(controls: NoVideoControls)`/`screenshot→Uint8List` |

### §16 专项：selectable_region_ext 冲突结论

**A 的 `utils/extension/selectable_region_ext.dart`（ONLY_A）依赖：**
1. `SelectableRegionState` 公共 API：`hideToolbar()`、`clearSelection()`、`contextMenuButtonItems` — 框架与 B vendored 副本都有 → **编译 OK**。
2. `List.insertOrAdd` — B `iterable_ext.dart` 已删 → T27 恢复。
3. `PageUtils.launchURL` — B 有 ✓。
4. **运行时反射**：`(this as dynamic).selectable as Selectable?` 与 `(this as dynamic).selectionDelegate as StaticSelectionContainerDelegate` — **Flutter 3.44.4 框架与 B vendored `selectable_region.dart` 均无公共 `selectable`/`selectionDelegate` getter（只有私有 `_selectable`/`_selectionDelegate`）**。A 靠 12KB `selectable_region.patch` 引擎补丁提供；B 只做了 1 文件 16 行最小复刻，**未提供这两个 getter** → 直译移植会 `NoSuchMethodError`。

**改写方案（2 选 1）：**
- **方案 A（推荐）**：给 B 的 vendored `lib/common/widgets/flutter/selectable_text/selectable_region.dart` 增加两个公共 getter（`Selectable? get selectable => _selectable;` 与 `StaticSelectionContainerDelegate get selectionDelegate => _selectionDelegate;`），并让需要使用"打开 URL"菜单的页面路由到 vendored `SelectionArea`/`SelectableRegion`（注意框架 `SelectionArea` 内部用的是框架 `SelectableRegion`，getter 不会生效，必须 import vendored 版）。等价于把 A 的引擎补丁在 B 的 vendored 文件里复刻。
- **方案 B**：改写扩展为纯公共 API——`isUncollapsed` 用 `selectionEndpoints.length > 1` 近似；`selectedText` 无法纯公共获取（框架无公开取选中文本 API），需改用 `SelectionListener`（框架 widget，`onSelectionChanged(SelectedContent?)` 公开回调）在页面侧捕获 `SelectedContent.plainText`，菜单项从页面状态读取。

**接线前提**：B 中 `dyn_menu_helper.dart`/`reply_menu_helper.dart`/`live_menu_helper.dart` 的 `part of` 声明**丢失**（A `content_panel.dart:18` 声明 `part '...dyn_menu_helper.dart'`，B 的 content_panel 无任何 part 声明）→ 3 个 helper 文件在 B 是**孤儿死代码（不参与编译）**。T27 需恢复 part 声明（`content_panel.dart`、reply item、live panel）并接回 `addLaunchMenuIfNeeded`/`hideAndClear` 调用点，否则"长按文本打开 URL"不生效。
**T4 联动**：T4 应确认 B 引擎对 `text_selection.dart:2921,3044` 注释区域的限制不涉及 `SelectableRegionState`（二者不同文件）；方案 A/B 均不触碰 text_selection 注释区。

---

## 四、对 T13/T18/T19/T25/T27 的执行建议

### T13（AI 总结）
- 依赖模型/服务全部就位（见三.4），**无 API 阻塞**。唯一前置：`VideoHttp.ugcSummaryMp4Url`/`transcriptSubtitles` 恢复（纯 dio）。`ai_summary_service.dart` 残留按 T1 决策（extend 或 replace）。

### T18（Stein 数据模型 + 进度恢复）
- **模型基本已存在**：`story_list.dart`（StoryList 完整）、`interaction.dart`（HistoryNode）B 都有；4 个 DIFF 的 `video_stein_edgeinfo`（choice/data/edges/question）为"精简版 vs fork 完整版"的数据字段差异，**无 API 问题**，按 A 版本恢复字段即可。
- 进度恢复用 GetX `Rx<HistoryNode?>` + 本地历史栈，无框架敏感 API。

### T19（Stein 播放器 UI）
- `BottomControlType.stein` 枚举、`showStein`/`interactiveChild` 参数、`_showSteinHistorySheet` 面板：全部 UI 级。**必须 graft 到 B 的 `Video` 结构**（A 的 `interactiveChild` 挂载点在 A view.dart:1661，B 在对应 `Video(...)` 外层）。`interactiveChild` 只是 `Widget?` 叠加层，B 可完全承载。
- 模型读取路径：B 的 video controller 需恢复 `import .../video_stein_edgeinfo/story_list.dart` 与 `.../video_play_info/interaction.dart`（文件在，import 被删）。
- **runtime-pending**：回溯面板交互仅设备可验证。

### T25（播放器快捷操作）
- 三个子功能 API 全部可用（见 2.3）。落地时：
  - 长按倍速：`setPlaybackSpeed` 走 `player.setRate`（B fork ✓）。
  - 长按比例：`toggleVideoFit` 纯状态（勿碰 media_kit）。
  - `fastForBackwardDuration_`：恢复 `Pref.fastForBackwardDuration_` 消费（B 的 storage_pref 键仍在）+ `BackwardSeekIndicator` 独立双时长。
  - HDR：`VideoQuality.hdrVivid/dolbyVision/hdr` 选择时 AlertDialog，纯 UI。
- **禁止**：复制 A 的 `_initPlayer`（`Player.create`/`setMediaHeader`）、`_createVideoController`（`edl://`）、`SimpleVideo` 段落。以 B 的 `Player()`/`maybeAsNativePlayer.setProperty`/`Media(httpHeaders:)`/`audio-files`/`Video` 为基底。

### T27（selectable_region_ext / insertOrAdd / viewPugv）
- `insertOrAdd`、`viewPugv(progress:)`：纯 Dart，直接恢复。
- `selectable_region_ext`：**首选方案 A**（给 B vendored selectable_region.dart 补 getter + 路由到 vendored SelectionArea/SelectableRegion），或方案 B（SelectionListener 公共 API 改写）。**两者都不触碰 `text_selection.dart:2921,3044` 注释区**。
- 必须恢复 3 个 menu helper 的 `part` 声明（content_panel/reply_item/live panel），否则功能不接线。
- 若走方案 A，注意 `dyn_menu_helper` 依赖 `_showTextDialog` 等 content_panel 库内符号，恢复 part 后自然可见。
- **runtime-pending**：长按"打开 URL"交互仅设备可验证。

---

## 附：本任务方法与证据
- 实读 B `pubspec.yaml`/`pubspec.lock`（media_kit 1.2.3 / media_kit_video 2.0.1 / media_kit_libs_ohos 1.0.0 / sdk >=3.11.1）。
- 实读两 fork 源码（cnoim feat-ohos `media-kit-9de37e13...` / My-Responsitories `media-kit-deac6b62...`）：`player.dart`、`native/player/real.dart`、`models/media/media_native.dart`、`models/player_state.dart`、`media_kit_video` 的 `video_controller.dart`/`video_texture.dart`/`no.dart`、`video/simple_video_texture.dart`（A-only）。
- 对比报告：`06_player_report.md`（§2.4 media_kit fork API 差异、§17.8 快捷操作、HDR）、`04b_common_flutter_report.md`（引擎版本漂移 §16-17、§274）、`03_utils_report.md`（selectable_region_ext/insertOrAdd/viewPugv）、`12_meta_report.md`（selectable_region.patch 差异）。
- grep 实证：功能代码（排除 `common/widgets/flutter/**`）对 `ScrollCacheExtent`/`enableInlinePrediction`/`Alignment.bottomStart`/`onFocusReceived` **0 命中**。
- B 现存死代码实证：`selection_text.dart`（SAME，无人 import）、menu helper 3 文件（`part of` 无主）、`pmShare`（已存在）。
